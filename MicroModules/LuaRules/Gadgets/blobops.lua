function gadget:GetInfo()
	return {
		name = "Blob Operations",
		desc = "Global functions for interacting with Blobs",
		author = "KDR_11k (David Becker)",
		date = "2008-09-13",
		license = "Public Domain",
		layer = 2,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE = VFS.Include("LuaRules/Header/header.lua", nil, VFS.MOD)


local SetUnitMaxHealth=Spring.SetUnitMaxHealth
local SetUnitHealth=Spring.SetUnitHealth
local SetUnitNoDraw=Spring.SetUnitNoDraw
local GetUnitHealth = Spring.GetUnitHealth
local GetUnitPosition=Spring.GetUnitPosition
local GetUnitTeam=Spring.GetUnitTeam
local GetUnitDefID=Spring.GetUnitDefID
local SetUnitCOBValue=Spring.SetUnitCOBValue
local GetUnitCOBValue=Spring.GetUnitCOBValue
local GetUnitHeading=Spring.GetUnitHeading
local CallCOBScript=Spring.CallCOBScript
local GetGameFrame=Spring.GetGameFrame
local sqrt=math.sqrt
local random=math.random
local Debug=nil
local min=math.min
local max=math.max
local CreateUnit=Spring.CreateUnit

local jumpTime=8

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local blobList={
	"red","green","blue","black"
}

local creepOwner={}


local createList={}

local function AddBlobs(u, ud, blobType, count)
	local bc= GetUnitCOBValue(u, blobCount + blobType) + count
	if bc < 0 then
		count = count - bc
		bc=0
	end
	SetUnitCOBValue(u, blobCount + blobType, bc)
	CallCOBScript(u, "ChangedBlobCount", 0, blobType, min(bc,GG.maxBlob), sqrt(min(bc,GG.maxBlob)))
	if blobType==1 then --chassis type
		local hpBonus=higherUnits[ud].hpBonus
		local health, maxHealth=GetUnitHealth(u)
		local dif = min(bc,GG.maxBlob) - min(bc-count,GG.maxBlob)
		SetUnitMaxHealth(u, maxHealth + hpBonus*dif)
		SetUnitHealth(u, {health=health * (maxHealth + hpBonus*dif) / maxHealth})
	end
	return count
end

local function EjectBlobs(u, ud, blobType, count, stun, color, moveTo)
	local hu=higherUnits[ud]
	local team=Spring.GetUnitTeam(u)
	if hu.contInv[blobType] then
		local type= hu.contInv[blobType]
		if type=="ANY" then
			if color then
				type = color
			else
				type = blobList[random(3)] --Don't want any blacks
			end
		end
		local num = -AddBlobs(u, ud, blobType, -count)
		local x,y,z=GetUnitPosition(u)
		for i = 1,num do
			local phi = random(628)/100
			local amp = 50 + random(40)
			table.insert(createList, {
				type,
				x + math.cos(phi)*amp,y,z + math.sin(phi)*amp,
				team, u, stun,
				x,z, moveTo, count
			})
		end
	end
end

local mergeJumps={}
local ejectJumps={}

local function EjectJump(u, x, y, z, stun)
	local tx,ty,tz = GetUnitPosition(u)
	SetUnitNoDraw(u, true)
	ejectJumps[u]= {tx-x,ty-y,tz-z,
		GetGameFrame(),
		sqrt((tx-x)*(tx-x) + (tz-z)*(tz-z)),
		stun
	}
end

local function MergeJump(u,tu)
	local x,y,z = GetUnitPosition(u)
	local tx,ty,tz = GetUnitPosition(tu)
	SetUnitNoDraw(u, true)
	table.insert(mergeJumps, {
		GetUnitDefID(u),GetUnitTeam(u),
		x,y,z,
		tx-x,ty-y,tz-z,
		GetGameFrame(),GetUnitHeading(u)*(360/65536)
	})
end

local GetUnitsInCylinder=Spring.GetUnitsInCylinder
local min=math.min
local max=math.max
local mapSizeX=Game.mapSizeX
local mapSizeZ=Game.mapSizeZ

local function NewUnit(udname,x,y,z,heading,team)
	local tries=0
	x = max ( random(5000)/100, min (x, mapSizeX -random(5000)/100))
	z = max ( random(5000)/100, min (z, mapSizeZ -random(5000)/100))
	while (#GetUnitsInCylinder(x,z,0.001)) > 0 and tries < 256 do
		x = max ( random(5000)/100, min (x + (random(10000)-5000)*.001, mapSizeX -random(5000)/100))
		z = max ( random(5000)/100, min (z + (random(10000)-5000)*.001, mapSizeZ -random(5000)/100))
		tries=tries+1
	end
	if tries >0 then
		Debug("Had to retry "..tries.." times to place "..udname)
	end
	return CreateUnit(udname,x,y,z,heading,team)
end

function gadget:UnitDestroyed(u, ud, team)
	ejectJumps[u]=nil
	mergeJumps[u]=nil
end


function gadget:GameFrame(f)
	for i,d in pairs(createList) do
		local nu = NewUnit(d[1],d[2],d[3],d[4],0,d[5])
		if nu then
			SetUnitHealth(nu, {paralyze=GetUnitHealth(nu) *1.1})
			if d[7] then
				Spring.GiveOrderToUnit(nu, CMD_JOIN, {d[6]}, {})
			elseif d[10] then
				Spring.GiveOrderToUnit(nu, CMD_JOIN, {d[10]}, {})
			elseif d[11] == 1 then
				Spring.GiveOrderToUnit(nu, CMD.MOVE_STATE, {0}, {})
			end
			EjectJump(nu,d[8],d[3],d[9], d[7])
--		elseif d[6] then
--			AddBlobs(d[6],Spring.GetUnitDefID(d[6]), higherUnits[d[6]].content[UnitDefNames[d[1]].id],1)
		end
		createList[i]=nil
	end
	for u,j in pairs(ejectJumps) do
		if j[4]+jumpTime <= f then
			SetUnitNoDraw(u, false)
			if not j[6] then
				SetUnitHealth(u, {paralyze=0})
			end
			ejectJumps[u]=nil
		end
	end
	for u,j in pairs(mergeJumps) do
		if j[9]+jumpTime <= f then
			mergeJumps[u]=nil
		end
	end
end

function gadget:Initialize()
	GG.AddBlobs = AddBlobs
	GG.EjectBlobs=EjectBlobs
	GG.EjectJump=EjectJump
	GG.MergeJump=MergeJump
	GG.NewUnit=NewUnit
	Debug=GG.Debug
	_G.ejectJumps=ejectJumps
	_G.mergeJumps=mergeJumps
	local i=1
end

else

--UNSYNCED
local ejectJumps=nil
local mergeJumps=nil

local PushMatrix=gl.PushMatrix
local PopMatrix=gl.PopMatrix
local Translate=gl.Translate
local Rotate=gl.Rotate
local Unit=gl.Unit
local UnitShape=gl.UnitShape
local Lighting=gl.Lighting
local GetPositionLosState=Spring.GetPositionLosState
local IsPosInLos=Spring.IsPosInLos

function gadget:Initialize()
	ejectJumps=SYNCED.ejectJumps
	mergeJumps=SYNCED.mergeJumps
end

local GetLocalAllyTeamID=Spring.GetLocalAllyTeamID

function gadget:DrawWorld()
	local f = GetGameFrame()
	local _,spec=Spring.GetSpectatingState()
	local ally=GetLocalAllyTeamID()
	for u,d in spairs(ejectJumps) do
		local t = sqrt((f - d[4])/jumpTime)
		local x=- d[1]*(1-t)
		local y=- d[2]*(1-t)
		local z=- d[3]*(1-t)
		local ux,uy,uz=GetUnitPosition(u)
		local los = IsPosInLos(ux,uy,uz,ally)
		Spring.Echo(los,ally)
		if spec or los then
			PushMatrix()
			Translate(x,y,z)
			Unit(u)
			PopMatrix()
		end
	end
	for _,d in spairs(mergeJumps) do
		local t = sqrt((f - d[9])/jumpTime)
		local x=d[3] + d[6]*t
		local y=d[4] + d[7]*t
		local z=d[5] + d[8]*t
		local los = IsPosInLos(x,y,z,ally)
		if spec or los then
			PushMatrix()
			Translate(x,y,z)
			Rotate(d[10],0,1,0)
			UnitShape(d[1],d[2])
			PopMatrix()
		end
	end
end

end
