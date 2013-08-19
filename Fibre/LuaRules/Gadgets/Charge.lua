function gadget:GetInfo()
	return {
		name = "Charge",
		desc = "Handles the entirety of Fibre's charge system",
		author = "KDR_11k (David Becker)",
		date = "2007-11-18",
		license = "None",
		layer = 1,
		enabled = true
	}
end

local nodeRange=200
local nodeConnect=500
local nodeMaxCharge=10
local nodeChargeLimit=1000
local citadelCharge=30
local buildStep = 20
local superchargerCharge = 50
local partCapacity = 200
local units = {}
local beacon = UnitDefNames.beacon.id
local hostileIndicator=UnitDefNames.hostile_main.id
local beaconMode
local partCost = 40

local function nameUnits()
	units[UnitDefNames.unit_light.id] = true
	units[UnitDefNames.unit_armor.id] = true
	units[UnitDefNames.unit_gunship.id] = true
	units[UnitDefNames.unit_bomber.id] = true
	units[UnitDefNames.unit_ship.id] = true
	units[UnitDefNames.turret_projectile.id] = true --not really a unit but whatever
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED
--Charge shall be UNIT_VAR 0

local parent = {} --each unit's parent
local canHaveChildren = {} --units that need checking for children on change
local nodeList = {} --node data
local citadelList = {}
local constructionList = {}
local chargeList = {}
local destroyList = {}
local neutralizeList = {}
local createList = {}
local citadel
local node
local supercharger
local fabber
local superchargers = {}
local factory = {}
local factories = {}
local change = 0
local teamParts = {}

function gadget:Initialize()
	nameUnits()
	citadel = UnitDefNames.citadel.id
	node = UnitDefNames.node.id
	supercharger = UnitDefNames.neutral_supercharger.id
	fabber = UnitDefNames.partmaker.id
	canHaveChildren[citadel]=true
	canHaveChildren[node]=true
	canHaveChildren[UnitDefNames.factory_light.id]=true
	canHaveChildren[UnitDefNames.factory_armor.id]=true
	canHaveChildren[UnitDefNames.factory_gunship.id]=true
	canHaveChildren[UnitDefNames.factory_bomber.id]=true
	canHaveChildren[UnitDefNames.factory_ship.id]=true
	canHaveChildren[UnitDefNames.turret_launcher.id]=true
	factory[UnitDefNames.factory_light.id] = {
		product = "unit_light",
		max = 30,
		range = 1100,
		offset = 20
	}
	factory[UnitDefNames.factory_armor.id] = {
		product = "unit_armor",
		max = 6,
		range = 1300,
		offset = 40
	}
	factory[UnitDefNames.factory_gunship.id] = {
		product = "unit_gunship",
		max = 4,
		range = 1600,
		offset = 0,
		noStray=false
	}
	factory[UnitDefNames.factory_bomber.id] = {
		product = "unit_bomber",
		max = 1,
		range = 3000,
		offset = 2,
		noStray=true
	}
	factory[UnitDefNames.factory_ship.id] = {
		product = "unit_ship",
		max = 2,
		range = 999999,
		offset = 70,
		noStray=false
	}
	for ud,d in pairs(factory) do
		d.ecost = UnitDefNames[d.product].energyCost
		d.mcost = UnitDefNames[d.product].metalCost
	end
	if Spring.GetModOptions().infiniterange == "1" then
		factory[UnitDefNames.factory_light.id].range=999999;
		factory[UnitDefNames.factory_armor.id].range=999999;
		factory[UnitDefNames.factory_gunship.id].range=999999;
		factory[UnitDefNames.factory_bomber.id].range=999999;
	end
	_G.chargeList=chargeList
	_G.constructionList=constructionList
	_G.nodeList=nodeList
	_G.parent=parent
	_G.factory=factory
	GG.parent = parent
	GG.factory = factory
	GG.factories = factories
	GG.citadelList = citadelList
	GG.nodeList = nodeList
	beaconMode = GG.beaconMode
	_G.change = 0

	for _,t in ipairs(Spring.GetTeamList()) do
		teamParts[t]=30
	end
	_G.teamParts=teamParts
	GG.teamParts=teamParts
