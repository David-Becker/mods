function gadget:GetInfo()
	return {
		name = "Blob damage",
		desc = "Handles the bonus damage for some units",
		author = "KDR_11k (David Becker)",
		date = "2008-09-04",
		license = "Public Domain",
		layer = 10,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE = VFS.Include("LuaRules/Header/header.lua", nil, VFS.MOD)
local rtweapon={
	[WeaponDefNames.tankredgun.id]=700,
	[WeaponDefNames.turretredgun.id]=60,
	[WeaponDefNames.tankblackgun.id]=600,
	[WeaponDefNames.airredgun.id]=400,
	[WeaponDefNames.airbluecannon.id]=250,
}
local singleColor={
	[WeaponDefNames.tankblackgun.id]=true,
	[WeaponDefNames.turretredgun.id]=true,
}


if (gadgetHandler:IsSyncedCode()) then

--SYNCED

function gadget:UnitDamaged(u, ud, team, damage, para, weapon, attacker, aud, ateam)
	if rtweapon[weapon] and attacker and u~=attacker then
		local bc=nil
		if not singleColor[weapon] then
			bc = Spring.GetUnitCOBValue(attacker, blobCount + 2) --weapon blobs
		else
			bc = Spring.GetUnitCOBValue(attacker, blobCount + 1) --black tanks have only one blob value
		end
		Spring.AddUnitDamage(u, rtweapon[weapon]*bc, 0, attacker)
	end
end

else

--UNSYNCED

return false

end
