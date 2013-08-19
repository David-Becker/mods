function gadget:GetInfo()
	return {
		name = "Form Commander",
		desc = "Allows morphing a higher unit into a commander unit",
		author = "KDR_11k (David Becker)",
		date = "2008-09-17",
		license = "Public Domain",
		layer = 10,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE, CMD_EJECT, CMD_WAVE, CMD_WAVELEVEL, CMD_FORM = VFS.Include("LuaRules/Header/header.lua", nil, VFS.MOD)
local master=UnitDefNames.master.id
local black=UnitDefNames.black.id
local tankblack=UnitDefNames.tankblack.id

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local teamCost={}
local morphList={}
local morphing={}

local GetUnitCOBValue=Spring.GetUnitCOBValue
local SetUnitCOBValue=Spring.SetUnitCOBValue
local GetTeamUnits=Spring.GetTeamUnits
local FindUnitCmdDesc=Spring.FindUnitCmdDesc
local EditUnitCmdDesc=Spring.EditUnitCmdDesc
local GetUnitDefID=Spring.GetUnitDefID

local function UpdateMorph(team)
	for _,u in ipairs(Spring.GetTeamUnits(team)) do
		local ud=GetUnitDefID(u)
		if higherUnits[ud] then
			local f=FindUnitCmdDesc(u,CMD_FORM)
			if f then
				EditUnitCmdDesc(u,f,{tooltip="Morph this unit into a Master Converter if you don't have one\nuses "..(teamCost[team] or 30).." blobs",})
			end
		end
	end
end

function gadget:UnitCreated(u, ud, team)
	if higherUnits[ud] and ud ~=master then
		Spring.InsertUnitCmdDesc(u,{
			name="Master Converter",
			tooltip="Morph this unit into a Master Converter if you don't have one\nuses "..(teamCost[team] or 30).." blobs",
			id=CMD_FORM,
			type=CMDTYPE.ICON,
			action="formmaster",
			texture="unitpics/master.png",
		})
	end
end

function gadget:UnitDestroyed(u,ud,team)
	if morphing[u] then
		morphList[morphing[u]]=nil
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opt)
	if cmd == CMD_FORM then
		if higherUnits[ud] and ud~=master then
			return true
		else
			return false
		end
	end
	return true
end

function gadget:CommandFallback(u, ud, team, cmd, param, opt)
	if cmd == CMD_FORM then
		if Spring.GetTeamUnitDefCount(team,master)>0 then
			Spring.SendMessageToTeam(team,"Cannot morph if Master Converter is still in your possession")
			return true, true
		elseif morphList[team] then
			Spring.SendMessageToTeam(team,"Can only morph one unit at a time")
			return true, true
		end
		local bc1=GetUnitCOBValue(u, blobCount+1)
		local bc2=GetUnitCOBValue(u, blobCount+2)
		local cost=teamCost[team] or 30
		if bc1 >= cost then
			GG.AddBlobs(u, ud,1, -cost)
		elseif bc1 + bc2 >= cost then
			GG.AddBlobs(u, ud,1, -bc1)
			GG.AddBlobs(u, ud,2, -cost + bc1)
		else
			Spring.SendMessageToTeam(team,"You need at least "..cost.." blobs in this unit to morph it!")
			return true, true
		end
		teamCost[team] = cost + 20
		local x,y,z=Spring.GetUnitBasePosition(u)
		morphList[team]={
			u,ud,
			Spring.GetGameFrame(),
			x,Spring.GetGroundHeight(x,z),z
		}
		morphing[u]=team
		Spring.SetUnitHealth(u,{paralyze=999999999999})
		Spring.SetUnitNoDraw(u,true)
		Spring.MoveCtrl.Enable(u)
		Spring.MoveCtrl.SetVelocity(u,0,0,0)
		UpdateMorph(team)
		return true, true
	end
	return false
end

function gadget:GameFrame(f)
	for team,d in pairs(morphList) do
		if d[3]+90 == f then
			morphing[d[1]]=nil
			local x,y,z=Spring.GetUnitPosition(d[1])
			local nu=GG.NewUnit("master",x,y,z,0,team)
			local bc1=Spring.GetUnitCOBValue(d[1], blobCount+1)
			local bc2=Spring.GetUnitCOBValue(d[1], blobCount+2)
			Spring.SetUnitCOBValue(d[1],blobCount+1, 0)
			Spring.SetUnitCOBValue(d[1],blobCount+2, 0)
			GG.AddBlobs(nu,master,1, bc1+bc2)
			Spring.DestroyUnit(d[1],false,true)
		elseif d[3]+130 <=f then
			morphList[team]=nil
		end
	end
end

function gadget:Initialize()
	_G.morphList=morphList
end

else

--UNSYNCED

local tubeList=nil
local morphList=nil

local function tube()
	for i=0,31 do
		local phi=i/32*6.284
		gl.Vertex(math.cos(phi),0,math.sin(phi))
		gl.Vertex(math.cos(phi),1,math.sin(phi))
	end
	gl.Vertex(1,0,0)
	gl.Vertex(1,1,0)
end

local Unit=gl.Unit
local PushMatrix=gl.PushMatrix
local Translate=gl.Translate
local Scale=gl.Scale
local CallList=gl.CallList
local PopMatrix=gl.PopMatrix
local GetLocalAllyTeamID=Spring.GetLocalAllyTeamID
local GetPositionLosState=Spring.GetPositionLosState

function gadget:DrawWorld()
	gl.DepthTest(GL.LEQUAL)
	gl.Texture(false)
	local f = Spring.GetGameFrame()
	local _,spec = Spring.GetSpectatingState()
	local ally=GetLocalAllyTeamID()
	local lt=Spring.GetLocalTeamID()
	for team,d in spairs(morphList) do
		local los=GetPositionLosState(d[3],d[4],d[5],ally)
		if los or spec or team==lt then
			if d[3]+90 > f then
				Unit(d[1],true)
				PushMatrix()
				Translate(d[4],d[5],d[6])
				local t = (f - d[3])/90
				Scale(t*30,9000,t*30)
				CallList(tubeList)
				PopMatrix()
			else
				PushMatrix()
				Translate(d[4],d[5],d[6])
				local t = (f - d[3] - 90)/40
				Scale(30,1000*((1-t)*(1-t)),30)
				CallList(tubeList)
				PopMatrix()
			end
		end
	end
	gl.DepthTest(false)
end

function gadget:Initialize()
	tubeList=gl.CreateList(gl.BeginEnd,GL.TRIANGLE_STRIP,tube)
	morphList=SYNCED.morphList
end

end
