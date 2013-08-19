function gadget:GetInfo()
	return {
		name = "activate captured",
		desc = "Makes all captured units turn on",
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
local activateList={}

function gadget:UnitGiven(u,ud,team,oldTeam)
	table.insert(activateList,u)
end

function gadget:GameFrame(f)
	for i,u in pairs(activateList) do
		Spring.GiveOrderToUnit(u, CMD.ONOFF, {1}, {})
		activateList[i]=nil
	end
end

end
