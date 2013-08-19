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

local citadel = UnitDefNames.citadel.id
local destroyList={}

function gadget:AllowUnitTransfer(u, ud, team, newteam, capture)
	if ud == citadel then
		table.insert(destroyList, u)
		return false
	end
	return capture
end

function gadget:GameFrame(f)
	for i,u in pairs(destroyList) do
		Spring.DestroyUnit(u)
		destroyList[i]=nil
	end
end

end
