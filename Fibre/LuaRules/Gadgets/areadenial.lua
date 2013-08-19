function gadget:GetInfo()
	return {
		name = "Area Denial",
		desc = "Lets a weapon's damage persist in an area",
		author = "KDR_11k (David Becker)",
		date = "2007-08-26",
		license = "Public domain",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local frameNum
local explosionList={}
local weaponInfo= {}

function gadget:Explosion(weaponID, px, py, pz, ownerID)
	if (weaponInfo[weaponID]) then
		local w={}
		w.radius=weaponInfo[weaponID].radius
		w.damage=weaponInfo[weaponID].damage/30
		w.expiry=frameNum + weaponInfo[weaponID].ttl
		w.id=weaponID;
		w.pos={x=px, y=py, z=pz}
		w.owner=ownerID
		table.insert(explosionList,w)
	end
	return false
end

function gadget:GameFrame(f)
	frameNum=f
	for i,w in pairs(explosionList) do
		local ulist = Spring.GetUnitsInSphere(w.pos.x, w.pos.y, w.pos.z, w.radius)
		if (ulist) then
			for _,u in ipairs(ulist) do
				Spring.AddUnitDamage(u, w.damage, 0, w.owner, w.id, 0, 0, 0)
			end
		end
		if f >= w.expiry then
			explosionList[i] = nil
		end
	end
end

function gadget:Initialize()
	weaponInfo[WeaponDefNames["turretnapalm"].id] = { radius=70, damage=30, ttl=100 }
	for w,_ in pairs(weaponInfo) do
		Script.SetWatchWeapon(w, true)
	end
end

end
