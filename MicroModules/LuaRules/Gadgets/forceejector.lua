function gadget:GetInfo()
	return {
		name = "Force Ejector",
		desc = "Makes the green tank force blobs to leave the target",
		author = "KDR_11k (David Becker)",
		date = "2008-09-13",
		license = "Public Domain",
		layer = 9,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE = VFS.Include("LuaRules/Header/header.lua", nil, VFS.MOD)


if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local GetUnitCOBValue = Spring.GetUnitCOBValue
local random=math.random

local gtwep = WeaponDefNames.tankgreengun.id

function gadget:UnitDamaged(u, ud, team, damage, para, weapon)
	if weapon == gtwep and higherUnits[ud] then
		local bcs = {}
		local n = 1
		for i=1,3 do
			local count = GetUnitCOBValue(u,blobCount+i)
			if count > 0 then
				bcs[n]=i
				n=n+1
			end
		end
		if n > 2 then
			GG.EjectBlobs(u,ud,bcs[random(#bcs -1)],1,true)
		elseif n == 2 then
			GG.EjectBlobs(u,ud,bcs[1],1,true)
		end
	end
end

else

--UNSYNCED

return false

end
