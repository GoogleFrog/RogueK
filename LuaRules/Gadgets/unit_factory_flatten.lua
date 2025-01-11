if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name    = "Factory exit flatten",
		author  = "GoogleFrog (effectively)",
		date    = "2017-10-01",
		license = "GNU GPL, v2 or later",
		layer   = 1, -- after mission_galaxy_campaign_battle_handler (it levels ground for facs and would overwrite ours)
		enabled = true,
	}
end

local finished = {}

local smoothDef = {
	smooth = 0.75,
	smoothradius = 150,
	gatherradius = 280,
	quickgather = false,
	detachmentradius = false,
	smoothheightoffset = false,
	movestructures = 1,
	smoothexponent = 0.8,
}

local function FlattenFunc(left, top, right, bottom, height)
	-- top and bottom
	for i = 1, 6 do
		for x = left - i*8, right + i*8, 8 do
			Spring.SetHeightMap(x, top - i*8, height, 1 - i/7)
			Spring.SetHeightMap(x, bottom + i*8, height, 1 - i/7)
		end
		-- left and right
		for z = top - (i - 1)*8, bottom + (i - 1)*8, 8 do
			Spring.SetHeightMap(left - i*8, z, height, 1 - i/7)
			Spring.SetHeightMap(right + i*8, z, height, 1 - i/7)
		end
	end
end

local function FlattenRectangle(left, top, right, bottom, height)
	Spring.LevelHeightMap(left, top, right, bottom, height)
	Spring.SetHeightMapFunc(FlattenFunc, left, top, right, bottom, height)
end

local function FlattenFactory(unitID, unitDefID)
	local ud = UnitDefs[unitDefID]
	local sX = ud.xsize*4
	local sZ = ud.zsize*4
	local facing = Spring.GetUnitBuildFacing(unitID)
	if facing == 1 or facing == 3 then
		sX, sZ = sZ, sX
	end

	local x,y,z = Spring.GetUnitPosition(unitID)
	local height
	if facing == 0 then -- South
		height = Spring.GetGroundHeight(x, z + 0.8*sZ)
	elseif facing == 1 then -- East
		height = Spring.GetGroundHeight(x + 0.8*sX, z)
	elseif facing == 2 then -- North
		height = Spring.GetGroundHeight(x, z - 0.8*sZ)
	else -- West
		height = Spring.GetGroundHeight(x - 0.8*sX, z)
	end

	if height > 0 or (not ud.floatOnWater) then
		FlattenRectangle(x - sX, z - sZ, x + sX, z + sZ, height)
		if GG.Terraform then
			GG.Terraform.SetStructureHeight(unitID, height)
		end
	end
end

local pregame_facs = {}
function gadget:UnitFinished(unitID, unitDefID)
	if not UnitDefs[unitDefID].isFactory then
		return
	end
	FlattenFactory(unitID, unitDefID)
	finished[unitID] = true
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if finished[unitID] then
		local x, _, z = Spring.GetUnitPosition(unitID)
		local y = Spring.GetGroundHeight(x, z)
		GG.Terraform.DoSmooth(smoothDef, x, y, z)
	end
end