end

local function FindNode(x,z,range,team,unit,maxhops)
	if not x then
		return nil
	end
	if team == Spring.GetGaiaTeamID() then
		team=nil
	end
	local nl = Spring.GetUnitsInCylinder(x,z,range,team)
	local minhops = 65536
	local maxCharge = -1
	if maxhops then
		minhops=maxhops+1
	end
	local p
	local hops
	for _,t in ipairs(nl) do
		local charge = Spring.GetUnitCOBValue(t, 1024)
		if t~=unit and Spring.GetUnitTeam(t) ~= Spring.GetGaiaTeamID() then
			if t == citadelList[Spring.GetUnitTeam(t)] and charge > maxCharge then
				minhops=0
				p=t
				hops=1
				maxCharge = charge
			elseif nodeList[t] and nodeList[t].done and parent[t] and charge > maxCharge then --nodeList[t].hops < minhops then
				minhops = nodeList[t].hops
				p=t
				hops=minhops + 1
				maxCharge = charge
			end
		end
	end
	return p, hops
end

local function nodeValue(n)
	local x,y,z = Spring.GetUnitPosition(n)
	local output = nodeMaxCharge
	for _,u in ipairs(Spring.GetUnitsInCylinder(x,z,nodeRange*2,nil)) do
		if nodeList[u] then
			if u ~= n then
				local cx, cy, cz = Spring.GetUnitPosition(u)
				local dist = math.sqrt((x-cx)*(x-cx) + (z-cz)*(z-cz))
				output = output - nodeMaxCharge/2 + nodeMaxCharge * (dist / nodeRange / 2)/2
			end
		end
	end
	if output <= 0 then
		output =0
	end
	return math.ceil(output)
end

local function calcNodeValueLocal(n)
	local x,y,z = Spring.GetUnitPosition(n)
	for _,u in ipairs(Spring.GetUnitsInCylinder(x,z,nodeRange*2,nil)) do
		if nodeList[u] then
			nodeList[u].charge = nodeValue(u)
		end
	end
end

local function calcNodeValues()
	for _,u in ipairs(Spring.GetAllUnits()) do
		if nodeList[u] then
			nodeList[u].charge = nodeValue(u)
		end
	end
end

local function UnlinkNode(n)
	for u,p in pairs(parent) do --yes, this is inefficient but I hope it won't happen often
		if p==n then
			parent[u]=nil
			UnlinkNode(n)
		end
	end
end

local function RebuildNodes(team)
	_G.change = _G.change + 1
	local workingOn={}
	local toBeDone={}
	for n,d in pairs(nodeList) do
		if Spring.GetUnitTeam(n) == team then
			toBeDone[n]=true
			d.parent=nil
			parent[n]=nil
		end
	end
	if citadelList[team] then --if not then the team's dead anyway
		local x,y,z = Spring.GetUnitPosition(citadelList[team])
		for _,pn in ipairs(Spring.GetUnitsInCylinder(x,z, nodeConnect, team)) do
			if nodeList[pn] then
				table.insert(workingOn, pn)
			end
		end
		local changes = true
		while workingOn ~= {} and changes do
			changes=false
			for i,u in pairs(workingOn) do
	--			if not parent[u] then
					x,y,z = Spring.GetUnitPosition(u)
					if x then --seems necessary
						local hops
						local newOnes={}
						parent[u], hops = FindNode(x,z,nodeConnect,team)
						for _,pn in ipairs(Spring.GetUnitsInCylinder(x,z, nodeConnect, team)) do
							if nodeList[pn] then
								table.insert(newOnes, pn)
							end
						end
						for _,new in ipairs(newOnes) do
							if toBeDone[new] then
								table.insert(workingOn,new)
								toBeDone[new]=nil
							end
						end
						if parent[u] then
							changes = true
							if not nodeList[u] then
								nodeList[u]={done = true}
								calcNodeValueLocal(u)
							end
							nodeList[u].parent=parent[u]
							nodeList[u].hops=hops
							workingOn[i]=nil
						end
					end
	--			end
			end
		end
	end
