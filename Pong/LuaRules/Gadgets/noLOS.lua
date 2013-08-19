function gadget:GetInfo()
	return {
		name = "noLOS",
		desc = "Disables LOS",
		author = "KDR_11k (David Becker)",
		date = "2007-11-18",
		license = "None",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED
local exempt = {
}

function gadget:UnitCreated(u, ud, team)
	if not exempt[ud] then
		Spring.SetUnitAlwaysVisible(u,true)
	end
end

end
