function gadget:GetInfo()
	return {
		name = "Autotrack",
		desc = "Tracks the given unit for each team",
		author = "KDR_11k (David Becker)",
		date = "20089-10-27",
		license = "Public Domain",
		layer = 1,
		enabled = false
	}
end

local fixedHeight=3000
local fixedAngle=30/180*3.1415

local fixedDY = math.sin(-fixedAngle)
local fixedDZ=math.cos(fixedAngle)

if (gadgetHandler:IsSyncedCode()) then

--SYNCED
--return false

--Test

function gadget:Initialize()
	_G.trackUnit={}
end

function gadget:UnitCreated(u,ud,team)
	_G.trackUnit[team]=u
end

else

--UNSYNCED

function gadget:Update()
	local team = Spring.GetLocalTeamID()
	local unit = SYNCED.trackUnit[team]
	if unit then
		local x,y,z = Spring.GetUnitPosition(unit)
		if x then
			local camState=Spring.GetCameraState()
			camState.px=x
			camState.py=y
			camState.pz=z
			camState.height=fixedHeight
			Spring.SetCameraState(camState,.1)
		end
	end
end

end
