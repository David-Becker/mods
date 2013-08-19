function gadget:GetInfo()
	return {
		name = "reinforcements",
		desc = "reinforcements for the simple mod",
		author = "KDR_11k (David Becker)",
		date = "2009-03-05",
		license = "Public Domain",
		layer = 20,
		enabled = true
	}
end

local maxCharge=120
local startCharge=90
local pointCharge=.2

local grunt=UnitDefNames.grunt.id
local jumper=UnitDefNames.jumper.id
local armor=UnitDefNames.armor.id
local killbot=UnitDefNames.killbot.id
local recruit=UnitDefNames.recruit.id
local burner=UnitDefNames.burner.id
local grenadier=UnitDefNames.grenadier.id

local base = UnitDefNames.base.id
local sepcore = UnitDefNames.sepcore.id
local controller = UnitDefNames.controller.id
local point = UnitDefNames.point.id

local CMD_RALLY=30002

local bases= {
	[base]=1.0,
	[sepcore]=.2,
	[controller]=90,
}

local unitCounts= {
	[base]={
		[grunt]=4,
		[jumper]=3,
		[armor]=3,
	},
	[sepcore]={
		[recruit]=7,
		[burner]=2,
		[grenadier]=3,
	},
	[controller]={
		[killbot]=1,
	},
}

local squadSize= {
	[grunt]=3,
	[jumper]=2,
	[armor]=0,
	[recruit]=8,
	[burner]=4,
	[grenadier]=1,
	[killbot]=24,
}


if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local refTimers={}
local squads
local rallyPoints={}

local rallyCmd={
	name="Rallypoint",
	tooltip="Define the location where new squads will move after being built",
	action="move",
	id=CMD_RALLY,
	type=CMDTYPE.ICON_MAP,
	cursor="Move",
}

function gadget:UnitCreated(u, ud, team)
	if bases[ud] then
		refTimers[u]=startCharge
		local x,y,z=Spring.GetUnitBasePosition(u)
		rallyPoints[u]={x,y,z+200}
		if ud ~=controller then
			Spring.InsertUnitCmdDesc(u,rallyCmd)
		end
	end
end

function gadget:UnitDestroyed(u,ud,team)
	if bases[ud] then
		refTimers[u]=nil
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opt)
	if cmd == CMD_RALLY then
		if rallyPoints[u] and param[3] then
			rallyPoints[u] = param
		end
		return false
	end
	return true
end

local function Reinforce(team,from)
	local sx,sy,sz = Spring.GetUnitPiecePosDir(from,Spring.GetUnitPieceMap(from).spawner)
	local basetype=Spring.GetUnitDefID(from)
	--sz=sz+16
	local counts={}
	for ud,_ in pairs(unitCounts[basetype]) do
		counts[ud]=0
	end
	for u,d in pairs(squads) do
		if Spring.GetUnitTeam(u)==team then
			local ud = d.type
			if unitCounts[basetype][ud] then
				counts[ud]=(counts[ud] or 0)+1
				for i = 1,squadSize[ud] do
					if not d.followers[i] then
						local nu = Spring.CreateUnit(ud,sx+math.random(40)-20,sy,sz+math.random(40)-20,0,team)
						if nu then
							GG.AddSquadUnitAt(nu,i,u)
						end
					end
				end
			end
		end
	end
	for ud,c in pairs(counts) do
		if c < (unitCounts[basetype][ud] or 0) then
			c=c+1
			local nl = Spring.CreateUnit(ud,sx,sy,sz,0,team)
			if nl then
				local fol = {}
				for i = 1,squadSize[ud] do
					fol[i]=Spring.CreateUnit(ud,sx+math.random(40)-20,sy,sz+math.random(40)-20,0,team)
				end
				GG.RegisterSquad(ud,nl,fol)
				local phi = math.random()*6.284
				local dist = math.random(100)
				if basetype ~=controller then
					Spring.GiveOrderToUnit(nl,CMD.MOVE,{rallyPoints[from][1] + math.cos(phi)*dist,rallyPoints[from][2],rallyPoints[from][3] + math.sin(phi)*dist},{})
				end
			end
		end
	end
end

function gadget:GameFrame(f)
	if f==5 then
		for u,_ in pairs(refTimers) do
			local team = Spring.GetUnitTeam(u)
			Reinforce(team,u)
		end
	end
	if f%30 < .1 then
		for b,tm in pairs (refTimers) do
			local team = Spring.GetUnitTeam(b)
			local ud = Spring.GetUnitDefID(b)
			tm = tm + bases[ud] + pointCharge * Spring.GetTeamUnitDefCount(team,point)
			if tm >= maxCharge then
				refTimers[b]=0
				Reinforce(team,b)
			else
				refTimers[b]=tm
			end
		end
	end
end

function gadget.Initialize()
	squads=GG.squads
	_G.refTimers=refTimers
	_G.rallyPoints=rallyPoints
	GG.rallyPoints=rallyPoints
end

else
--UNSYNCED

local myBase=nil
local myPoints=0
local border = 3
local left, right, top, bottom = 0,0,0,0

function gadget:DrawScreen(vsx,vsy)
	if not Spring.IsGUIHidden() and myBase and SYNCED.refTimers[myBase] then
		left = vsx*.5
		right = vsx*.95
		top = vsy-15
		bottom = top - 20
		gl.Color(.2,.2,.2,1)
		gl.Rect(left - border, top + border, right + border, bottom - border)
		gl.Color(.2,.5,.2,1)
		gl.Rect(left, top, left + (SYNCED.refTimers[myBase] / maxCharge)*(right - left), bottom)
		gl.Text("Reinforcement Timer:", left, top - 10, 16,"oc")
		gl.Text("Points held: "..myPoints.."/"..SYNCED.pointCountTotal, right,bottom-5,16,"or")
	end
end

function gadget:DrawWorldPreUnit()
	if myBase and SYNCED.rallyPoints[myBase] then
		gl.Texture("bitmaps/rally.tga")
		gl.Blending(GL.SRC_ALPHA,GL.ONE)
		local r = SYNCED.rallyPoints[myBase]
		gl.DrawGroundQuad(r[1]-32,r[3]-32,r[1]+32,r[3]+32,false,true)
		gl.Texture(false)
		gl.Blending(false)
	end
end

function gadget:IsAbove(x,y)
	if myBase and x > left and x < right and y > bottom and y < top then
		return true
	end
	return false
end

function gadget:GetTooltip()
	if myBase then
		local team = Spring.GetLocalTeamID()
		return "Reinforcement Timer: "..math.floor((SYNCED.refTimers[myBase] / maxCharge)*100).."%\n"..
			"When this reaches 100% you receive reinforcements.\n"..
			"Any squad will be refilled to full size and new squads are spawned.\n"..
			"Take points to increase the charge rate."
	end
end

function gadget:Update()
	local team = Spring.GetLocalTeamID()
	myBase=Spring.GetTeamUnitsByDefs(team,base)[1] or Spring.GetTeamUnitsByDefs(team,sepcore)[1]
	myPoints=Spring.GetTeamUnitDefCount(team,point)
end

end
