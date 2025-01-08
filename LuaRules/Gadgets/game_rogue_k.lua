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
-- Things to move into a defs file

local roundDefs = {
	{
		shopSize = {3, 3},
	},
	{
		shopSize = {3, 4},
	},
	{
		shopSize = {3, 5},
	},
	{
		shopSize = {4, 5},
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Tell inbuilt setup and game over lua to stop handling things, as if this were a mission
GG.MOD_MISSION = true

local roundNumber = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetupTeamShop(teamID, roundDef)
	for i = 1, roundDef.shopSize[1] do
		for j = 1, roundDef.shopSize[2] do
			Spring.SetTeamRulesParam(teamID, "rk_shop_item_" .. i .. "_" .. j, "glaive")
		end
	end
end

local function StartNextRound()
	roundNumber = (roundNumber or 0) + 1
	local roundDef = roundDefs[roundNumber]
	Spring.SetGameRulesParam("rk_in_shop", 1)
	Spring.SetGameRulesParam("rk_round_number", roundNumber)
	
	Spring.SetGameRulesParam("rk_shop_width", roundDef.shopSize[1])
	Spring.SetGameRulesParam("rk_shop_height", roundDef.shopSize[2])
	
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID, leaderID, isDead, isAiTeam = Spring.GetTeamInfo(teamList[i])
		if (leaderID or 0) >= 0 and not isAiTeam then
			SetupTeamShop(teamID, roundDef)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function NewGame(cmd, line, words, player)
	Spring.SetGameRulesParam("rk_preGame", 0)
	StartNextRound()
end

function gadget:Initialize()
	Spring.SetGameRulesParam("rk_preGame", 1)
	Spring.SetGameRulesParam("rk_round_number", 0)
	Spring.SetGameRulesParam("rk_in_shop", 0)
	
	Spring.SetGameRulesParam("is_mod_mission", 1)
	gadgetHandler:AddChatAction("rk_new_game", NewGame)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

end