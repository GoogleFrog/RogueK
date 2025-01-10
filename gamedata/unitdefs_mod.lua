
for name, ud in pairs(UnitDefs) do
	ud.reclaimable = false
end

VFS.Include("gamedata/rk_clonedefs.lua")
