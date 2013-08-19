function gadget:GetInfo()
	return {
		name = "Eject",
		desc = "implements the Eject command",
		author = "KDR_11k (David Becker)",
		date = "2008-02-10",
		license = "Public Domain",
		layer = 10,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE, CMD_EJECT = VFS.Include("LuaRules/Header/header.lua", nil, VFS.MOD)
local master=UnitDefNames.master.id


if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local black=UnitDefNames.black.id

local blobNum={[red]=0, [green]=1, [blue]=2, [black]=3}
local blobName={"red","green","blue","black"}
local blobId={red,green,blue,black}

local makeJoinList={}

local InsertUnitCmdDesc=Spring.InsertUnitCmdDesc
local GetTeamUnitsByDefs=Spring.GetTeamUnitsByDefs
local GetUnitPosition=Spring.GetUnitPosition
local GetUnitsInCylinder=Spring.GetUnitsInCylinder
local GetUnitDefID=Spring.GetUnitDefID
local GetUnitCommands=Spring.GetUnitCommands
local GiveOrderToUnit=Spring.GiveOrderToUnit

function gadget:UnitCreated(u, ud, team)
	if higherUnits[ud] then
		for c,n in pairs(blobs) do
			if higherUnits[ud].contents[c] then
				InsertUnitCmdDesc(u, {
					name="Eject "..n[1],
					tooltip="Remove a loaded "..n[1].." unit, shift-click for 5, ctrl-click for 20\nhold ALT to send the ejected units to the Master converter\nRightclick for the reverse\n(make nearby units join this or send units from the MC)",
					id = CMD_EJECT + blobNum[c],
					type = CMDTYPE.ICON,
					texture=n[2],
				})
			end
		end
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param,opt)
	if cmd >= CMD_EJECT and cmd < CMD_EJECT + 3 then
		if higherUnits[ud] then
			local count = 1
			if opt.shift then
				count=5
			end
			if opt.ctrl then
				count=count*20
			end
			local target=nil
			if opt.alt then
				local m = GetTeamUnitsByDefs(team,master)[1]
				if m then
					target = m
				end
			end
			local type=blobId[cmd - CMD_EJECT + 1]
			if opt.right then
				if not target then
					local x,_,z=GetUnitPosition(u)
					for _,t in ipairs(GetUnitsInCylinder(x,z,900,team)) do
						if GetUnitDefID(t) == type then
							local cq = GetUnitCommands(t)[1]
							if not cq or cq.id~=CMD_JOIN then
								makeJoinList[t]=u
								count = count -1
								if count <= 0 then
									break
								end
							end
						end
					end
				else
					GG.EjectBlobs(target,master,higherUnits[master].contents[type],count,false,blobName[cmd - CMD_EJECT + 1],u)
				end
			else
				GG.EjectBlobs(u,ud,higherUnits[ud].contents[type],count,false,blobName[cmd - CMD_EJECT + 1],target)
			end
		end
		return false
	end
	return true
end

function gadget:GameFrame(f)
	for t,u in pairs(makeJoinList) do
		GiveOrderToUnit(t,CMD_JOIN,{u},{})
		makeJoinList[t]=nil
	end
end

else

--UNSYNCED

return false

end
