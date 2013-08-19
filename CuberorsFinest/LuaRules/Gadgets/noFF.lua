function gadget:GetInfo()
	return {
		name = "no friendly fire",
		desc = "nullifies friendly fire damage",
		author = "KDR_11k (David Becker)",
		date = "2008-05-20",
		license = "Public Domain",
		layer = 20,
		enabled = true
	}
end

local exempt= {
	[WeaponDefNames.grenade.id]=1.0,
	[WeaponDefNames.burner.id]=1.0,
}

local GetUnitAllyTeam = Spring.GetUnitAllyTeam
local GetUnitHealth = Spring.GetUnitHealth
local SetUnitHealth = Spring.SetUnitHealth

if (gadgetHandler:IsSyncedCode()) then

function gadget:UnitDamaged(u,ud,team,damage,para,weapon,au,aud,ateam)
	if exempt[weapon] and (not au or GetUnitAllyTeam(u) == GetUnitAllyTeam(au)) then
		local h = GetUnitHealth(u)
		SetUnitHealth(u, {health = h + damage})
	end
end

--SYNCED

else

--UNSYNCED

return false

end
