
local turrets = {
	"turret_cloakraid",
	"turret_jumpraid",
	"turret_cloakassault",
	"turret_vehassault",
	"turret_hoverriot",
}

local mounts = {
	"mount_cloakraid",
	"mount_jumpraid",
	"mount_cloakassault",
	"mount_hoverriot",
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

local perks = {
	"perk_unit_limit",
	"perk_module_limit",
}

local itemLists = {
	turrets = turrets,
	mounts = mounts,
	combos = combos,
	modules = modules,
}

-- By default a turret and mount from the same unit can be combined
-- to recreate the unit. But modules give bonuses/penalties, which
-- must cancel out:
--  * Turret: turretSpeed, turretHealth
--  * Mount: mountSpeed, mountDamage, mountReload
-- Cost is a cobmination of turret and mount.
local baseUnitSplit = {
	cloakraid = {
		turretCost = 25,
		turretSpeed = 1.2,
		mountRange = 0.8,
	},
	jumpraid = {
		turretCost = 120,
		turretHealth = 0.8,
	},
	vehassault = {
		turretCost = 100,
		turretHealth = 1.25,
		mountReload = 0.9,
	},
	cloakassault = {
		turretCost = 230,
		mountRange = 1.25,
	},
	hoverriot = {
		turretCost = 220,
		mountRange = 1.1,
		mountDamage = 1.25,
	},
}


local itemDefs = {
	turret_cloakraid = {
		isTurret = true,
		humanName = "Gl",
	},
	turret_jumpraid = {
		isTurret = true,
		humanName = "Pyr",
	},
	turret_cloakassault = {
		isTurret = true,
		humanName = "Kn",
	},
	turret_vehassault = {
		isTurret = true,
		humanName = "Rav",
	},
	turret_hoverriot = {
		isTurret = true,
		humanName = "Mac",
	},

	mount_cloakraid = {
		isMount = true,
		humanName = "aive",
	},
	mount_jumpraid = {
		isMount = true,
		humanName = "yro",
	},
	mount_cloakassault = {
		isMount = true,
		humanName = "ight",
	},
	mount_vehassault = {
		isMount = true,
		humanName = "ager",
	},
	mount_hoverriot = {
		isMount = true,
		humanName = "ace",
	},

	combo_vehcon = {
		isCombo = true,
		humanName = "Mason",
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
	
	perk_unit_limit = {
		isPerk = true,
		humanName = "+Units",
	},
	perk_module_limit = {
		isPerk = true,
		humanName = "+Modules",
	},
}

for unit, data in pairs(baseUnitSplit) do
	local ud = UnitDefNames[unit]
	local wd = WeaponDefs[ud.weapons[1].weaponDef]
	local turret = itemDefs["turret_" .. unit]
	local mount = itemDefs["mount_" .. unit]
	
	local cost = ud.metalCost
	local health = ud.health
	local speed = ud.speed
	local range = ud.maxWeaponRange
	local reload = wd.reload
	local damage = wd.damages[1]
	
	turret.cost = data.turretCost
	mount.cost = cost - data.turretCost
	
	turret.healthMult = (data.turretHealth or 1)
	mount.healthMult = 1 / turret.healthMult
	mount.health = health * mount.healthMult
	turret.speedMult = (data.turretSpeed or 1)
	mount.speedMult = 1 / turret.speedMult
	mount.speed = speed * mount.speedMult
	
	mount.rangeMult = (data.mountRange or 1)
	turret.rangeMult = 1 / mount.rangeMult
	turret.range = range * mount.rangeMult
	mount.reloadMult = (data.mountReload or 1)
	turret.reloadMult = 1 / mount.reloadMult
	turret.reload = reload * turret.reloadMult
	mount.damageMult = (data.mountDamage or 1)
	turret.damageMult = 1 / mount.damageMult
	turret.damage = damage * turret.damageMult
end

return itemDefs, itemLists
