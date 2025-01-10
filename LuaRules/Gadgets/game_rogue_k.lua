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
			end
			index = index + 1
		end
	end
end

local function InitPlayerTeam(teamID)
	Spring.SetTeamRulesParam(teamID, "rk_unit_combo_1", "combo_vehcon")
	Spring.SetTeamRulesParam(teamID, "rk_perk_1", "perk_unit_limit")
	Spring.SetTeamRulesParam(teamID, "rk_perk_level_1", 5)
	Spring.SetTeamRulesParam(teamID, "rk_perk_2", "perk_module_limit")
	Spring.SetTeamRulesParam(teamID, "rk_perk_level_2", 2)
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

local function SendUnitSpec(cmd, line, words, player)
	Spring.Echo(cmd)
	Spring.Echo(line)
	Spring.Echo(words)
	Spring.Echo(player)
	--msg = Spring.Utilities.ExplodeString('|', msg)
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	Spring.SetGameRulesParam("rk_preGame", 1)
	Spring.SetGameRulesParam("rk_round_number", 0)
	Spring.SetGameRulesParam("rk_in_shop", 0)
	Spring.SetGameRulesParam("is_mod_mission", 1)
	
	gadgetHandler:AddChatAction("rk_new_game", NewGame)
	gadgetHandler:AddChatAction("rk_send_unit_spec", SendUnitSpec)
	gadgetHandler:AddChatAction("rk_send_perk_spec", SendPerkSpec)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

end