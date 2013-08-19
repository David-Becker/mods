function gadget:GetInfo()
	return {
		name = "turretLauncher",
		desc = "Implements the turret launcher",
		author = "KDR_11k (David Becker)",
		date = "2007-11-18",
		license = "None",
		layer = 50,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local launchedTurret = UnitDefNames.turret_projectile.id
local tlWeapon = WeaponDefNames.turretlauncher.id
local createList = {}

function gadget:Initialize()
	Script.SetWatchWeapon(tlWeapon, true)
end

function gadget:Explosion(w, x, y, z, owner)
	if w == tlWeapon and owner then
		if not Spring.GetGroundBlocked(x,z) then
			table.insert(createList, {owner = owner, x=x,y=y,z=z})
			return true
		end
	end
	return false
end

function gadget:GameFrame(f)
	for i,c in pairs(createList) do
		local u = Spring.CreateUnit("turret_projectile", c.x, c.y, c.z, 0, Spring.GetUnitTeam(c.owner))
		GG.parent[u]=c.owner
		createList[i]=nil
	end
end

end
