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

local shopDefs = VFS.Include("LuaRules/Configs/rk_shop.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Tell inbuilt setup and game over lua to stop handling things, as if this were a mission
GG.MOD_MISSION = true

local roundNumber = false
local buildData = {}

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

local function SetBuildRulesParams(teamID)
	local build = buildData[teamID]
	for i = 1, #build.units do
		local unit = build.units[i]
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
	for i = 1, #build.perks do
		local perk = build.perks[i]
		Spring.SetTeamRulesParam(teamID, "rk_perk_" .. i, perk.name)
		Spring.SetTeamRulesParam(teamID, "rk_perk_level_" .. i, perk.level)
	end
	for i = 1, #build.inventory do
		local item = build.inventory[i]
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

local function DeserialiseBuild(words)
	local unitCount = words[1] or 0
	local perkCount = words[2] or 0
	local invCount = words[3] or 0
	local build = {
		units = {},
		perks = {},
		inventory = {},
	}
	local wordIndex = 4
	for i = 1, unitCount do
		build.units[i] = DeserialiseUnit(words[wordIndex])
		wordIndex = wordIndex + 1
	end
	for i = 1, perkCount do
		build.perks[i] = DeserialiseItem(words[wordIndex])
		wordIndex = wordIndex + 1
	end
	for i = 1, invCount do
		build.inventory[i] = DeserialiseItem(words[wordIndex])
		wordIndex = wordIndex + 1
	end
end

local function InitPlayerTeam(teamID)
	buildData[teamID] = {
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
	SetBuildRulesParams(teamID)
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
	end
	GG.GenerateNewMap()
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
end

local function SendNextRoundAndBuild(cmd, line, words, player)
	if not words then
		return
	end
	local name, active, spectator, teamID = Spring.GetPlayerInfo(player)
	if spectator then
		return
	end
	buildData[teamID] = DeserialiseBuild(words)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function GG.rk_MapGenerationComplete()
	Spring.SetGameRulesParam("map_texture_generate_count", roundNumber)
end

function gadget:Initialize()
	Spring.SetGameRulesParam("rk_preGame", 1)
	Spring.SetGameRulesParam("rk_round_number", 0)
	Spring.SetGameRulesParam("rk_in_shop", 0)
	Spring.SetGameRulesParam("is_mod_mission", 1)
	
	gadgetHandler:AddChatAction("rk_new_game", NewGame)
	gadgetHandler:AddChatAction("rk_send_next_round_and_build", SendNextRoundAndBuild)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

end