function gadget:GetInfo()
	return {
		name      = "Rogue-K Handler",
		desc      = "Implements main Rogue-K handling",
		author    = "GoogleFrog",
		date      = "8 Jan 2025",
		license   = "GNU GPL, v2 or later",
		layer     = -2, -- Start unit setup
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local shopDefs = VFS.Include("LuaRules/Configs/rk_shop_def.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Tell inbuilt setup and game over lua to stop handling things, as if this were a mission
GG.MOD_MISSION = true

local FACTORY_ID = UnitDefNames["rogue_factory"].id

local BATTLE_START_DELAY = 40
local BUILD_RESOLUTION = 16

local roundNumber = false
local loadoutData = {}
local teamReadyToStart = {}
local mapGenerated = false
local startBattleTimer = false
local mapGenData = {}
local removedCmdDesc = {}

local playerTeamList = {}
do
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID, leaderID, isDead, isAiTeam = Spring.GetTeamInfo(teamList[i])
		if (leaderID or 0) >= 0 and not isAiTeam then
			playerTeamList[#playerTeamList + 1] = teamID
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function SetGlobalLos(enabled)
	local allyTeams = Spring.GetAllyTeamList()
	for i = 1, #allyTeams do
		Spring.SetGlobalLos(allyTeams[i], enabled)
	end
end

local function AugmentLoadoutData(data)
	local validUnitdefIDMap = {}
	for i = 1, #data.units do
		local unit = data.units[i]
		if unit.mount then
			validUnitdefIDMap[UnitDefNames[unit.mount.name .. "_" .. i].id] = i
		elseif unit.combo then
			validUnitdefIDMap[UnitDefNames[unit.combo.name .. "_" .. i].id] = i
		end
	end
	data.validUnitdefIDMap = validUnitdefIDMap
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Player loadout handling

local function SetLoadoutRulesParams(teamID)
	local loadout = loadoutData[teamID]
	for i = 1, #loadout.units do
		local unit = loadout.units[i]
		if unit.combo then
			Spring.SetTeamRulesParam(teamID, "rk_unit_combo_" .. i, unit.combo.name)
			Spring.SetTeamRulesParam(teamID, "rk_unit_combo_level_" .. i, unit.combo.level)
		end
		if unit.turret then
			Spring.SetTeamRulesParam(teamID, "rk_unit_turret_" .. i, unit.turret.name)
			Spring.SetTeamRulesParam(teamID, "rk_unit_turret_level_" .. i, unit.turret.level)
		end
		if unit.mount then
			Spring.SetTeamRulesParam(teamID, "rk_unit_mount_" .. i, unit.mount.name)
			Spring.SetTeamRulesParam(teamID, "rk_unit_mount_level_" .. i, unit.mount.level)
		end
		for j = 1, #unit.modules do
			local mod = unit.modules[j]
			Spring.SetTeamRulesParam(teamID, "rk_unit_module_" .. i .. "_" .. j, mod.name)
			Spring.SetTeamRulesParam(teamID, "rk_unit_module_level_" .. i .. "_" .. j, mod.level)
		end
	end
	for i = 1, #loadout.perks do
		local perk = loadout.perks[i]
		Spring.SetTeamRulesParam(teamID, "rk_perk_" .. i, perk.name)
		Spring.SetTeamRulesParam(teamID, "rk_perk_level_" .. i, perk.level)
	end
	for i = 1, #loadout.inventory do
		local item = loadout.inventory[i]
		Spring.SetTeamRulesParam(teamID, "rk_inv_item_" .. i, item.name)
		Spring.SetTeamRulesParam(teamID, "rk_inv_item_level_" .. i, item.level)
	end
end

local function DeserialiseUnit(unitStr)
	local data = Spring.Utilities.ExplodeString('|', unitStr)
	local unit = {
		modules = {},
	}
	local index = 1
	while data[index] do
		if data[index] == "combo" or data[index] == "turret" or data[index] == "mount" then
			unit[data[index]] = {
				name = data[index + 1],
				level = data[index + 2]
			}
			index = index + 3
		elseif data[index] == "modules" then
			index = index + 1
		else
			unit.modules[#unit.modules + 1] = {
				name = data[index + 1],
				level = data[index + 2]
			}
			index = index + 2
		end
	end
	return unit
end

local function DeserialiseItem(unitStr)
	local data = Spring.Utilities.ExplodeString('|', unitStr)
	local item = {
		name = data[1],
		level = data[2],
	}
	return item
end

local function DeserialiseLoadout(words)
	local unitCount = words[1] or 0
	local perkCount = words[2] or 0
	local invCount = words[3] or 0
	local loadout = {
		units = {},
		perks = {},
		inventory = {},
	}
	local wordIndex = 4
	for i = 1, unitCount do
		loadout.units[i] = DeserialiseUnit(words[wordIndex])
		wordIndex = wordIndex + 1
	end
	for i = 1, perkCount do
		loadout.perks[i] = DeserialiseItem(words[wordIndex])
		wordIndex = wordIndex + 1
	end
	for i = 1, invCount do
		loadout.inventory[i] = DeserialiseItem(words[wordIndex])
		wordIndex = wordIndex + 1
	end
	return loadout
end

local function InitPlayerTeam(teamID)
	loadoutData[teamID] = {
		units = {
			{
				combo = {name = "combo_vehcon", level = 1},
				modules = {},
			}
		},
		perks = {
			{name = "perk_unit_limit", level = 5},
			{name = "perk_module_limit", level = 2},
		},
		inventory = {},
	}
	AugmentLoadoutData(loadoutData[teamID])
	SetLoadoutRulesParams(teamID)
end

local function SetupTeamShop(teamID, roundDef)
	local index = 1
	local perks = shopDefs.perks
	local perkCount = {}
	for i = 1, #roundDef.shopListsUsed do
		local name = roundDef.shopListsUsed[i]
		Spring.Utilities.PermuteList(perks[name])
	end
	for i = 1, roundDef.shopSize[1] do
		for j = 1, roundDef.shopSize[2] do
			if roundDef.prescribeShop then
				local name = roundDef.prescribeShop[index]
				perkCount[name] = (perkCount[name] or 0) + 1
				Spring.SetTeamRulesParam(teamID, "rk_shop_item_" .. i .. "_" .. j, perks[name][perkCount[name]])
				Spring.SetTeamRulesParam(teamID, "rk_shop_item_level_" .. i .. "_" .. j, 1)
			end
			index = index + 1
		end
	end
end

local function StartNextRound()
	roundNumber = (roundNumber or 0) + 1
	local roundDef = shopDefs.rounds[roundNumber]
	Spring.SetGameRulesParam("rk_in_shop", 1)
	Spring.SetGameRulesParam("rk_round_number", roundNumber)
	
	Spring.SetGameRulesParam("rk_shop_width", roundDef.shopSize[1])
	Spring.SetGameRulesParam("rk_shop_height", roundDef.shopSize[2])
	
	for i = 1, #playerTeamList do
		local teamID = playerTeamList[i]
		SetupTeamShop(teamID, roundDef)
		teamReadyToStart[teamID] = false
	end
	GG.mapGenAtFullSpeed = false
	GG.GenerateNewMap(roundDef.mapSize)
	mapGenerated = false
	SetGlobalLos(true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Spawning

local function SanitizeBuildPositon(x, z, xSize, zSize, facing)
	if facing % 2 == 1 then
		xSize, zSize = zSize, xSize
	end
	local oddX = (xSize % 4 == 2)
	local oddZ = (zSize % 4 == 2)
	
	if oddX then
		x = math.floor((x + 8)/BUILD_RESOLUTION)*BUILD_RESOLUTION - 8
	else
		x = math.floor(x/BUILD_RESOLUTION)*BUILD_RESOLUTION
	end
	if oddZ then
		z = math.floor((z + 8)/BUILD_RESOLUTION)*BUILD_RESOLUTION - 8
	else
		z = math.floor(z/BUILD_RESOLUTION)*BUILD_RESOLUTION
	end
	return x, z
end

local function GetClearBuildingPlacement(unitDefID, centerX, centerZ, spawnRadius, facing)
	local ud = UnitDefs[unitDefID]
	local xSize, zSize = ud.xsize, ud.zsize
	local x, z = centerX, centerZ
	if spawnRadius then
		x = centerX + 2*math.random()*spawnRadius - spawnRadius
		z = centerZ + 2*math.random()*spawnRadius - spawnRadius
	end
	x, z = SanitizeBuildPositon(x, z, xSize, zSize, facing)
	local y = Spring.GetGroundHeight(x,z)
	
	spawnRadius = spawnRadius or 100
	local tries = 1
	while not (y > 5 and Spring.TestBuildOrder(unitDefID, x, y, z, facing) ~= 0) do
		if tries > 30 then
			spawnRadius = spawnRadius + 15
		end
		if tries > 50 then
			break
		end
		x = centerX + 2*math.random()*spawnRadius - spawnRadius
		z = centerZ + 2*math.random()*spawnRadius - spawnRadius
		x, z = SanitizeBuildPositon(x, z, xSize, zSize, facing)
		y = Spring.GetGroundHeight(x,z)
		tries = tries + 1
	end
	
	return x, z
end

local function GetClearMobilePlacement(unitDefID, centerX, centerZ, spawnRadius)
	local x, z = centerX, centerZ
	if spawnRadius then
		x = centerX + 2*math.random()*spawnRadius - spawnRadius
		z = centerZ + 2*math.random()*spawnRadius - spawnRadius
	end
	local y = Spring.GetGroundHeight(x,z)
	
	spawnRadius = spawnRadius or 100
	local tries = 1
	while not (y > 5 and Spring.TestMoveOrder(unitDefID, x, y, z, 0, 0, 0, true, true, false)) do
		if tries > 30 then
			spawnRadius = spawnRadius + 15
		end
		if tries > 50 then
			break
		end
		x = centerX + 2*math.random()*spawnRadius - spawnRadius
		z = centerZ + 2*math.random()*spawnRadius - spawnRadius
		y = Spring.GetGroundHeight(x,z)
		tries = tries + 1
	end
	
	return x, z
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Build Options

local function RemoveUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		if not removedCmdDesc[lockDefID] then
			local toRemove = Spring.GetUnitCmdDescs(unitID, cmdDescID, cmdDescID)
			removedCmdDesc[lockDefID] = toRemove[1]
		end
		Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
	end
end

local function AddUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (not cmdDescID) and removedCmdDesc[lockDefID] then
		Spring.InsertUnitCmdDesc(unitID, removedCmdDesc[lockDefID])
	end
end

local function SetBuildOptions(unitID, unitDefID, teamID)
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
	local ud = unitDefID and UnitDefs[unitDefID]
	if ud and ud.isBuilder and (ud.customParams.clone_id or ud.customParams.rogue_factory) then
		local buildoptions = ud.buildOptions
		for i = 1, #buildoptions do
			local opt = buildoptions[i]
			Spring.Echo(UnitDefs[opt].name)
			if loadoutData[teamID].validUnitdefIDMap[opt] or opt == FACTORY_ID then
				AddUnit(unitID, opt)
			else
				RemoveUnit(unitID, opt)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SpawnPlayerBase(teamID)
	local centerX, centerZ = mapGenData.startCell.site[1], mapGenData.startCell.site[2]
	local x, z = GetClearBuildingPlacement(FACTORY_ID, centerX, centerZ, 300, 1)
	unitID = Spring.CreateUnit(FACTORY_ID, x, Spring.GetGroundHeight(x, z), z, 1, teamID, false, true)
end

local function StartBattle()
	for i = 1, #playerTeamList do
		local teamID = playerTeamList[i]
		SpawnPlayerBase(teamID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function NewGame(cmd, line, words, player)
	Spring.SetGameRulesParam("rk_preGame", 0)
	for i = 1, #playerTeamList do
		local teamID = playerTeamList[i]
		InitPlayerTeam(teamID)
	end
	StartNextRound()
	Spring.SendCommands("wbynum 255 SPRINGIE:FORCE")
end

local function CheckStartBattle()
	for i = 1, #playerTeamList do
		local teamID = playerTeamList[i]
		if not teamReadyToStart[teamID] then
			return
		end
	end
	GG.mapGenAtFullSpeed = true
	if not mapGenerated then
		return
	end
	for i = 1, #playerTeamList do
		local teamID = playerTeamList[i]
		SetLoadoutRulesParams(teamID)
	end
	startBattleTimer = BATTLE_START_DELAY
end

local function SendNextRoundAndLoadout(cmd, line, words, player)
	if not words then
		return
	end
	local name, active, spectator, teamID = Spring.GetPlayerInfo(player)
	if spectator then
		return
	end
	loadoutData[teamID] = DeserialiseLoadout(words)
	AugmentLoadoutData(loadoutData[teamID])
	teamReadyToStart[teamID] = true
	CheckStartBattle()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function GG.rk_MapGenerationComplete(startCell, cells, edges)
	mapGenData.startCell = startCell
	mapGenData.cells = cells
	mapGenData.edges = edges
	
	SetGlobalLos(false)
	Spring.SetGameRulesParam("map_texture_generate_count", roundNumber)
	mapGenerated = true
	CheckStartBattle()
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	SetBuildOptions(unitID, unitDefID, teamID)
end

function gadget:GameFrame(n)
	if startBattleTimer then
		startBattleTimer = startBattleTimer - 1
		if startBattleTimer <= 0 then
			StartBattle()
			startBattleTimer = false
		end
	end
end

function gadget:Initialize()
	Spring.SetGameRulesParam("rk_preGame", 1)
	Spring.SetGameRulesParam("rk_round_number", 0)
	Spring.SetGameRulesParam("rk_in_shop", 0)
	Spring.SetGameRulesParam("is_mod_mission", 1)
	
	gadgetHandler:AddChatAction("rk_new_game", NewGame)
	gadgetHandler:AddChatAction("rk_send_next_round_and_loadout", SendNextRoundAndLoadout)
end

function gadget:AllowStartPosition(playerID, teamID, readyState, x, y, z, rx, ry, rz)
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

end