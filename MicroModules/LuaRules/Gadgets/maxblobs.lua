function gadget:GetInfo()
	return {
		name = "Max Blob Influence",
		desc = "sets the maximum number of blobs that influence a unit",
		author = "KDR_11k (David Becker)",
		date = "2010-02-07",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

function gadget:Initialize()
	GG.maxBlob=tonumber(Spring.GetModOptions().maxblobs) or 20
	_G.maxBlob=GG.maxBlob
end

else

--UNSYNCED

return false

end
