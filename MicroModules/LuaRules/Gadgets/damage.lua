function gadget:GetInfo()
	return {
		name = "Damage",
		desc = "handles the damage for higher units",
		author = "KDR_11k (David Becker)",
		date = "2008-02-10",
		license = "Public Domain",
		layer = 10,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE = VFS.Include("LuaRules/Header/header.lua", nil, VFS.MOD)


if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local gaia=Spring.GetGaiaTeamID()
local min = math.min

function gadget:UnitDamaged(u, ud, team, damage, para, weapon, attacker)
	if higherUnits[ud] then
		local bc1, bc2 = Spring.GetUnitCOBValue(u, blobCount + 1), Spring.GetUnitCOBValue(u, blobCount + 2)
		local bc = bc1 + bc2
		local health, maxHealth = Spring.GetUnitHealth(u)
		local lost=0
		if damage > health and bc > 0 then
			local heal = 0
			local hpBonus=higherUnits[ud].hpBonus
			while damage > health + heal and bc > 0 do
				bc = bc - 1
				local t = nil
				if bc1 > 0 and bc2 > 0 then
					t = math.random(1,2)
				elseif bc1 > 0 then
					t = 1
				else
					t = 2
				end
				if t==1 then
					bc1 = bc1 - 1
					if bc1 < GG.maxBlob then
						maxHealth = maxHealth - hpBonus
					end
				else
					bc2 = bc2 - 1
				end
				heal = heal + maxHealth
				lost=lost+1
			end
			Spring.SetUnitCOBValue(u, blobCount +1, bc1)
			Spring.CallCOBScript(u, "ChangedBlobCount", 0, 1, min(bc1,GG.maxBlob), math.sqrt(min(bc1,GG.maxBlob)))
			Spring.SetUnitCOBValue(u, blobCount +2, bc2)
			Spring.CallCOBScript(u, "ChangedBlobCount", 0, 2, min(bc2,GG.maxBlob), math.sqrt(min(bc2,GG.maxBlob)))
			Spring.SetUnitMaxHealth(u, maxHealth)
			Spring.SetUnitHealth(u, {health=health + heal})
			if team == gaia then
				GG.Reward(u, attacker, lost)
			end
		end
	end
end

else

--UNSYNCED

return false

end
