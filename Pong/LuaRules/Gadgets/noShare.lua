function gadget:GetInfo()
	return {
		name = "noShare",
		desc = "Disables sharing",
		author = "KDR_11k (David Becker)",
		date = "2007-11-18",
		license = "None",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

function gadget:AllowUnitTransfer(u, ud, team, newteam, capture)
	return capture
end
end
