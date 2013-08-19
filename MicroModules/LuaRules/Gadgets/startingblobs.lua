function gadget:GetInfo()
	return {
		name = "Starting Blobs",
		desc = "Gives the master blob the starting blobs",
		author = "KDR_11k (David Becker)",
		date = "2008-09-13",
		license = "Public Domain",
		layer = 5,
		enabled = true
	}
end

local master=UnitDefNames.master.id

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local count=tonumber(Spring.GetModOptions().startblobs or 500)

function gadget:UnitCreated(u, ud, team)
	if ud == master and Spring.GetGameFrame() < 10 then
		GG.AddBlobs(u, ud, 1, count)
	end
end

else

--UNSYNCED

return false

end