end


function gadget:UnitCreated(u,ud,team)
	if citadelList[team] or ud == citadel or team== Spring.GetGaiaTeamID() then --otherwise it's not in our jurisdiction
		chargeList[u]=0
		if(ud == citadel) then
			_G.change = _G.change + 1
			citadelList[team] = u
		elseif (units[ud]) then
			--nothing
		elseif (ud == beacon) then
			--nothing
		else
			local c = {}
			if(team ~= Spring.GetGaiaTeamID()) then
				c.max = UnitDefs[ud].energyCost
				c.left = c.max
				constructionList[u] = c
				Spring.SetUnitHealth(u,{health = 0})
				--Spring.SetUnitBlocking(u, false)
			else
				Spring.SetUnitBlocking(u, true)
				Spring.CallCOBScript(u, "Completed", 0)
				if ud == supercharger then
					superchargers[u]=true
				end
			end
			Spring.SetUnitNeutral(u, true)
			if ud == node then
				_G.change = _G.change + 1
				c.node = true
				local n={}
				n.id=u
				n.team=team
				n.done=team == Spring.GetGaiaTeamID()
				--n.charge=nodeMaxCharge
				local x, y, z
				x,y,z = Spring.GetUnitPosition(u)
				n.parent, n.hops = FindNode(x,z,nodeConnect,team)
				nodeList[u]=n
				parent[u]=n.parent
				calcNodeValueLocal(u)
			else
				local x, y, z
				x,y,z = Spring.GetUnitPosition(u)
				if(team ~= Spring.GetGaiaTeamID()) then
					Spring.SetUnitNoDraw(u,true)
					local minhops = 65536
					parent[u] = FindNode(x,z,nodeRange,team)
				end
				if factory[ud] then
					factories[u] = {}
					factories[u].count = 0
					factories[u].children = {}
					factories[u].regroup = false
					local ox, oz = x, z
					local heading = Spring.GetUnitBuildFacing(u)
					if heading==0 or heading ==2 then
						oz = z + 100 - 100*heading
					else
						ox = x + 200 - 100*heading
					end
					local cu = {
						type="beacon",
						x=ox,
						y=y,
						z=oz,
						team=team,
						parent=u
					}
					table.insert(createList, cu)
				end
			end
		end
	end
end

function gadget:AllowCommand(u,ud,team,cmd,param,opts,synced)
	if units[ud] and not synced then
		return false
	end
	return true
end

function gadget:UnitDestroyed(u, ud, team, au, aud, ateam)
	superchargers[u]=nil --Superchargers are indestructable but meh...
	if units[ud] then
		if factories[parent[u]] then --could be that the fac is already dead
			factories[parent[u]].count = factories[parent[u]].count - 1
			factories[parent[u]].children[u] = nil
			if factories[parent[u]].beacon then
				chargeList[factories[parent[u]].beacon] = factories[parent[u]].count
			end
			if factories[parent[u]].count <= factory[Spring.GetUnitDefID(parent[u])].max / 2 then
				factories[parent[u]].regroup = false
			end
		end
	end
	if ud == node then
		_G.change = _G.change + 1
		nodeList[u] = nil
		calcNodeValues()
		if team ~= Spring.GetGaiaTeamID() then
			RebuildNodes(team)
		end
	end
	parent[u] = nil
	constructionList[u]=nil
	nodeList[u] = nil
	if ud==citadel then
		_G.change = _G.change + 1
		citadelList[team] = nil
		for _,t in ipairs(Spring.GetTeamUnits(team)) do
			table.insert(neutralizeList, t)
		end
	end
	if factory[ud] then
		factories[u] = nil
	end
	if(canHaveChildren[ud] and ud ~= citadel) then
		for t,p in pairs(parent) do
			if p == u then
				if ud ~=node then --if the lost unit was not a node
					table.insert(destroyList, t)
				else
					parent[t] = nil
					--if(Spring.GetUnitDefID(t) ~=node) then --if the child was not a node
						table.insert(neutralizeList, t)
					--end
				end
			end
		end
	end
