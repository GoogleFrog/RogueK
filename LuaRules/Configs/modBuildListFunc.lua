

local function ModBuildList(factory_commands, econ_commands, defense_commands, special_commands)
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

	local special_commands = {
		rogue_factory = {order = 6.4, row = 2, col = 1},
	}
	for i = 1, #UnitDefs do
		local ud = UnitDefs[i]
		if ud.customParams.clone_id and ud.speed <= 0 then
			special_commands[ud.name] = unitTypes[tonumber(ud.customParams.clone_id)]
		end
	end
	
	return {}, {}, {}, special_commands
end

return ModBuildList
