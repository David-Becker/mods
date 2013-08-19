function gadget:GetInfo()
	return {
		name = "Game",
		desc = "PONG!",
		author = "KDR_11k (David Becker)",
		date = "2008-08-15",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

local ballDef = UnitDefNames.ball.id
local paddle = UnitDefNames.paddle.id
local boundaryN=128
local boundaryS=2048-128
local boundaryW=256
local boundaryE=2048-256
local fieldDist=256
local center=1024
local bouncycenter= Spring.GetModOptions().bouncycenter == "1"

local serveX=1024
local serveDist=512

local groundHeight = 20

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local score={0,0}
local nextServeTime=120
local nextServeSide=1
local lastShot

local paddleSide={}
local ball
local scoreLimit=tonumber(Spring.GetModOptions().pointlimit) or 5
local winSide
local stopList={}

local function Score(scorer, message)
	if scorer then
		score[scorer] = score[scorer] + 1
	end

	if scorer and score[scorer] >= scoreLimit then
		winSide=scorer
		local teams={"North","South"}
		SendToUnsynced(teams[scorer] .." Team WON!",1200)
	else
		SendToUnsynced(message,120)

		if scorer == 1 then
			nextServeSide=2
		elseif scorer == 2 then
			nextServeSide=1
		end
		nextServeTime=Spring.GetGameFrame()+150
		lastShot=nil
	end
end

function gadget:UnitCreated(u, ud, team)
	if ud == paddle then
		local side
		local x,y,z=Spring.GetUnitPosition(u)
		if x < boundaryW then
			x=boundaryW+10
		end
		if x > boundaryE then
			x=boundaryE-10
		end
		if z < boundaryN then
			z=boundaryN+10
		end
		if z > boundaryS then
			z=boundaryS-10
		end
		if z < center then
			side=1
			if z > center - fieldDist then
				z=center - fieldDist - 10
			end
		else
			side=2
			if z < center + fieldDist then
				z=center + fieldDist + 10
			end
		end
		paddleSide[u]=side
		Spring.SetUnitPosition(u,x,groundHeight,z)
		--stopList[u]=true
	elseif ud == ballDef then
		ball=u
		_G.ball=u
	end
end

function gadget:AllowCommand(u,ud,team,cmd,param,opt)
	if cmd==CMD.MOVE and ud==paddle then
		if param[1] > boundaryW and param[1] < boundaryE and param[3] > boundaryN and param[3] < boundaryS then
			if paddleSide[u]==1 then
				if param[3] < center - fieldDist then
					return true
				end
			elseif paddleSide[u]==2 then
				if param[3] > center + fieldDist then
					return true
				end
			end
		end
	elseif cmd==CMD.STOP then
		return true
	end
	return false
end

function gadget:UnitDestroyed(u, ud, team)
	if ud == ballDef then
		local x,y,z=Spring.GetUnitPosition(u)

		if x < boundaryW or x > boundaryE or z < boundaryN or z > boundaryS or (z > center - fieldDist and z < center + fieldDist) then
			--OUT!

			local scorer
			if lastShot == 1 then
				scorer = 2
			elseif lastShot == 2 then
				scorer = 1
			end

			Score(scorer, "OUT!!")
		else
			--must be in the field since it's not OUT
			if lastShot then --no points for failed serves!
				if z < center then
					Score(2,"South Team scored!")
				else
					Score(1,"North Team scored!")
				end
			else
				Score(nil, "KEEP TRY!")
			end
		end
		ball=nil
		_G.ball=nil
	end
end

function gadget:GameFrame(f)
	if ball then
		local x,y,z=Spring.GetUnitPosition(ball)
		--Spring.Echo(ball, y)
		if y and y < groundHeight then
			if bouncycenter then
				if z > center - fieldDist and z < center + fieldDist and x > boundaryW and x < boundaryE then
					local vx,vy,vz = Spring.GetUnitVelocity(ball)
					Spring.MoveCtrl.SetVelocity(ball,vx,-vy,vz)
					Spring.MoveCtrl.SetPosition(ball,x,groundHeight,z)
				else
					Spring.DestroyUnit(ball)
				end
			else
				Spring.DestroyUnit(ball)
			end
		end
	end
	if winSide then
		for u,s in pairs(paddleSide) do
			if s ~= winSide then
				Spring.DestroyUnit(u)
			end
		end
	end
	if f==nextServeTime then
		local servePos
		if nextServeSide==1 then
			servePos=center - serveDist
		else
			servePos=center + serveDist
		end
		local nu=Spring.CreateUnit("ball",0,0,0,0,Spring.GetGaiaTeamID())
		Spring.MoveCtrl.Enable(nu)
		Spring.MoveCtrl.SetPosition(nu,serveX,500,servePos)
        Spring.MoveCtrl.SetVelocity(nu,0,-1,0)
        Spring.MoveCtrl.SetRotationVelocity(nu,0,0,0)
	end
	
	for u,_ in pairs(stopList) do
		Spring.GiveOrderToUnit(u, CMD.STOP, {},{})
		stopList[u]=nil
	end
end

function gadget:UnitDamaged(u, ud, team, damage, para, weapon, attacker, au, ateam)
	if attacker and paddleSide[attacker] then
		lastShot=paddleSide[attacker]
	end
end

local function SetLastShot(side)
	lastShot=side
end

function gadget:Initialize()
	_G.score=score
	GG.paddleSide=paddleSide
	GG.SetLastShot = SetLastShot
end

else

--UNSYNCED

local message="Start!"
local messageTTL=120

function gadget:DrawScreen(vsx,vsy)
	gl.Text(SYNCED.score[1].." - "..SYNCED.score[2],vsx*.5,vsy-80,16,"oc")
	if messageTTL > Spring.GetGameFrame() then
		gl.Text(message,vsx*.5,vsy*.5 + 40,24,"oc")
		gl.Text(SYNCED.score[1].." - "..SYNCED.score[2],vsx*.5,vsy*.5 - 100,60,"oc")
	end
end

function gadget:RecvFromSynced(messageContent,timeout)
	message=messageContent
	messageTTL=Spring.GetGameFrame()+timeout
end

local function outline()
	gl.Vertex(boundaryW,groundHeight,boundaryN)
	gl.Vertex(boundaryW,groundHeight,boundaryS)
	gl.Vertex(boundaryE,groundHeight,boundaryS)
	gl.Vertex(boundaryE,groundHeight,boundaryN)
	gl.Vertex(boundaryW,groundHeight,boundaryN)
end

local function inline()
	gl.Vertex(boundaryE,groundHeight,center - fieldDist)
	gl.Vertex(boundaryW,groundHeight,center - fieldDist)
	gl.Vertex(boundaryE,groundHeight,center + fieldDist)
	gl.Vertex(boundaryW,groundHeight,center + fieldDist)
end


function gadget:DrawWorldPreUnit()
	gl.BeginEnd(GL.LINE_STRIP,outline)
	gl.BeginEnd(GL.LINES,inline)
end

end
