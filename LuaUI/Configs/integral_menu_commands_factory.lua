VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Factory Units Panel Positions


local unitTypes = {
	{order = 1, row = 1, col = 1},
	{order = 2, row = 1, col = 2},
	{order = 3, row = 1, col = 3},
	{order = 4, row = 1, col = 4},
	{order = 5, row = 1, col = 5},
	{order = 6, row = 1, col = 6},
	{order = 7, row = 2, col = 2},
	{order = 8, row = 2, col = 3},
	{order = 9, row = 2, col = 4},
	{order = 10, row = 2, col = 5},
	{order = 11, row = 2, col = 6},
}

local factory = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.clone_id and ud.speed > 0 then
		factory[ud.name] = unitTypes[tonumber(ud.customParams.clone_id)]
	end
end

local factoryUnitPosDef = {
	rogue_factory = factory,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return factoryUnitPosDef

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
