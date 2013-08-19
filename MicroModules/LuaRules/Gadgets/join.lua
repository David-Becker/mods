function gadget:GetInfo()
	return {
		name = "Join",
		desc = "allows blobs to merge into higher units",
		author = "KDR_11k (David Becker)",
		date = "2008-09-03",
		license = "Public Domain",
		layer = 10,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE = VFS.Include("LuaRules/Header/header.lua", nil, VFS.MOD)

local joinDesc={
	name="Join",
	tooltip="Join a higher unit",
	id=CMD_JOIN,
	type=CMDTYPE.ICON_UNIT,
	cursor="Load units",
	action="load",
}
local joinDist=100;


if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local mgList={}     --MoveGoals
local joinList={}   --Join processes

function gadget:UnitCreated(u, ud, team)
	if blobs[ud] then
		Spring.InsertUnitCmdDesc(u, joinDesc)
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opt)
	if cmd == CMD_JOIN then
		local tud=Spring.GetUnitDefID(param[1])
		if blobs[ud] and tud and higherUnits[tud] and Spring.GetUnitTeam(param[1]) == team then
			if higherUnits[tud].contents[ud] then
				return true
			else
				return false
			end
		else
			return false
		end
	end
	return true
end

function gadget:CommandFallback(u, ud, team, cmd, param, opt)
	if cmd == CMD_JOIN then
		local x,y,z=Spring.GetUnitPosition(param[1])
		local dist=Spring.GetUnitSeparation(u, param[1])
		if dist then
			if dist > joinDist then
				mgList[u]={x,y,z}
				return true, false
			else
				joinList[u]=param[1]
				return true, true
			end
		else
			return true, true
		end
	end
	return false
end

function gadget:GameFrame(f)
	for u,d in pairs(mgList) do
		Spring.SetUnitMoveGoal(u,d[1],d[2],d[3],joinDist*.75)
		mgList[u]=nil
	end
	for u,t in pairs(joinList) do
		local ud= Spring.GetUnitDefID(u)
		local tud=Spring.GetUnitDefID(t)
		local hu= higherUnits[tud]
		local blobType=hu.contents[ud]
		GG.AddBlobs(t, tud, blobType, 1)
		GG.MergeJump(u,t)
		Spring.DestroyUnit(u,false, true)
		joinList[u]=nil
	end
end

else

--UNSYNCED

return false

end
