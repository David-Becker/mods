function gadget:GetInfo()
	return {
		name = "Wave",
		desc = "implements the Wave Spawner",
		author = "KDR_11k (David Becker)",
		date = "2008-02-10",
		license = "Public Domain",
		layer = 10,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE, CMD_EJECT, CMD_WAVE, CMD_WAVELEVEL = VFS.Include("LuaRules/Header/header.lua", nil, VFS.MOD)
local master=UnitDefNames.master.id
local black=UnitDefNames.black.id
local tankblack=UnitDefNames.tankblack.id

local minWaveLevel=tonumber(Spring.GetModOptions().minwave) or 1


if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local waveTypes=VFS.Include("LuaRules/Header/waveTypes.lua", nil, VFS.MOD)

local waveStatus={}
local spawnList={}
local creepOwner=nil

local waveLevelList={}

local wlList={}

function gadget:UnitCreated(u, ud, team)
	if ud == master then
		for i,d in pairs(waveTypes) do
			Spring.InsertUnitCmdDesc(u, {
				name=d.name.." Wave",
				tooltip="Spawn a creep wave containing "..d.tooltip.."\nFight waves to gain more blobs",
				id = CMD_WAVE + i - 1,
				type = CMDTYPE.ICON,
			})
		end
		waveLevelList[1]=minWaveLevel
		Spring.InsertUnitCmdDesc(u, {
			name="Maximum Wave Level",
			tooltip="Vote on what you think the highest wave level\nshould be that your team can call",
			id=CMD_WAVELEVEL,
			type=CMDTYPE.ICON_MODE,
			params=waveLevelList,
		})
		wlList[team]=minWaveLevel
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param,opt)
	if cmd >= CMD_WAVE and cmd < CMD_WAVE + #waveTypes then
		if ud == master then
			return true
		else
			return false
		end
	end
	if cmd == CMD_WAVELEVEL then
		if param[1] and ud==master then
			GG.Debug("Team ",team," voted ",param[1]," on unit ",u)
			wlList[team]=math.max(param[1],minWaveLevel)
			local f = Spring.FindUnitCmdDesc(u,CMD_WAVELEVEL)
			waveLevelList[1]=math.max(param[1],minWaveLevel)
			Spring.EditUnitCmdDesc(u,f,{
				params=waveLevelList,
			})
		end
	end
	return true
end

function gadget:CommandFallback(u, ud, team, cmd, param, opt)
	if cmd >= CMD_WAVE and cmd < CMD_WAVE + #waveTypes then
		if not waveStatus[team] then
			local _,_,_,_,_,at=Spring.GetTeamInfo(team)
			local wls={}
			local num=.5
			for _,t in ipairs(Spring.GetTeamList(at)) do
				if t ~= team and wlList[t] then
					--Spring.Echo(t.." voted "..wlList[t])
					wls[wlList[t]]=(wls[wlList[t]] or 0 )+1
					num = num +.5
				end
			end
			for i=1,#waveTypes do
				if wls[i] then
					local c = wls[i]
					--Spring.Echo(i,c, num)
					num = num - c
					if num <=0 and cmd - CMD_WAVE +1 > i then
						cmd = i + CMD_WAVE
						Spring.SendMessageToTeam(team, "Your teammates have voted to allow nothing larger than a ".. waveTypes[i+1].name .." wave. Wave replaced.")
						break
					end
				end
			end
			local type = waveTypes[cmd - CMD_WAVE +1]
			local x,y,z=Spring.GetUnitPosition(u)
			waveStatus[team]={
				type=type,
				units={},
				count=math.huge,
				timeout=Spring.GetGameFrame()+120*30
			}
			spawnList[team]={
				wave=type,
				x=x,y=y,z=z,
			}
			Spring.CallCOBScript(u, "WaveFX", 0)
			return true, true
		else
			return true, false
		end
	end
	return false
end

