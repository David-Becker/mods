function gadget:GetInfo()
	return {
		name = "Spawn",
		desc = "Lets the Citadel spawn everything it wants to",
		author = "KDR_11k (David Becker)",
		date = "2007-11-18",
		license = "None",
		layer = 10,
		enabled = true
	}
end

local nodePartCost = Spring.GetModOptions().nodepartcost ~= "0"
local nodeCost = 3
local maxNodeCost = 180
local nodeRange=200
local nodeConnect=500
local CMD_CANCEL=31998
local partCapacity = 200

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local citadel = UnitDefNames["citadel"].id
local node = UnitDefNames.node.id
local spawnList={}
local citadelList
local teamParts
local teamNodeCost={}

local placeCost = 0

function gadget:Initialize()
	teamParts = GG.teamParts
	citadelList=GG.citadelList
	for _,t in ipairs(Spring.GetTeamList()) do
		teamNodeCost[t] = 0
	end
	_G.teamNodeCost = teamNodeCost
	GG.teamNodeCost = teamNodeCost
	GG.nodePartCost = nodePartCost
	GG.maxNodeCost = maxNodeCost
	_G.toBeBuilt = spawnList
end

function gadget:AllowCommand(u,ud,team,cmd,params,opts)
	if(ud == citadel and cmd < 0) then
		local c={}
		c.team = team
		c.type = UnitDefs[-cmd].name
		c.typeid = -cmd
		c.x = params[1]
		c.y = params[2]
		c.z = params[3]
		c.heading = params[4]
		local ok, f = Spring.TestBuildOrder(-cmd, c.x, c.y, c.z, c.heading)
		if ok == 2 and not f then
			for _,u in ipairs(Spring.GetUnitsInCylinder(c.x, c.z, (-cmd == node and nodeConnect) or nodeRange, team)) do
				if GG.citadelList[team] == u or (GG.nodeList[u] and GG.nodeList[u].done) then
					table.insert(spawnList, c)
					break
				end
			end
		end
		return false
	end
	return true
end

function gadget:CommandFallback(u,ud,team,cmd,params,opts)
	if ud == citadel then
		for i,c in pairs(spawnList) do
			if c.team == team then
				spawnList[i] = nil
			end
		end
	end
	return true, true
end

function gadget:GameFrame(f)
	if f%8 < .1 then
		for i,c in pairs(spawnList) do
			local ok, f = Spring.TestBuildOrder(c.typeid, c.x, c.y, c.z, c.heading)
			if citadelList[c.team] and ok == 2 and not f then
				local charge = Spring.GetUnitCOBValue(citadelList[c.team],1024)
				if nodePartCost and c.typeid == node then
					if charge >= placeCost and math.min(teamNodeCost[c.team], maxNodeCost) <= teamParts[c.team] then
						teamParts[c.team] = teamParts[c.team] - math.min(teamNodeCost[c.team], maxNodeCost)
						Spring.CreateUnit(c.type, c.x, c.y, c.z, c.heading, c.team)
						spawnList[i]=nil
						Spring.SetUnitCOBValue(citadelList[c.team],1024,charge - placeCost)
					end
				else
					if charge >= placeCost then
						Spring.CreateUnit(c.type, c.x, c.y, c.z, c.heading, c.team)
						spawnList[i]=nil
						Spring.SetUnitCOBValue(citadelList[c.team],1024,charge - placeCost)
					end
				end
			else
				spawnList[i]=nil
			end
		end
	end
end

function gadget:UnitTaken(u, ud, team, newTeam)
	if ud == node then
		local c = 0
		for _,n in ipairs(Spring.GetTeamUnitsByDefs(team, node)) do
			if GG.nodeList[n] then
				c = c + nodeCost
			end
		end
		teamNodeCost[team] = c
	end
end

function gadget:UnitGiven(u, ud, team, oldTeam)
	if ud == node then
		local c = 0
		for _,n in ipairs(Spring.GetTeamUnitsByDefs(team, node)) do
			if GG.nodeList[n] then
				c = c + nodeCost
			end
		end
		teamNodeCost[team] = c
	end
end

function gadget:UnitDestroyed(u, ud, team)
	if ud == node then
		local c = 0
		for _,n in ipairs(Spring.GetTeamUnitsByDefs(team, node)) do
			if GG.nodeList[n] then
				c = c + nodeCost
			end
		end
		teamNodeCost[team] = c
	end
end

function gadget:UnitCreated(u, ud, team)
	if ud == node then
		local c = 0
		for _,n in ipairs(Spring.GetTeamUnitsByDefs(team, node)) do
			if GG.nodeList[n] then
				c = c + nodeCost
			end
		end
		teamNodeCost[team] = c
	elseif ud == citadel then
		local descs = Spring.GetUnitCmdDescs(u)
		for _,d in ipairs(descs) do
			Spring.RemoveUnitCmdDesc(u,d)
		end
		local stop={
			id = CMD_CANCEL,
			name = "Cancel",
			tooltip = "cancel all pending building placements",
			action="stop",
			type=CMDTYPE.ICON
		}
		Spring.InsertUnitCmdDesc(u, stop)
		for _,o in pairs(UnitDefs[ud].buildOptions) do
			local desc={
				id = -o, --CMD_SPAWN + o,
				name = UnitDefs[o].humanName,
				tooltip = UnitDefs[o].humanName.."\n"..
						  UnitDefs[o].tooltip .."\n"..
						  "Cost: "..UnitDefs[o].energyCost.."\n"..
						  "Energy: "..UnitDefs[o].energyMake.."/"..UnitDefs[o].energyStorage.."\n",
				action="buildunit_"..UnitDefs[o].name,
				type=CMDTYPE.ICON_BUILDING
			}
			if GG.factory[o] then
				desc.tooltip = desc.tooltip.."Unit cost: P:"..GG.factory[o].mcost.." E:"..GG.factory[o].ecost.."\n"
			end
			Spring.InsertUnitCmdDesc(u, desc)
		end
	end
end

else

function gadget:DrawWorld()
	for i,c in spairs(SYNCED.toBeBuilt) do
		if c.team == Spring.GetLocalTeamID() then
			gl.PushMatrix()
			gl.Translate(c.x, c.y, c.z)
			gl.Rotate(90 * c.heading, 0,1,0)
			gl.Blending(GL.ONE, GL.ONE)
			gl.DepthTest(GL.LEQUAL)
			gl.UnitShape(c.typeid, c.team)
			gl.DepthTest(false)
			gl.PopMatrix()
		end
	end
end

function gadget:DrawScreen(vsx, vsy)
	if nodePartCost then
		gl.Text("Node Part Cost:"..math.min(SYNCED.teamNodeCost[Spring.GetLocalTeamID()], maxNodeCost), vsx - 80, vsy - 50, 11, "ro")
		gl.Color(1,1,0,.8)
		gl.Rect(vsx-22-(vsx/2 -24)*math.min(SYNCED.teamNodeCost[Spring.GetLocalTeamID()], maxNodeCost)/partCapacity, vsy-30, vsx-22-(vsx/2 -24)*(1+math.min(SYNCED.teamNodeCost[Spring.GetLocalTeamID()], maxNodeCost))/partCapacity, vsy-12)
		gl.Color(1,1,1,1)
	end
end

end
