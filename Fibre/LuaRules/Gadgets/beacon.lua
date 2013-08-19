function gadget:GetInfo()
	return {
		name = "Beacon",
		desc = "Handles the Beacon's commands",
		author = "KDR_11k (David Becker)",
		date = "2007-11-22",
		license = "None",
		layer = 1,
		enabled = true
	}
end

local CMD_BEACON = 32123
local beacon = UnitDefNames.beacon.id

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local parent
local factory
local factories
local beaconMode= {}
local beaconEvalList = {}
local beaconStopList = {}

moveTo= {
		id=CMD_BEACON,
		name="Move",
		tooltip = "relocate beacon",
		type = CMDTYPE.ICON_UNIT_OR_MAP,
		action = "move"
	}

function gadget:UnitCreated(u, ud, team)
	if ud == beacon then
		local descs = Spring.GetUnitCmdDescs(u)
		for _,d in ipairs(descs) do
			Spring.RemoveUnitCmdDesc(u,d)
		end
		Spring.InsertUnitCmdDesc(u,moveTo)
		beaconMode[u] = 0
		Spring.SetUnitBlocking(u, true)
	elseif factory and factory[ud] then
		Spring.InsertUnitCmdDesc(u,moveTo)
	end
end

function gadget:UnitDestroyed(u,ud,team,au,aud,ateam)
	beaconMode[u] = nil
	for i,t in pairs(beaconMode) do
		if t==u then
			table.insert(beaconStopList,i)
		end
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opts)
	if factory[ud] and cmd == CMD_BEACON then --redirect this action to the beacon
		u = factories[u].beacon
		ud = beacon
	end
	if ud == beacon then
		if cmd ~= CMD_BEACON then
			return false
		else
			local cx,cy,cz = Spring.GetUnitPosition(parent[u])
			local dist = factory[Spring.GetUnitDefID(parent[u])].range
			if param[2] then
				if math.sqrt((param[1]-cx)*(param[1]-cx) + (param[3]-cz)*(param[3]-cz)) < dist then
					Spring.SetUnitPosition(u, param[1], param[3])
					beaconMode[u] = 0
				else
					return false
				end
			else
				local x,y,z = Spring.GetUnitPosition(param[1])
				if math.sqrt((x-cx)*(x-cx)+(z-cz)*(z-cz)) < dist then
					Spring.SetUnitPosition(u, x, z)
					if team ~= Spring.GetUnitTeam(param[1]) then
						beaconMode[u] = param[1]
					else
						beaconMode[u] = 0
					end
				else
					return false
				end
			end
			Spring.SetUnitBlocking(u, false)
			return true --let Charge.lua relay the info
		end
	elseif cmd == CMD_BEACON then
		return false
	end
	return true
end

function gadget:CommandFallback(u,ud,team,cmd,param,opts)
	if cmd == CMD_BEACON then
		if ud==beacon then
			table.insert(beaconEvalList, {u=u,param=param})
		else
			table.insert(beaconEvalList, {u=factories[u].beacon,param=param})
		end
	end
end

function gadget:Initialize()
	GG.beaconMode = beaconMode
end

function gadget:GameFrame(f)
	if not parent then
		parent = GG.parent
		factory = GG.factory
		factories = GG.factories
	end
	for i,b in pairs(beaconEvalList) do
		local u = b.u
		local param = b.param
		if factories[parent[u]] then
			if param[2] then
				Spring.GiveOrderToUnitMap(factories[parent[u]].children, CMD.FIRE_STATE, {2}, {})
				Spring.GiveOrderToUnitMap(factories[parent[u]].children, CMD.MOVE, param, {"alt"})
			else
				if Spring.GetUnitTeam(u) ~= Spring.GetUnitTeam(param[1]) then
					if factory[Spring.GetUnitDefID(parent[u])].noStray then
						Spring.GiveOrderToUnitMap(factories[parent[u]].children, CMD.FIRE_STATE, {0}, {})
					end
					Spring.GiveOrderToUnitMap(factories[parent[u]].children, CMD.ATTACK, param, {})
				else
					local x,y,z = Spring.GetUnitPosition(param[1])
					Spring.GiveOrderToUnitMap(factories[parent[u]].children, CMD.FIRE_STATE, {2}, {})
					Spring.GiveOrderToUnitMap(factories[parent[u]].children, CMD.MOVE, {x,y,z}, {"alt"})
				end
			end
			factories[parent[u]].regroup=true
		end
		beaconEvalList[i] = nil
	end

	for i,b in pairs(beaconStopList) do
		beaconMode[b]=0
		local x,y,z = Spring.GetUnitPosition(b)
		Spring.GiveOrderToUnitMap(factories[parent[b]].children, CMD.FIRE_STATE, {2}, {})
		Spring.GiveOrderToUnitMap(factories[parent[b]].children, CMD.MOVE, {x,y,z}, {"alt"})
		beaconStopList[i] = nil
	end

	--update beacon positions
	local doVerify = (f % 16 < 0.5)
	for b,t in pairs(beaconMode) do
		if t ~= 0 then
			local x,y,z = Spring.GetUnitPosition(t)
			Spring.SetUnitPosition(b,x,z)
			Spring.SetUnitBlocking(b,false)
			if doVerify then
				if Spring.GetUnitSeparation(t,parent[b],true) > factory[Spring.GetUnitDefID(parent[b])].range then
					beaconMode[b] = 0
				end
			end
		end
	end
end

else

local function DrawConnection(x,y,z,tx,ty,tz,offset,height,length)
	gl.TexCoord(0,0)
	gl.Vertex(x,y + offset,z)
	gl.TexCoord(0,1)
	gl.Vertex(x,y + offset + height,z)
	gl.TexCoord(length,0)
	gl.Vertex(tx,ty+offset,tz)
	gl.TexCoord(length,1)
	gl.Vertex(tx,ty+offset+height,tz)
end

function gadget:DrawWorldPreUnit()
	for _,u in ipairs(Spring.GetTeamUnitsByDefs(Spring.GetLocalTeamID(), beacon)) do
		if SYNCED.parent[u] then
			local x,y,z = Spring.GetUnitBasePosition(u)
			local r,g,b = Spring.GetTeamColor(Spring.GetUnitTeam(u))
			gl.Texture("bitmaps/arrow.tga")
			gl.Color(r,g,b,.8)
			local tx,ty,tz = Spring.GetUnitBasePosition(SYNCED.parent[u])
			gl.BeginEnd(GL.TRIANGLE_STRIP, DrawConnection,x,y,z,tx,ty,tz,0,16,math.sqrt((x-tx)*(x-tx) + (z-tz)*(z-tz))/16)
			gl.Color(1,1,1,1)
			gl.Texture(false)
		end
	end
end

end
