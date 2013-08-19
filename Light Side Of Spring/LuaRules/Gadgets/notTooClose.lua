function gadget:GetInfo()
	return {
		name = "notTooClose",
		desc = "prevents building stuff near enemy lasers",
		author = "KDR_11k (David Becker)",
		date = "2008-06-14",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

local laser = UnitDefNames.laser.id

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

function gadget:AllowUnitCreation(ud, b, bteam, x,y,z)
	for _,u in ipairs(Spring.GetUnitsInCylinder(x,z,300)) do
		if Spring.GetUnitDefID(u) == laser and Spring.GetUnitTeam(u) ~= bteam then
			return false
		end
	end
	return true
end

else

--UNSYNCED

return false

end
