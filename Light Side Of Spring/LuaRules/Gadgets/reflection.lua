function gadget:GetInfo()
	return {
		name = "reflection",
		desc = "the meat of the game",
		author = "KDR_11k (David Becker)",
		date = "2008-06-14",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

local attacklaser = WeaponDefNames.laser.id
local guidelaser = WeaponDefNames.guidelaser.id

local reflective= {
	[UnitDefNames.mirror.id]=true,
	[UnitDefNames.splitter.id]=true,
	[UnitDefNames.bottle.id]=true,
}

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local timeout={}
local timeToNeutral=150

local transferList={}

function gadget:UnitDamaged(u, ud, team, damage, para, weapon, attacker, au, ateam)
	if reflective[ud] and attacker then
		local x,y,z = Spring.GetUnitPosition(u)
		local ax,ay,az = Spring.GetUnitPosition(attacker)
		local heading = Spring.GetHeadingFromVector(ax-x+1,az-z)
		if weapon == attacklaser then
			local _,damageReduction = Spring.CallCOBScript(u,"ForwardLaser",1,0,heading)
			local health, maxHealth = Spring.GetUnitHealth(u)
			Spring.SetUnitHealth(u, {health = math.min(health + (damageReduction/100.0 * damage), maxHealth)})
		else
			Spring.CallCOBScript(u,"AimLaser",0,heading)
			timeout[u]=Spring.GetGameFrame()+timeToNeutral
			if team == Spring.GetGaiaTeamID() then
				transferList[u]=ateam
			end
		end
	end
end

function gadget:UnitFinished(u, ud, team)
	if reflective[ud] then
		timeout[u]=Spring.GetGameFrame()+timeToNeutral
	end
end

function gadget:UnitDestroyed(u, ud, team)
	timeout[u]=nil
end

function gadget:GameFrame(f)
	if f%32 < .1 then
		for u,t in pairs(timeout) do
			if t < f then
				transferList[u]=Spring.GetGaiaTeamID()
				timeout[u]=nil
			end
		end
	end
	for u,t in pairs(transferList) do
		Spring.TransferUnit(u, t, false)
		timeout[u]=nil
		transferList[u]=nil
	end
end

else

--UNSYNCED

return false

end
