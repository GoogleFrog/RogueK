
local turrets = {
	"turret_glaive",
	"turret_pyro",
	"turret_knight",
	"turret_ravager",
}

local mounts = {
	"mount_glaive",
	"mount_pyro",
	"mount_knight",
	"mount_ravager",
}

local modules = {
	"base_damage",
	"base_range",
	"base_speed",
	"base_health",
}

local roundDefs = {
	{
		shopSize = {3, 3},
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
		turrets = turrets,
		mounts = mounts,
		modules = modules,
	},
}

return defs
