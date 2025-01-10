local CopyTable = Spring.Utilities.CopyTable

-- Set CLONE_COPIES to the largest number of distinct units that a player can create
-- The units have to fit on the factory UI, so 11 seems reasonable.
local CLONE_COPIES = 11

-- Simple turret, mounts and combos are for when the unitdef will be a copy
-- of the base game unit. Any specific changes (such as a different script, or
-- fiddling with weapons) will require an file in units/. 
-- turret_cloakraid has been put in units/ as an example.

local simpleTurrets = {
	--"cloakraid",
	"jumpraid",
	"cloakassault",
	"vehassault",
}
local simpleMounts = {
	"cloakraid",
	"jumpraid",
	"cloakassault",
	"vehassault",
}
local simpleCombos = {
	"vehcon",
}

local function MakeSimpleClone(simpleList, prefix)
	for i = 1, #simpleList do
		local name = simpleList[i]
		local cloneName = prefix .. '_' .. name
		UnitDefs[cloneName] = CopyTable(UnitDefs[name], true)
		UnitDefs[cloneName]['rk_' .. prefix] = 1
		UnitDefs[cloneName].base_unit = name
		UnitDefs[cloneName].corpse = nil
	end
end
MakeSimpleClone(simpleTurrets, 'turret')
MakeSimpleClone(simpleMounts, 'mount')
MakeSimpleClone(simpleCombos, 'combo')

local toCopy = {}
for name, ud in pairs(UnitDefs) do
	if ud.customparams.rk_mount or ud.customparams.rk_combo then
		toCopy[#toCopy + 1] = name
	end
end

-- We need to tell apart units of the same combo or mount, so factories can produce them
-- in the standard way, and selectkeys can select distinct groups
for i = 1, #toCopy do
	local name = toCopy[i]
	for cloneID = 1, CLONE_COPIES do
		local cloneName = name .. '_' .. cloneID
		UnitDefs[cloneName] = CopyTable(UnitDefs[name], true)
		UnitDefs[cloneName].customparams.clone_id = cloneID
	end
end
