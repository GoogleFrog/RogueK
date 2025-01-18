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
	"hoverriot",
}
local simpleMounts = {
	"cloakraid",
	"jumpraid",
	"cloakassault",
	"vehassault",
	"hoverriot",
}
local simpleCombos = {
	"vehcon",
}

local factoryBuildlist = {}
local constructorBuildlist = {
	"rogue_factory"
}

local function MakeSimpleClone(simpleList, prefix)
	for i = 1, #simpleList do
		local name = simpleList[i]
		local cloneName = prefix .. '_' .. name
		UnitDefs[cloneName] = CopyTable(UnitDefs[name], true)
		UnitDefs[cloneName].customparams['rk_' .. prefix] = 1
		UnitDefs[cloneName].customparams.base_unit = name
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
	local isMobile = (UnitDefs[name].speed or 0) > 0
	for cloneID = 1, CLONE_COPIES do
		local cloneName = name .. '_' .. cloneID
		UnitDefs[cloneName] = CopyTable(UnitDefs[name], true)
		UnitDefs[cloneName].customparams.clone_id = cloneID
		if isMobile then
			factoryBuildlist[#factoryBuildlist + 1] = cloneName
		else
			constructorBuildlist[#constructorBuildlist + 1] = cloneName
		end
	end
end

for name, ud in pairs(UnitDefs) do
	if ud.customparams.clone_id and (ud.workertime or 0) > 0 then
		ud.buildoptions = constructorBuildlist
	end
end

UnitDefs["rogue_factory"].buildoptions = factoryBuildlist
