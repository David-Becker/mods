function gadget:GetInfo()
	return {
		name = "Arty rules",
		desc = "handles arty",
		author = "KDR_11k (David Becker)",
		date = "2008-09-15",
		license = "Public Domain",
		layer = 15,
		enabled = true
	}
end

local GetGameFrame=Spring.GetGameFrame

if (gadgetHandler:IsSyncedCode()) then

--SYNCED
local lastShotPosition={}
local arty=UnitDefNames.turretred.id

local GetUnitBasePosition=Spring.GetUnitBasePosition
local GiveOrderToUnit=Spring.GiveOrderToUnit

local function ArtyFire(u, ud, team)
	local cmd=Spring.GetUnitCommands(u)[1]
	local x,y,z
	if cmd then
		if cmd.params[3] then
			if not lastShotPosition[u] or cmd.params[1] ~= lastShotPosition[u][1] or cmd.params[3] ~= lastShotPosition[u][2] or GetGameFrame() > lastShotPosition[u][3]+120 then
				lastShotPosition[u]={cmd.params[1],cmd.params[3], GetGameFrame()}
				SendToUnsynced("arty",cmd.params[1],cmd.params[2],cmd.params[3])
			end
			lastShotPosition[u][3]=GetGameFrame()
		else --this should never happen
			Spring.Echo("ARTY FIRED AT UNIT!")
			local x,y,z = Spring.GetUnitPosition(cmd.params[1])
			SendToUnsynced("arty",x,y,z)
		end
	end
end

local attackList={}

function gadget:AllowCommand(u, ud, team, cmd, param, opt)
	if cmd==CMD.ATTACK and ud == arty and not param[3] then
		local x,y,z=GetUnitBasePosition(param[1])
		attackList[u]={x,y,z,opt}
		return false
	end
	return true
end

function gadget:AllowDirectUnitControl(u, ud, team)
	if ud==arty then
		return false
	end
	return true
end

function gadget:GameFrame(f)
	for u,d in pairs(attackList) do
		if d[4].shift then
			GiveOrderToUnit(u,CMD.INSERT, {-1,CMD.ATTACK,0,d[1],d[2],d[3]},{"alt"})
		else
			GiveOrderToUnit(u,CMD.ATTACK,{d[1],d[2],d[3]},d[4])
		end
		attackList[u]=nil
	end
end

function gadget:Initialize()
	gadgetHandler:RegisterGlobal("ArtyFire",ArtyFire)
end

else

--UNSYNCED

local warningList={}
local GetPositionLosState=Spring.GetPositionLosState
local GetSpectatingState=Spring.GetSpectatingState
local Texture=gl.Texture
local Blending=gl.Blending
local AlphaTest=gl.AlphaTest
local GEQUAL=GL.GEQUAL
local Translate=gl.Translate
local Scale=gl.Scale
local Color=gl.Color
local Rotate=gl.Rotate
local PushMatrix=gl.PushMatrix
local PopMatrix=gl.PopMatrix
local CallList=gl.CallList
local LoadIdentity=gl.LoadIdentity
local insert=table.insert
local min=math.min
local GetLocalAllyTeamID=Spring.GetLocalAllyTeamID
local IsPosInLos=Spring.IsPosInLos


local drawList=nil

function gadget:RecvFromSynced(name,x,y,z)
	if name == "arty" then
		local _,spec = GetSpectatingState()
		local los = IsPosInLos(x,y,z,GetLocalAllyTeamID())
		if spec or los then
			insert(warningList,{x,y,z,GetGameFrame()})
		end
	end
end

function gadget:DrawWorld()
	local f=GetGameFrame()
	Texture("bitmaps/targetmarker.tga")
	AlphaTest(GEQUAL,.1)
	--gl.Blending(false)
	for i,d in pairs(warningList) do
		local t = (f - d[4])/50
		Color(1,1,1,1 - ((1-t)*(1-t))*.9)
		t=min(1,t)
		PushMatrix()
		Translate(d[1],d[2],d[3])
		Rotate((((1-t)*(1-t)))*120,0,1,0)
		local factor=(((1-t)*(1-t)))*300 + 100
		Scale(factor,1,factor)
		CallList(drawList)
		PopMatrix()
		if f - d[4] > 100 then
			warningList[i]=nil
		end
	end
	Color(1,1,1,1)
	--gl.Blending(true)
	Texture(false)
	AlphaTest(false)
end

function gadget:DrawInMiniMap(mmsx, mmsy)
	PushMatrix()
	LoadIdentity()
	Translate(0,1,0)
	Scale(1/Game.mapSizeX, 1/Game.mapSizeZ, 1)
	Rotate(90,1,0,0)
	gadget:DrawWorld()
	PopMatrix()
end

local function mesh()
	gl.TexCoord(0,0)
	gl.Vertex(1,0,1)
	gl.TexCoord(0,1)
	gl.Vertex(1,0,-1)
	gl.TexCoord(1,0)
	gl.Vertex(-1,0,1)
	gl.TexCoord(1,1)
	gl.Vertex(-1,0,-1)
end

function gadget:Initialize()
	drawList=gl.CreateList(gl.BeginEnd,GL.TRIANGLE_STRIP,mesh)
end

end
