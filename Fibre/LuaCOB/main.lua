local destroyQueue = {}
local replaceQueue={}
local createQueue={}

function GameFrame(t)
	for i,u in pairs(destroyQueue) do
		Spring.DestroyUnit(u, true) --using selfD to prevent plane crashing anim
		destroyQueue[i]=nil
	end
	for i,u in pairs(replaceQueue) do
		local x, y, z
		x, y, z = Spring.GetUnitPosition(u.unit)
		nu = Spring.CreateUnit(u.target,x,y,z,0,u.team)
		Spring.SetUnitBlocking(nu, false)
		Spring.SetUnitCOBValue(nu, 82, Spring.GetUnitHeading(u.unit))
		Spring.SetUnitHealth(nu, Spring.GetUnitHealth(u.unit) / UnitDefs[Spring.GetUnitDefID(u.unit)].health * UnitDefs[Spring.GetUnitDefID(nu)].health)
		Spring.DestroyUnit(u.unit, false, true)
		replaceQueue[i] = nil
	end
	for i,u in pairs(createQueue) do
		Spring.CreateUnit(u.target,u.x,u.y,u.z,0,u.team)
		createQueue[i] = nil
	end
end

function Destroy(u, ud, team)
	table.insert(destroyQueue, u)
end

function GetCentralHeading(unit, ud, team)
	local x=0
	local z=0
	local count = 0
	for _,u in ipairs(Spring.GetAllUnits()) do
		local tempx, tempz
		tempx, _, tempz = Spring.GetUnitPosition(u)
		x = x + tempx
		z = z + tempz
		count = count + 1
	end
	local ux, uz
	ux, _, uz = Spring.GetUnitPosition(unit)
	return Spring.GetHeadingFromVector(x/count-ux, x/count-uz)
end

function GetHealth(u, ud, team, target)
	return Spring.GetUnitHealth(target)
end

function IsParalyzed(u,ud,team)
	return Spring.GetUnitIsStunned(u)
end
