local included = VFS.Include("units/cloakraid.lua")
local unitDef = included.cloakraid
unitDef.customParams.rk_turret = 1
unitDef.customParams.base_unit = "cloakraid"
unitDef.corpse = nil -- Dynamic units spawn their own wreck

return { turret_cloakraid = unitDef }
