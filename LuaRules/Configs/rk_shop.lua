local CopyTable = Spring.Utilities.CopyTable
local itemDefs, itemLists = VFS.Include("LuaRules/Configs/rk_item_defs.lua")

local roundDefs = {
	{
		shopSize = {3, 3},
		mapSize = 0.3,
		shopListsUsed = {"turrets", "mounts", "modules"},
		prescribeShop = {
			"turrets", "mounts", "modules",
			"modules", "turrets", "mounts",
			"mounts", "modules", "turrets",
		}
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

local defs = {
	rounds = roundDefs,
	perks = {
		turrets = CopyTable(itemLists.turrets),
		mounts  = CopyTable(itemLists.mounts),
		modules = CopyTable(itemLists.modules),
		combos  = CopyTable(itemLists.combos),
	},
}

return defs
