function gadget:GetInfo()
	return {
		name = "Points",
		desc = "The points you have to capture",
		author = "KDR_11k (David Becker)",
		date = "2009-03-05",
		license = "Public Domain",
		layer = 5,
		enabled = true
	}
end

local CMD_TAKE = 30001

local takeDist=70 --Distance at which the unit will do the taking

local exempt = {
	[UnitDefNames.point.id]=true,
	[UnitDefNames.relic.id]=true,
}

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local cmdDesc={
	name="Capture Point",
	tooltip="Send one unit into the point to take control of it.\n"..
			"The unit will remain in the point and cannot be removed\n"..
			"If the squad has only one member left the squad is lost",
	id=CMD_TAKE,
	type=CMDTYPE.ICON_UNIT,
	action="capture",
	cursor="Capture",
}

local capturers={
	[UnitDefNames.grunt.id]=true,
	[UnitDefNames.jumper.id]=true,
	[UnitDefNames.armor.id]=true,
	[UnitDefNames.recruit.id]=true,
	[UnitDefNames.burner.id]=true,
	[UnitDefNames.grenadier.id]=true,
}

local bases = {
	[UnitDefNames.base.id]=true,
	[UnitDefNames.sepcore.id]=true,
}

local gaia = Spring.GetGaiaTeamID()
local point = UnitDefNames.point.id

local mgList={}
local transferList={}
local stopList={}

local takers={}
local taken={}

local destroyList={}

_G.pointCountTotal=0
GG.takers=takers

local function Take(taker, ud, team, target)
	takers[taker]=target
	taken[target]=true
	transferList[target]=team
	Spring.MoveCtrl.Enable(taker)
	local x,y,z=Spring.GetUnitBasePosition(target)
	Spring.MoveCtrl.SetPosition(taker,x,y,z)
	GG.RemoveSquadUnit(taker, ud, team)
	Spring.SetUnitNoSelect(taker,true)
	stopList[taker]=true
end

function gadget:UnitCreated(u,ud,team)
	if capturers[ud] then
		Spring.InsertUnitCmdDesc(u,cmdDesc)
	end
	if ud == point then
		Spring.SetUnitNoSelect(u,true)
		Spring.SetUnitAlwaysVisible(u,true)
		_G.pointCountTotal = _G.pointCountTotal + 1
	end
end

function gadget:UnitDestroyed(u,ud,team)
	if takers[u] then
		taken[takers[u]]=nil
		transferList[takers[u]]=gaia
		takers[u]=nil
	end
	if bases[ud] then
		destroyList[team]=true
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opt)
	if cmd == CMD_TAKE then
		if capturers[ud] and param[1] and Spring.GetUnitDefID(param[1])==point and Spring.GetUnitTeam(param[1])==gaia then
			return true
		else
			return false
		end
	end
	if ud == point then
		return false
	end
	if takers[u] then
		return false
	end
	return true
end

function gadget:CommandFallback(u,ud,team,cmd,param,opt)
	if cmd == CMD_TAKE then
		if Spring.GetUnitTeam(param[1]) ~= gaia or taken[param[1]] then
			return true,true --the target was already taken before we got to it
		end
		if Spring.GetUnitSeparation(u, param[1]) <= takeDist then
			Take(u, ud, team, param[1])
			return true, false
		else
			local x,y,z=Spring.GetUnitPosition(param[1])
			mgList[u]={x,y,z,takeDist*.5}
			return true, false
		end
	end
	return false
end

function gadget:GameFrame()
	for u,d in pairs(mgList) do
		Spring.SetUnitMoveGoal(u,d[1],d[2],d[3],d[4])
		mgList[u]=nil
	end
	for u,t in pairs(transferList) do
		Spring.TransferUnit(u,t,false)
		transferList[u]=nil
	end
	for u,_ in pairs(stopList) do
		Spring.GiveOrderToUnit(u,CMD.STOP,{},{})
		stopList[u]=nil
	end
	for t,_ in pairs(destroyList) do
		for _,u in ipairs (Spring.GetTeamUnits(t)) do
			if not exempt[Spring.GetUnitDefID(u)] then
				Spring.DestroyUnit(u)
			end
		end
	end
end


else

--UNSYNCED
function gadget:Initialize()
	Spring.SetCustomCommandDrawData(CMD_TAKE,"Capture",{1,1,.2,1})
end

end
