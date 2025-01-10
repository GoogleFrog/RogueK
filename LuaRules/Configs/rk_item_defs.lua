
local turrets = {
	"turret_cloakraid",
	"turret_jumpraid",
	"turret_cloakassault",
	"turret_vehassault",
}

local mounts = {
	"mount_cloakraid",
	"mount_jumpraid",
	"mount_cloakassault",
	"mount_vehassault",
}

local combos = {
	"combo_vehcon",
}

local modules = {
	"module_damage",
	"module_range",
	"module_speed",
	"module_health",
}

local itemLists = {
	turrets = turrets,
	mounts = mounts,
	combos = combos,
	modules = modules,
}

local defs = {
	turret_cloakraid = {
		isTurret = true,
		humanName = "Gl",
		cost = 25,
	},
	turret_jumpraid = {
		isTurret = true,
		humanName = "Pyr",
		cost = 130,
	},
	turret_cloakassault = {
		isTurret = true,
		humanName = "Kn",
		cost = 220,
	},
	turret_vehassault = {
		isTurret = true,
		humanName = "Rav",
		cost = 90,
	},

	mount_cloakraid = {
		isMount = true,
		humanName = "aive",
		cost = 40,
	},
	mount_jumpraid = {
		isMount = true,
		humanName = "yro",
		cost = 90,
	},
	mount_cloakassault = {
		isMount = true,
		humanName = "ight",
		cost = 130,
	},
	mount_vehassault = {
		isMount = true,
		humanName = "ager",
		cost = 160,
	},

	combo_vehcon = {
		isCombo = true,
		humanName = "Mason",
		cost = 120,
	},

	module_damage = {
		isModule = true,
		humanName = "+Damage",
	},
	module_range = {
		isModule = true,
		humanName = "+Range",
	},
	module_speed = {
		isModule = true,
		humanName = "+Speed",
	},
	module_health = {
		isModule = true,
		humanName = "+Health",
	},
}

return defs, itemLists