end

function gadget:GameFrame(f)
	--destroys
	for i,u in pairs(createList) do
		local nu = Spring.CreateUnit(u.type, u.x, u.y, u.z, 0, u.team)
		parent[nu] = u.parent
		if u.type=="beacon" then
			factories[u.parent].beacon = nu
			Spring.SetUnitBlocking(nu,false)
		end
		createList[i]=nil
	end
	for i,u in pairs(destroyList) do
		Spring.DestroyUnit(u,true)
		destroyList[i]=nil
	end
	for i,u in pairs(neutralizeList) do
		Spring.TransferUnit(u, Spring.GetGaiaTeamID(), false)
		Spring.SetUnitNeutral(u, true)
		Spring.SetUnitCOBValue(u, 1024, 0) --discharge unit on neutralization
		chargeList[u]=0
		if(Spring.GetUnitDefID(u) == node) then
			parent[u]=nil
			for c,t in pairs(parent) do
				if t==u then
					parent[c]=nil
					table.insert(neutralizeList,c)
				end
			end
		elseif factories[u] then
			for t,_ in pairs(factories[u].children) do
				Spring.DestroyUnit(t)
			end
			factories[u].children = {}
			factories[u].count = 0
			Spring.TransferUnit(factories[u].beacon, Spring.GetGaiaTeamID(), false)
		end
		neutralizeList[i]=nil
	end


	--Charge producers
	if(f % 16 < 0.1) then
		for t,c in pairs(citadelList) do
			local charge
			charge=Spring.GetUnitCOBValue(c,1024) + citadelCharge
			if (charge > nodeChargeLimit) then
				charge=nodeChargeLimit
			end
			Spring.SetUnitCOBValue(c, 1024, charge)
			chargeList[c] = charge
		end
		for n,d in pairs(nodeList) do
			if Spring.GetUnitDefID(n) == node then
				local charge
				charge=Spring.GetUnitCOBValue(n,1024)
				if (d.done and Spring.GetUnitTeam(n) ~= Spring.GetGaiaTeamID()) then
					--If built and connected
					if parent[n] then
						charge=charge + d.charge
						if (charge > nodeChargeLimit) then
							charge=nodeChargeLimit
						end
						Spring.SetUnitCOBValue(n, 1024, charge)
					else
						--the node lost connection, reset all downwards connections
						for u, p in pairs(parent) do
							if p==n then
								if Spring.GetUnitDefID(u) ~= node then --nodes are exempt to let UnlinkNode do this
									parent[u]=nil
									table.insert(neutralizeList,u)
								end
							end
						end
						UnlinkNode(n)
						local x,y,z = Spring.GetUnitPosition(n)
						local p, hops = FindNode(x,z, nodeConnect, Spring.GetUnitTeam(n), n)
						if p then
							parent[n] = p
							d.parent = p
							d.hops = hops
						else
							table.insert(neutralizeList,n)
						end
					end
				end
				chargeList[n] = charge
			else
				nodeList[n]=nil
			end
		end

	--Repairs
	elseif((f - 1) % 64 < 0.1) then
		for _,u in pairs(Spring.GetAllUnits()) do
			local ud = Spring.GetUnitDefID(u)
			local health, maxhealth = Spring.GetUnitHealth(u)
			if (health and health < maxhealth and ud ~= beacon) then
				local charge = Spring.GetUnitCOBValue(u, 1024)
				if charge > 10 then
					health = health + maxhealth * 10 / UnitDefs[Spring.GetUnitDefID(u)].energyCost
					charge = charge - 10
					Spring.SetUnitHealth(u,health)
					Spring.SetUnitCOBValue(u,1024,charge)
					chargeList[u]=charge
				end
			end
		end

	--Buildings
	elseif((f - 2) % 16 < 0.1) then
		for _,u in ipairs(Spring.GetAllUnits()) do
			local ud = Spring.GetUnitDefID(u)
			if parent[u] and ud ~= beacon then
				local p = parent[u]
				if not constructionList[u] then
					if(ud ~= node) then
						local charge = Spring.GetUnitCOBValue(u, 1024)
						if (UnitDefs[ud] and charge < UnitDefs[ud].energyStorage) and Spring.GetUnitIsActive(u) then --no idea why the first condition is needed but it is
							local chargeVal=math.min(UnitDefs[ud].energyStorage - charge, UnitDefs[ud].energyMake)
							local nodeCharge = Spring.GetUnitCOBValue(p, 1024)
							if nodeCharge >= chargeVal then
								nodeCharge = nodeCharge - chargeVal
								charge = charge + chargeVal
								Spring.SetUnitCOBValue(u, 1024, charge)
								Spring.SetUnitCOBValue(p, 1024, nodeCharge)
								chargeList[p] = nodeCharge
							end
						end
						chargeList[u] = charge
					end
				end
			elseif ud ~= citadel and ud ~=beacon and ud ~= hostileIndicator then
				table.insert(neutralizeList, u)
			elseif ud == beacon and not parent[u] then
				Spring.DestroyUnit(u)
			end
		end

	--Constructions
	elseif((f - 4) % 16 < 0.1) then
		for u,c in pairs(constructionList) do
			if(parent[u]) then
				local charge
				local health, maxhealth = Spring.GetUnitHealth(u)
				charge = Spring.GetUnitCOBValue(parent[u],1024)
				if charge > buildStep then
					charge = charge - buildStep
					c.left = c.left - buildStep
					Spring.SetUnitBlocking(u, true)
					Spring.SetUnitNeutral(u, false)
					Spring.SetUnitHealth(u,{health = health + maxhealth * buildStep / UnitDefs[Spring.GetUnitDefID(u)].energyCost})
				end
				Spring.SetUnitCOBValue(parent[u],1024,charge)
				chargeList[parent[u] ] = charge
			else
				table.insert(destroyList, u) --ownerless constructions die immediately
			end
			if c.left <=0 then
				Spring.SetUnitNoDraw(u,false)
				Spring.CallCOBScript(u, "Completed", 0)
				constructionList[u]=nil
				if Spring.GetUnitDefID(u) == node then
					_G.change = _G.change + 1
					nodeList[u].done=true
				end
			end
		end

	--Part Fabbers
	elseif((f - 12) % 32 < 0.1) then
		for t,_ in pairs(teamParts) do
			for _,u in ipairs(Spring.GetTeamUnitsByDefs(t,fabber)) do
				local charge = Spring.GetUnitCOBValue(u, 1024)
				if charge >= partCost and teamParts[t] < partCapacity then
					charge = charge - partCost
					Spring.SetUnitCOBValue(u, 1024, charge)
					chargeList[u]=charge
					teamParts[t] = teamParts[t] + 1
					Spring.CallCOBScript(u, "Indicate", 0)
				end
			end
		end

	--Factories
	elseif((f - 10) % 32 < 0.1) then
		for u,d in pairs(factories) do
			local ud = Spring.GetUnitDefID(u)
			if d.count < factory[ud].max then
				local t = Spring.GetUnitTeam(u)
				local charge = Spring.GetUnitCOBValue(u,1024)
				if charge >= factory[ud].ecost and 
				         (teamParts[t] >= math.max(factory[ud].mcost, math.min(GG.teamNodeCost[t], GG.maxNodeCost))
				      or (not GG.nodePartCost and teamParts[t] >= factory[ud].mcost)) then
					teamParts[t] = teamParts[t] - factory[ud].mcost
					local x,y,z = Spring.GetUnitPosition(u)
					local heading = Spring.GetUnitBuildFacing(u)
					local ox, oz = x, z
					local dist = factory[ud].offset
					if heading==0 or heading ==2 then
						oz = z + dist - dist*heading
					else
						ox = x + 2*dist - dist*heading
					end
					local team = Spring.GetUnitTeam(u)
					local p = Spring.CreateUnit(factory[ud].product,ox,y,oz,heading,team)
					d.count = d.count + 1
					parent[p] = u
					Spring.SetUnitNoSelect(p, true)
					d.children[p] = true --easier to erase that way
					if d.beacon then
						if  d.regroup or d.count == factory[ud].max then
							if beaconMode[d.beacon] == 0 then
								local tx, ty, tz = Spring.GetUnitPosition(d.beacon)
								Spring.GiveOrderToUnitMap(d.children, CMD.FIRE_STATE, {2}, {})
								if not d.regroup then
									Spring.GiveOrderToUnitMap(d.children,CMD.MOVE,{tx,ty,tz},{})
								else
									Spring.GiveOrderToUnit(p,CMD.MOVE,{tx,ty,tz},{})
								end
							else
								if factory[ud].noStray then
									Spring.GiveOrderToUnitMap(d.children, CMD.FIRE_STATE, {0}, {})
								end
								if not d.regroup then
									Spring.GiveOrderToUnitMap(d.children,CMD.ATTACK,{beaconMode[d.beacon]},{})
								else
									Spring.GiveOrderToUnit(p,CMD.ATTACK,{beaconMode[d.beacon]},{})
								end
							end
							d.regroup = true
						else
							Spring.GiveOrderToUnit(p,CMD.MOVE,{5*(ox-x)+x,y,5*(oz-z)+z},{})
						end
						chargeList[d.beacon] = d.count
					end
					charge = charge - factory[ud].ecost
					Spring.SetUnitCOBValue(u,1024,charge)
					chargeList[u] = charge
				end
			end
		end


	--Superchargers
	elseif((f - 14) % 16 < 0.1) then
		for u,_ in pairs(superchargers) do
			if parent[u] and Spring.GetUnitCOBValue(u,1024) >= 300 then
				local charge = Spring.GetUnitCOBValue(parent[u],1024)
				if charge < nodeChargeLimit - superchargerCharge then
					charge = charge + superchargerCharge
				else
					charge = nodeChargeLimit
				end
				Spring.SetUnitCOBValue(parent[u],1024,charge)
				chargeList[parent[u]] = charge
			end
		end

	--Ownerless buildings
	elseif((f - 8) % 16 < 0.1) then
		for _,u in ipairs(Spring.GetTeamUnits(Spring.GetGaiaTeamID())) do
			local x, y, z, p
			x,y,z = Spring.GetUnitPosition(u)
			if Spring.GetUnitDefID(u) == node then
				_G.change = _G.change + 1
				parent[u]=nil
				if not nodeList[u] then
					nodeList[u]={done = true}
					calcNodeValueLocal(u)
				end
				p, nodeList[u].hops = FindNode(x,z,nodeConnect,team,u)
				nodeList[u].parent=p
			elseif(Spring.GetUnitDefID(u) == beacon) then
				--do nothing!
			else
				parent[u]=nil
				p = FindNode(x,z,nodeRange,team,u)
			end
			if p then
				Spring.TransferUnit(u, Spring.GetUnitTeam(p), false)
				Spring.SetUnitNeutral(u, false)
				parent[u]=p
				if factories[u] then
					Spring.TransferUnit(factories[u].beacon, Spring.GetUnitTeam(p), false)
				end
			end
		end
	end