local random=math.random
local sqrt=math.sqrt
local mapSizeX=Game.mapSizeX
local mapSizeZ=Game.mapSizeZ
local GetUnitsInCylinder=Spring.GetUnitsInCylinder
local GetUnitPosition=Spring.GetUnitPosition
local GetUnitTeam=Spring.GetUnitTeam
local GiveOrderToUnit=Spring.GiveOrderToUnit

function gadget:GameFrame(f)
	local gaia=Spring.GetGaiaTeamID()
	for team,d in pairs(spawnList) do
		local phi=math.random(6280)/1000
		local units={}
		local count=0
		local tries = 0
		local x=d.x+math.cos(phi)*1650
		local z=d.z+math.sin(phi)*1650
		if (d.x < 800 and x < d.x) or (mapSizeX - d.x < 800 and x > d.x) then
			x = d.x-(x - d.x)
		end
		if (d.z < 800 and z < d.z) or (mapSizeZ - d.z < 800 and z > d.z) then
			z = d.z-(z - d.z)
		end
		while tries < 30 do
			local avx=0
			local avz=0
			local cyl = GetUnitsInCylinder(x,z,800)
			local num = 0
			for _,unit in ipairs(cyl) do
				if GetUnitTeam(unit) ~= gaia then
					local tx,_,tz = GetUnitPosition(unit)
					avx = avx + tx
					avz = avz + tz
					num=num+1
				end
			end
			if num==0 then
				break
			end
			avx=avx / #cyl
			avz=avz / #cyl
			local dist=sqrt((avx-x)*(avx-x) + (avz-z)*(avz-z))
			x=x+random(200)-100 + (900-dist)*(x-avx)/dist
			z=z+random(200)-100 + (900-dist)*(z-avz)/dist
			if (d.x < 800 and x < d.x) or (mapSizeX - d.x < 800 and x > d.x) then
				x = d.x-(x - d.x)
			end
			if (d.z < 800 and z < d.z) or (mapSizeZ - d.z < 800 and z > d.z) then
				z = d.z-(z - d.z)
			end
			tries=tries +1
		end
		GG.Debug("Used "..tries.." attempts")
		for ud, num in pairs(d.wave.content) do
			local name=UnitDefs[ud].name
			for i=1,num do
				local ux= x - 150 + random(300)
				local uz= z - 150 + random(300)
				ux=math.max(random(1000)/3,math.min(ux,mapSizeX-random(1000)/3))
				uz=math.max(random(1000)/3,math.min(uz,mapSizeZ-random(1000)/3))
				local nu=GG.NewUnit(name, ux, d.y, uz, 0, gaia)
				GiveOrderToUnit(nu,CMD.FIGHT,{d.x,d.y,d.z},{})
				count=count + 1
				units[nu]=true
				creepOwner[nu]=team
				if higherUnits[ud] then
					GG.AddBlobs(nu,ud,1,d.wave.bc)
				end
			end
		end
		waveStatus[team].count=count
		waveStatus[team].units=units
		spawnList[team]=nil
	end
	if f%150 < .1 then
		for i,d in pairs(waveStatus) do
			if d.timeout < f then
				for u,_ in pairs(d.units) do
					Spring.DestroyUnit(u)
				end
			end
		end
	end
end

function gadget:UnitDestroyed(u, ud, team)
	if creepOwner[u] and waveStatus[creepOwner[u]] then
		local ws = waveStatus[creepOwner[u]]
		ws.count=ws.count -1
		ws.units[u]=nil
		if ws.count<=0 then
			waveStatus[creepOwner[u]]=nil
		end
	end
	if ud == master and Spring.GetTeamUnitDefCount(team, master) then
		wlList[team]=nil
	end
end

function gadget:UnitTaken(u, ud, team, newteam)
	if ud == master and Spring.GetTeamUnitDefCount(team, master) then
		wlList[team]=nil
	end
end

function gadget:Initialize()
	creepOwner=GG.creepOwner
	for i,w in pairs(waveTypes) do
		waveLevelList[i+1]="Vote "..w.name
	end
end

else

--UNSYNCED

return false

end
