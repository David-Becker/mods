function gadget:GetInfo()
	return {
		name = "megaImpulse",
		desc = "flings stuff around",
		author = "KDR_11k (David Becker)",
		date = "2008-07-18",
		license = "Public Domain",
		layer = 1,
		enabled = false
	}
end

local impulseWeapons= {
    [WeaponDefNames.pong.id]=3,
}

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

function gadget:UnitDamaged(u, ud, team, damage, para, weapon, au)
    if impulseWeapons[weapon] and UnitDefs[ud].canMove and UnitDefs[ud].type~="Factory" then
        Spring.AddUnitImpulse(u,0,9000,0)
        local x,y,z=Spring.GetUnitPosition(u)
        local ax,ay,az,d
        if au then
	        ax,ay,az=Spring.GetUnitPosition(au)
	        d=WeaponDefs[weapon].range --math.sqrt((x-ax)*(x-ax)+(z-az)*(z-az))
        else
	        ax,ay,az=Spring.GetUnitPosition(u)
	        d=1
        end
        local i = impulseWeapons[weapon]
        Spring.SetUnitVelocity(u,2.5*i*(x-ax)/d,15,2.5*i*(z-az)/d)
    end
end

else

--UNSYNCED

return false

end