end

else

local citadel = UnitDefNames.citadel.id
local node = UnitDefNames.node.id
local phase = 0
local change

function gadget:Initialize()
	nameUnits()
end

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

function DrawLuaGraphics()
	for _,u in ipairs(Spring.GetAllUnits()) do
		local ud = Spring.GetUnitDefID(u)
		if (ud == citadel or SYNCED.nodeList[u] and not SYNCED.constructionList[u]) then
			local x,y,z = Spring.GetUnitBasePosition(u)
			local r,g,b = Spring.GetTeamColor(Spring.GetUnitTeam(u))
			gl.Texture("bitmaps/whitecircle.tga")
			gl.Color(r,g,b,.3)
			gl.DepthTest(GL.LEQUAL)
			gl.PolygonOffset(-1,-25)
			gl.DrawGroundQuad(x - nodeRange,z - nodeRange,x + nodeRange,z + nodeRange, false, true)
			gl.PolygonOffset(false)
			gl.DepthTest(false)
			if SYNCED.parent[u] then
				gl.Color(r,g,b,.8)
				local tx,ty,tz = Spring.GetUnitBasePosition(SYNCED.parent[u])
				gl.BeginEnd(GL.TRIANGLE_STRIP, DrawConnection,x,y,z,tx,ty,tz,20,5,1)
			end
			gl.Color(1,1,1,1)
			gl.Texture(false)
		end
	end
