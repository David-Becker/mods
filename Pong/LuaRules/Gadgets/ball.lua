function gadget:GetInfo()
	return {
		name = "ball",
		desc = "Ball physics",
		author = "KDR_11k (David Becker)",
		date = "2008-02-10",
		license = "Public Domain",
		layer = 5,
		enabled = true
	}
end

local ballDef=UnitDefNames.ball.id
local groundHeight = 30
local gravity=3
local vSpeed=20
local paddleRadius=170
local paddleStrength=.14

local boundaryN=128
local boundaryS=2048-128
local boundaryW=256
local boundaryE=2048-256

local bouncywalls= Spring.GetModOptions().bouncywalls =="1"


if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local ballspeeds={0,0,0}
local ball

local paddleSide

function gadget:UnitCreated(u, ud, team)
	if ud==ballDef then
		ball=u
		ballspeeds={0,0,0}
	end
end

function gadget:UnitDestroyed(u, ud, team)
	if ud==ballDef then
		ball=nil
	end
end

function gadget:GameFrame(f)
	if ball then
		local x,y,z = Spring.GetUnitPosition(ball)
		for u,s in pairs(paddleSide) do
			local px,py,pz = Spring.GetUnitPosition(u)
			local dist = math.sqrt((x-px)*(x-px) + (y-py)*(y-py) + (z-pz)*(z-pz))
			if dist < paddleRadius then
				Spring.MoveCtrl.SetVelocity(ball,(x-px)*paddleStrength, vSpeed, (z-pz)*paddleStrength)
				GG.SetLastShot(s)
			end
		end
		if bouncywalls then
			local vx,vy,vz = Spring.GetUnitVelocity(ball)
			local change=false
			if x > boundaryE and vx > 0 then
				vx = -vx
				change=true
			elseif x < boundaryW and vx < 0 then
				vx = -vx
				change=true
			end
			if z > boundaryS and vz > 0 then
				vz = -vz
				change=true
			elseif z < boundaryN and vz < 0 then
				vz = -vz
				change=true
			end
			if change then
				Spring.MoveCtrl.SetVelocity(ball, vx,vy,vz)
			end
		end
        Spring.MoveCtrl.SetGravity(ball,gravity)
	end
end

function gadget:Initialize()
	paddleSide=GG.paddleSide
end

else

--UNSYNCED

local function ballLine(u)
	gl.Color(1,0,0,1)
	local x,y,z=Spring.GetUnitPosition(u)
	gl.Vertex(x,y,z)
	gl.Vertex(x,groundHeight,z)
	gl.Vertex(x-30,groundHeight,z-30)
	gl.Vertex(x+30,groundHeight,z+30)
	gl.Vertex(x+30,groundHeight,z-30)
	gl.Vertex(x-30,groundHeight,z+30)
	gl.Color(1,1,1,1)
end

function gadget:DrawWorldPreUnit()
	if SYNCED.ball then
		gl.BeginEnd(GL.LINES,ballLine,SYNCED.ball)
	end
end

end
