--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name      = "Game Over",
		desc      = "GAME OVER!! (handles conditions thereof)",
		author    = "SirMaverick, Google Frog, KDR_11k, CarRepairer (unified by KingRaptor)",
		date      = "2009",
		license   = "GPL",
		layer     = 1,
		enabled   = true  --  loaded by default?
	}
end

function gadget:GameOver()
	if DEBUG_MSG then
		Spring.Echo("gadget:GameOver")
	end
	gameIsOver = true
	if noElo or Spring.Utilities.Gametype.isFFA() then
		Spring.SendCommands("wbynum 255 SPRINGIE:noElo")
	end
	Spring.Log(gadget:GetInfo().name, LOG.INFO, "GAME OVER!!")
end