end

local list

function gadget:DrawWorldPreUnit()
	if SYNCED.change ~= change or not list then
		change = SYNCED.change
		if (list) then
			gl.DeleteList(list)
		end
		list = gl.CreateList(DrawLuaGraphics)
	end
	gl.CallList(list)
end

function gadget:DrawWorld()
	if not Spring.IsGUIHidden() then
		local team = Spring.GetLocalTeamID()
		phase = phase + 0.1
		for _,u in ipairs(Spring.GetAllUnits()) do --if this was GetVisible it wouldn't draw the NoDraw units
			local ud = Spring.GetUnitDefID(u)
			if not units[ud] and SYNCED.chargeList[u] then --units don't use a charge
				local x,y,z = Spring.GetUnitBasePosition(u)
				if x then
					local charge

					if SYNCED.constructionList[u] then
						charge = SYNCED.constructionList[u].left
						if not SYNCED.constructionList[u].node then
							gl.Blending(GL.ONE,GL.ONE)
							local col = 1-(SYNCED.constructionList[u].left / SYNCED.constructionList[u].max) + math.sin(phase)*.2
							gl.Color(col,col,col,1)
							gl.Lighting(false)
							gl.Culling(GL.BACK)
							gl.DepthTest(true)
							gl.Unit(u, true)
							gl.DepthTest(false)
							gl.Culling(false)
							gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
						end
						gl.Color(1,1,.2,1)
					else
						charge = SYNCED.chargeList[u]
					end

					if Spring.GetUnitTeam(u) == team then
						gl.PushMatrix()
						gl.Translate(x,y+Spring.GetUnitHeight(u)+10,z)
						gl.Billboard()
						gl.Text(string.format("%i",charge), 0, 0, 7, "ocn")
						gl.PopMatrix()
					end
					gl.Color(1,1,1,1)
				end
			end
		end
		for _,u in ipairs(Spring.GetSelectedUnits()) do
			local ud = Spring.GetUnitDefID(u)
			if ud == beacon then
				if SYNCED.parent[u] then
					local x,y,z = Spring.GetUnitPosition(SYNCED.parent[u])
					gl.Color(.5,1,.5,1)
					gl.DrawGroundCircle(x,y,z,SYNCED.factory[Spring.GetUnitDefID(SYNCED.parent[u])].range, 100)
					gl.Color(1,1,1,1)
				end
			elseif SYNCED.factory[ud] then
				local x,y,z = Spring.GetUnitPosition(u)
				gl.Color(.5,1,.5,1)
				gl.DrawGroundCircle(x,y,z,SYNCED.factory[ud].range, 100)
				gl.Color(1,1,1,1)
			end
		end
	end
end

function gadget:DrawScreen(vsx, vsy)
	local parts = SYNCED.teamParts[Spring.GetLocalTeamID()]
	gl.Text("Parts: "..parts.." / "..partCapacity, vsx/2 - 10, vsy - 30, 14, "ro")
	gl.Color(.1,.1,.1,1)
	gl.Rect(vsx/2, vsy-30, vsx-20, vsy-12)
	gl.Color(.8,0,0,1)
	gl.Rect(vsx-22-(vsx/2 -24)*parts/partCapacity, vsy-28, vsx-22, vsy-14)
	gl.Color(1,1,1,1)
end

end
