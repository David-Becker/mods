function gadget:GetInfo()
	return {
		name = "teleporter",
		desc = "implements the teleporter",
		author = "KDR_11k (David Becker)",
		date = "2007-12-16",
		license = "None",
		layer = 1,
		enabled = true
	}
end

local teleporter = UnitDefNames.teleporter.id
local CMD_TELEPORT = 32601
local node = UnitDefNames.node.id
local citadel = UnitDefNames.citadel.id
local unteleportable = {}
local blockList={}

if (gadgetHandler:IsSyncedCode()) then

--SYNCED
teled = {
		name="Teleport",
		tooltip="Teleport a building to the location of this teleporter",
		action="loadunits",
		type=CMDTYPE.ICON_UNIT,
		id=CMD_TELEPORT
	}
	
function gadget:Initialize()
	unteleportable[UnitDefNames.citadel.id] = true
	unteleportable[UnitDefNames.node.id] = true
	unteleportable[UnitDefNames.neutral_doomsday.id] = true
	unteleportable[UnitDefNames.neutral_nukelauncher.id] = true
	unteleportable[UnitDefNames.neutral_supercharger.id] = true
	unteleportable[UnitDefNames.factory_ship.id] = true
	unteleportable[UnitDefNames.turret_sea.id] = true
end

function gadget:UnitCreated(u, ud, team)
	if ud == teleporter then
		Spring.InsertUnitCmdDesc(u, teled)
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opts)
	if cmd == CMD_TELEPORT then
		if ud == teleporter then
			if Spring.GetUnitTeam(param[1]) == team and not unteleportable[Spring.GetUnitDefID(param[1])] and GG.parent[param[1]] and (Spring.GetUnitDefID(GG.parent[param[1]]) == node or Spring.GetUnitDefID(GG.parent[param[1]]) == citadel) then
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

function gadget:CommandFallback(u, ud, team, cmd, param, opts)
	if cmd == CMD_TELEPORT then
		if Spring.GetUnitCOBValue(u,1024) == 150 then
			local x,y,z = Spring.GetUnitPosition(u)
			Spring.SetUnitPosition(param[1], x,y,z)
			GG.parent[param[1]] = GG.parent[u]
			Spring.CallCOBScript(u, "TeleportFX", 0)
			table.insert(blockList,{param[1],60 + Spring.GetGameFrame()})
			Spring.SetUnitBlocking(param[1],true)
			return true, true
		else
			return true, false
		end
	end
	return false
end

function gadget:GameFrame(f)
	if f % 32 < .1 then
		for i,u in pairs(blockList) do
			Spring.SetUnitBlocking(u[1], true) --must be delayed until after the teleport is deleted
			if f >= u[2] then
				blockList[i]=nil
			end
		end
	end
end

end
