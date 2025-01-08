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

GG.MOD_MISSION = true -- Tell inbuilt setup and game over lua to stop handling things, as if this were a mission

local function NewGame(cmd, line, words, player)
	Spring.SetGameRulesParam("rk_preGame", 0)
	Spring.SetGameRulesParam("rk_round_number", 1)
	Spring.SetGameRulesParam("rk_in_shop", 1)
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