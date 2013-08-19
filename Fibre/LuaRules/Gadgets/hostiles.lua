function gadget:GetInfo()
	return {
		name = "Hostiles",
		desc = "enables 'hostile' faction",
		author = "KDR_11k (David Becker)",
		date = "2008-02-23",
		license = "None",
		layer = 15,
		enabled = true
	}
end

local hostileIndicator=UnitDefNames.hostile_main.id
local node=UnitDefNames.node.id
local citadel=UnitDefNames.citadel.id
local spawnDist = 600
local spawnrate = tonumber(Spring.GetModOptions().creeprate) or 1.0

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local hostileTeam = {}
local spawnRect={Game.mapSizeX,Game.mapSizeZ,0,0}
local sides = {1,2,3,4}
local numSides = 4
local destroyHostiles=false
local parent
local citadels
local spawns = {
	unit_light = {delay = 3, squad = 2, squadgrowth = 1},
	unit_armor = {delay = 15, squad = 2, squadgrowth = .35},
	unit_gunship = {delay = 20, squad = 1, squadgrowth = .2},
	hostile_bomber = {delay = 40, squad = 0, squadgrowth = .16},
	hostile_artillery = {delay = 50, squad = 1, squadgrowth = .2},
}
local initialDelays = {
	unit_light = 30,
	unit_armor = 180,
	unit_gunship = 280,
	hostile_bomber = 500,
	hostile_artillery = 340,
}

function gadget:Initialize()
	parent = GG.parent
	citadels=GG.citadelList
	_G.spawnRect = spawnRect
end

function gadget:UnitCreated(u, ud, team)
	if ud == hostileIndicator then
		--Spring.Echo("Hostile!")
		local i = {}
		for a,b in pairs(initialDelays) do
			i[a]=Spring.GetGameFrame() + 32*b
		end
		hostileTeam[team]={
			root=u,
			delays=i,
		}
		parent[u]=u --hacky way of declaring something as parentless but meh
	elseif ud == node or ud == citadel then
		local x,_,z=Spring.GetUnitPosition(u)
		if x - spawnDist < spawnRect[1] then
			spawnRect[1] = math.max(x - spawnDist,0)
			if spawnRect[1]<=1 then
				sides[1]=nil
			end
		end
		if x + spawnDist > spawnRect[3] then
			spawnRect[3] = math.min(x + spawnDist,Game.mapSizeX)
			if spawnRect[3]>=Game.mapSizeX -1 then
				sides[3]=nil
			end
		end
		if z - spawnDist < spawnRect[2] then
			spawnRect[2] = math.max(z - spawnDist,0)
			if spawnRect[2]<=1 then
				sides[2]=nil
			end
		end
		if z + spawnDist > spawnRect[4] then
			spawnRect[4] = math.min(z + spawnDist,Game.mapSizeZ)
			if spawnRect[4]>=Game.mapSizeZ -1 then
				sides[4]=nil
			end
		end
		if #sides == 0 then
			destroyHostiles=true
		end
	elseif hostileTeam[team] then
		parent[u] = hostileTeam[team].root
	end
end

local function RandomCitadel()
	local n
	if #citadels > 1 then
		n = math.random(1,#citadels)
	else
		n = 1
	end
	for _,u in pairs(citadels) do
		if n == 1 then
			return u
		else
			n=n-1
		end
	end
	return Spring.GetAllUnits()[1] --fallback if none exist
end

local function GetSide()
	if numSides > 0 then
		if numSides > 1 then
			n = math.random(1,numSides)
		else
			n = 1
		end
		for _,u in pairs(sides) do
			if n == 1 then
				return u
			else
				n=n-1
			end
		end
	end
	return 128
end

function gadget:GameFrame(f)
	if destroyHostiles then
		for t,d in pairs(hostileTeam) do
			Spring.DestroyUnit(d.root,false, true)
			hostileTeam[t]=nil
		end
		destroyHostiles=nil
	end
	if (f - 11) % 16 < .1 then
		numSides=0
		for _,u in pairs(sides) do
			numSides = numSides + 1
		end
		for t,d in pairs(hostileTeam) do
			--Spring.Echo("Frame: "..f)
			for un,delay in pairs(d.delays) do
				--Spring.Echo(un..": "..delay)
				if delay <= f then
					local side = GetSide()
					local tx,ty,tz = Spring.GetUnitPosition(RandomCitadel())
					for i = 1,(spawns[un].squad + spawns[un].squadgrowth * Spring.GetGameFrame() * 0.00056) do
						local position = math.random(0,10000)*.0001
						local x,z = 0
						if side == 2 then
							x=spawnRect[1]+position*(spawnRect[3]-spawnRect[1])
							z=spawnRect[2]
						elseif side == 1 then
							x=spawnRect[1]
							z=spawnRect[2]+position*(spawnRect[4]-spawnRect[2])
						elseif side == 4 then
							x=spawnRect[1]+position*(spawnRect[3]-spawnRect[1])
							z=spawnRect[4]
						elseif side == 3 then
							x=spawnRect[3]
							z=spawnRect[2]+position*(spawnRect[4]-spawnRect[2])
						else
							break
						end
						local nu = Spring.CreateUnit(un,x,0,z,0,t)
						if tx then
							Spring.GiveOrderToUnit(nu,CMD.FIGHT,{tx,ty,tz},{})
						end
						parent[nu]=nu
					end
					d.delays[un]=f + spawns[un].delay * 32 * spawnrate
				end
			end
		end
	end
end

else

--UNSYNCED

return false

--debug only
--function gadget:DrawWorld()
--	gl.Color(1,1,1,.1)
--	gl.DrawGroundQuad(SYNCED.spawnRect[1],SYNCED.spawnRect[2],SYNCED.spawnRect[3],SYNCED.spawnRect[4])
--	gl.Color(1,1,1,1)
--end

end
