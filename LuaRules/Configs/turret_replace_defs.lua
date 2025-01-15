
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- To be moved to def files

local defs = {
	cloakraid = {
		mount = {
			piece = "chest",
			turretOffset = 2,
		},
		turret = {
			piece = "chest",
			turretOffset = 0.8,
			hidePieces = {
				"lthigh",
				"rthigh",
			},
		},
	},
	cloakassault = {
		mount = {
			piece = "chest",
			turretOffset = 2,
		},
		turret = {
			piece = "chest",
			hidePieces = {
				"lthigh",
				"rthigh",
			},
		},
	},
	vehassault = {
		mount = {
			piece = "turret",
			turretOffset = -1.5,
		},
		turret = {
			piece = "turret",
			turretOffset = 1.5,
		},
	},
	jumpraid = {
		mount = {
			piece = "low_head",
			turretOffset = 2,
		},
		turret = {
			piece = "low_head",
		},
	},
}

local mountDefs, turretDefs = {}, {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local baseUnit = ud.customParams.base_unit
	if baseUnit and defs[baseUnit] then
		mountDefs[i] = defs[baseUnit].mount
		Spring.Echo("addmountDefs", i, ud.name)
		if not ud.customParams.clone_id then
			turretDefs[i] = defs[baseUnit].turret
			Spring.Echo("turretDefs", i, ud.name)
		end
	end
end


return mountDefs, turretDefs
