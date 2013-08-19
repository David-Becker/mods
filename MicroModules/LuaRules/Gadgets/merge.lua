function gadget:GetInfo()
	return {
		name = "Merge",
		desc = "allows blobs to merge with other blobs",
		author = "KDR_11k (David Becker)",
		date = "2008-09-03",
		license = "Public Domain",
		layer = 10,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE = VFS.Include("LuaRules/Header/header.lua", nil, VFS.MOD)

local mergeDesc={
	name="Merge",
	tooltip="Merge to form a higher unit",
	id=CMD_MERGE,
	type=CMDTYPE.ICON_UNIT,
	cursor="Load units",
	action="load",
}
local mergeDist=50;


if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local mgList={}     --MoveGoals
local mergeList={}  --Merge processes

function gadget:UnitCreated(u, ud, team)
	if blobs[ud] then
		Spring.InsertUnitCmdDesc(u, mergeDesc)
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opt)
	if cmd == CMD_MERGE then
		local tud=Spring.GetUnitDefID(param[1])
		if u ~= param[1] and blobs[ud] and tud and blobs[tud] and Spring.GetUnitTeam(param[1]) == team then
			return true
		else
			return false
		end
	end
	return true
end

local GetUnitPosition=Spring.GetUnitPosition
local GetUnitSeparation=Spring.GetUnitSeparation
local SetUnitMoveGoal=Spring.SetUnitMoveGoal
local GetUnitIsStunned=Spring.GetUnitIsStunned

function gadget:CommandFallback(u, ud, team, cmd, param, opt)
	if cmd == CMD_MERGE then
		local x,y,z=GetUnitPosition(param[1])
		local dist=GetUnitSeparation(u, param[1])
		if not dist then
			return true, true
		end
		if dist > mergeDist then
			mgList[u]={x,y,z}
			return true, false
		else
			if Spring.GetGroundHeight(x,z) < 1 then
				Spring.SendMessageToTeam(team,"Can't merge over water!")
				return true, true
			end
			mergeList[u]=param[1]
			return true, true
		end
	end
	return false
end

function gadget:GameFrame(f)
	for u,d in pairs(mgList) do
		SetUnitMoveGoal(u,d[1],d[2],d[3],mergeDist*.75)
		mgList[u]=nil
	end
	local merged={}
	for u,t in pairs(mergeList) do
		if not GetUnitIsStunned(u) and not GetUnitIsStunned(u) and not merged[u] and not merged[t] then
			local ud= Spring.GetUnitDefID(u)
			local tud=Spring.GetUnitDefID(t)
			local x,y,z=Spring.GetUnitPosition(t)
			local team=Spring.GetUnitTeam(u)
			local nu=GG.NewUnit(mergeTable[ud][tud],x,y,z,0,team)
			Spring.DestroyUnit(u,false, true)
			Spring.DestroyUnit(t,false, true)
			merged[u]=true
			merged[t]=true
		end
		mergeList[u]=nil
	end
end

else

--UNSYNCED

return false

end
