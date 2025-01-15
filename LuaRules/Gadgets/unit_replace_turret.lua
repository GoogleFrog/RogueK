--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modoption = Spring.GetModOptions().techk
function gadget:GetInfo()
	return {
		name      = "Replace Turret",
		desc      = "Adds API for replacing turrets of units with other units",
		author    = "GoogleFrog",
		date      = "30 December 2024",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if not gadgetHandler:IsSyncedCode() then
	return
end

include("LuaRules/Configs/customcmds.h.lua")

local CMD_ATTACK = CMD.ATTACK

-- TODO.
-- Make all damage to turret turn into damage onto mount
-- Make mount immune to other sources of damage.
-- Fill out and extract the mount defs
-- Front back offset issues with vehicle turrets, for offsetting colvol and possibly target pos.

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local mountDefs, turretDefs = VFS.Include("LuaRules/Configs/turret_replace_defs.lua")

local updateTargetNextFrame = {}
local toCreateCheck = {}
local turrets = {} -- Indexed turretIDs (unitIDs of turrets), values are unitID of the mount holding the turret.
local mountData = IterableMap.New() -- Indexed by unitID of mounts.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Piece Utilities

local function HidePieceAndChildren(unitID, pieceName)
	local pieceMap = Spring.GetUnitPieceMap(unitID)
	local pieceID = pieceMap[pieceName]
	local toHide = {pieceID}
	
	Spring.UnitScript.CallAsUnit(unitID, function ()
		while #toHide > 0 do
			local pieceID = toHide[#toHide]
			toHide[#toHide] = nil
			local info = Spring.GetUnitPieceInfo(unitID, pieceID)
			Spring.UnitScript.Hide(pieceID)
			if info and info.children then
				for i = 1, #info.children do
					toHide[#toHide + 1] = pieceMap[info.children[i]]
				end
			end
		end
	end)
end

local function ShowOnlyPieceAndChildren(unitID, pieceName)
	local pieceMap = Spring.GetUnitPieceMap(unitID)
	local toHide = {Spring.GetUnitRootPiece(unitID)}
	
	Spring.UnitScript.CallAsUnit(unitID, function ()
		while #toHide > 0 do
			local pieceID = toHide[#toHide]
			toHide[#toHide] = nil
			local info = Spring.GetUnitPieceInfo(unitID, pieceID)
			Spring.UnitScript.Hide(pieceID)
			if info and info.children then
				for i = 1, #info.children do
					local name = info.children[i]
					if name ~= pieceName then
						toHide[#toHide + 1] = pieceMap[name]
					end
				end
			end
		end
	end)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Setup

local function ReplaceTurret(unitID, unitDefID, teamID, builderID, turretDefID)
	local mountDef = mountDefs[unitDefID]
	local turretDef = turretDefs[turretDefID]
	local pieceMap = Spring.GetUnitPieceMap(unitID)
	
	-- Hide the turret of the mount, and the body of the turret.
	if mountDef.hidePieces then
		for i = 1, #mountDef.hidePieces do
			HidePieceAndChildren(unitID, mountDef.hidePieces[i])
		end
	else
		HidePieceAndChildren(unitID, mountDef.piece)
	end
	local turretID = Spring.CreateUnit(turretDefID, 0, 0, 0, 0, teamID, true)
	if turretDef.hidePieces or turretDef.hidePiecesNonRecursive then
		if turretDef.hidePieces then
			for i = 1, #turretDef.hidePieces do
				HidePieceAndChildren(turretID, turretDef.hidePieces[i])
			end
		end
		if turretDef.hidePiecesNonRecursive then
			for i = 1, #turretDef.hidePiecesNonRecursive do
				HidePieceAndChildren(turretID, turretDef.hidePiecesNonRecursive[i])
			end
		end
	else
		ShowOnlyPieceAndChildren(turretID, turretDef.piece)
	end
	
	-- Attach the turret to the mount, and apply an offset because the turret is being attached
	-- at its feet, but the turret needs to line up with the mount
	local turretPieceMap = Spring.GetUnitPieceMap(turretID)
	local _, turretOffset = Spring.GetUnitPiecePosition(turretID, turretPieceMap[turretDef.piece])
	Spring.UnitAttach(unitID, turretID, pieceMap[mountDef.piece])
	GG.UnitModelRescale(turretID, 1, -turretOffset + (mountDef.turretOffset or 2) + (turretDef.turretOffset or 0))
	
	-- The turret is responsible for projectile collision, because it needs to aim from inside
	-- where the collision volumne of the mount would be. The collision volume is taken
	-- from the mount, and offset appropriately.
	local scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ,
		volumeType, testType, primaryAxis = Spring.GetUnitCollisionVolumeData(unitID)
	local _, mountOffset = Spring.GetUnitPiecePosition(unitID, pieceMap[mountDef.piece])
	offsetY = offsetY - mountOffset
	Spring.SetUnitRulesParam(turretID, "aimpos_offset", -turretOffset + (mountDef.turretOffset or 2))
	GG.OverrideBaseColvol(turretID, scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ, volumeType, testType, primaryAxis)
	Spring.SetUnitBlocking(unitID, true, true, false, false)
	Spring.SetUnitBlocking(turretID, false, false, true, true)
	Spring.SetUnitNoSelect(turretID, true)
	
	-- Mount is responsible for movement, so remove weapon firing ability and set range to mount range.
	local tud = UnitDefs[turretDefID]
	local ud = UnitDefs[unitDefID]
	local turretRange = math.max(tud.maxWeaponRange or 10, 10)
	local mountRange = math.max(ud.maxWeaponRange or 10, 10)
	local mountSpeed = ud.speed
	
	local prevHealth, mountMaxHealth = Spring.GetUnitHealth(unitID)
	local _, turretMaxHealth = Spring.GetUnitHealth(turretID)
	
	local maxHealth = mountMaxHealth
	local weaponRange = turretRange
	local speed = mountSpeed
	
	GG.Attributes.AddEffect(unitID, "turret_replace", {
		weaponNum = 1,
		range = weaponRange / mountRange,
		healthAdd = maxHealth - mountMaxHealth,
		speed = ((speed > 0) and (speed / mountSpeed)),
		reload = 0
	})
	GG.Attributes.AddEffect(turretID, "turret_replace", {
		range = weaponRange / turretRange,
		healthAdd = maxHealth - turretMaxHealth,
	})
	
	Spring.SetUnitMaxRange(unitID, weaponRange)
	Spring.SetUnitRulesParam(turretID, "no_eta_display", 1)
	Spring.SetUnitRulesParam(turretID, "no_healthbar", 1)
	
	-- De-duplicate radar dots.
	Spring.SetUnitSonarStealth(unitID, true)
	Spring.SetUnitStealth(unitID, true)
	
	local data = {
		turretID = turretID,
		prevHealth = prevHealth,
	}
	IterableMap.Add(mountData, unitID, data)
	turrets[turretID] = unitID
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Weapon and Target Handling

local function UpdateWeaponTarget(unitID, data)
	if data.forceUpdatingTarget then
		return
	end
	local tx, ty, tz = GG.GetAnyTypeOfUserUnitTarget(unitID)
	--Spring.Utilities.UnitEcho(unitID, tx)
	if tz then
		Spring.SetUnitTarget(data.turretID, tx, ty, tz, false, true)
		data.hasUserTarget = true
	elseif tx then
		Spring.SetUnitTarget(data.turretID, tx, false, true)
		data.hasUserTarget = true
	elseif data.hasUserTarget then
		Spring.SetUnitTarget(data.turretID, nil)
		data.hasUserTarget = false
	end
end

local function QueueForWeaponCheck(unitID)
	local data = IterableMap.Get(mountData, unitID)
	if data and not data.forceUpdatingTarget then
		data.forceUpdatingTarget = true
		updateTargetNextFrame = updateTargetNextFrame or {}
		updateTargetNextFrame[#updateTargetNextFrame + 1] = unitID
	end
end

local function UpdateWeaponChecks(n)
	IterableMap.ApplyFraction(mountData, 30, n%30, UpdateWeaponTarget)
	if updateTargetNextFrame then
		for i = 1, #updateTargetNextFrame do
			local unitID = updateTargetNextFrame[i]
			local data = IterableMap.Get(mountData, unitID)
			data.forceUpdatingTarget = false
			UpdateWeaponTarget(unitID, data)
		end
		updateTargetNextFrame = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateUnitStats(unitID, data)
	local turretID = data.turretID
	local turretHealth, maxHealth, emp = Spring.GetUnitHealth(turretID)
	local mountHealth, _, _, _, build = Spring.GetUnitHealth(unitID)
	
	local health = turretHealth + (mountHealth - data.prevHealth) -- Mount can be repaired etc
	if (mountHealth - data.prevHealth) ~= 0 and turretHealth > maxHealth*0.995 and not data.fixedBuildBug then
		-- Some bug with fluctuating health every slowupdate after construction.
		health = maxHealth
		data.fixedBuildBug = true
	end
	data.prevHealth = health
	
	Spring.SetUnitHealth(unitID, {health = health, paralyze = emp})
	Spring.SetUnitHealth(turretID, {health = health, build = build})
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateCreationChecks(n)
	if not toCreateCheck then
		return
	end
	for i = 1, #toCreateCheck do
		local unitID = toCreateCheck[i]
		if Spring.ValidUnitID(unitID) then
			local unitDefID = Spring.GetUnitDefID(unitID)
			local teamID = Spring.GetUnitTeam(unitID)
			if unitDefID and teamID then
				local wantTurret = GG.rk_GetWantedTurret(unitID, unitDefID, teamID)
				if wantTurret then
					ReplaceTurret(unitID, unitDefID, teamID, false, wantTurret)
				end
			end
		end
	end
	toCreateCheck = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, playerID, fromSynced, fromLua)
	QueueForWeaponCheck(unitID)
	return true
end

function gadget:GameFrame(n)
	UpdateWeaponChecks(n)
	UpdateCreationChecks(n)
	IterableMap.Apply(mountData, UpdateUnitStats)
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	local data = IterableMap.Get(mountData, unitID)
	if data then
		return 0
	end
	return damage
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	local wantTurret = GG.rk_GetWantedTurret(unitID, unitDefID, teamID)
	if wantTurret then
		if builderID then
			toCreateCheck = toCreateCheck or {}
			toCreateCheck[#toCreateCheck + 1] = unitID
		end
	end
end