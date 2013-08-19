function gadget:GetInfo()
	return {
		name = "null",
		desc = "null gadget",
		author = "KDR_11k (David Becker)",
		date = "2008-02-10",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

else

--UNSYNCED

return false

end
