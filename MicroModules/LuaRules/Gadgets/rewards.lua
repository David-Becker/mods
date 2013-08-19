function gadget:GetInfo()
	return {
		name = "Rewards",
		desc = "gives rewards for killing creeps",
		author = "KDR_11k (David Becker)",
		date = "2008-09-13",
		license = "Public Domain",
		layer = 3,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE, CMD_EJECT, CMD_WAVE = VFS.Include("LuaRules/Header/header.lua", nil, VFS.MOD)


if (gadgetHandler:IsSyncedCode()) then

--SYNCED
local gaia = Spring.GetGaiaTeamID()
local master = UnitDefNames.master.id
local createList={}
local creepOwner={}

local reload={}

local function Reward(hurtU,attacker, count)
	if attacker then
		local aud = Spring.GetUnitDefID(attacker)
		if higherUnits[aud] then
			GG.AddBlobs(attacker, aud, math.random(#(higherUnits[aud].contInv)), count)
		else
			local x,y,z=Spring.GetUnitPosition(attacker)
			local team =Spring.GetUnitTeam(attacker)
			local type =UnitDefs[aud].name
			if team == gaia then
				return
			end
			for i = 1,count do
				local phi = math.random(628)/100
				local amp = 50 + math.random(40)
				table.insert(createList, {
					type, x + math.cos(phi)*amp,y,z + math.sin(phi)*amp, team,x,z
				})
			end
		end
	elseif creepOwner[hurtU] then
		local m = Spring.GetTeamUnitsByDefs(creepOwner[hurtU],master)
		if m[1] then
			GG.AddBlobs(m[1], master, 1, count)
		end
	end
end

function gadget:UnitDestroyed(u, ud, team, attacker)
	if team == gaia and attacker then
		Reward(u, attacker, 1)
	end
end


function gadget:GameFrame(f)
	for i,d in pairs(createList) do
		local nu = GG.NewUnit(d[1],d[2],d[3],d[4],0,d[5])
		if (nu) then
			Spring.SetUnitWeaponState(nu, 0, {reloadState=Spring.GetGameFrame() + reload[d[1]]*2})
			GG.EjectJump(nu,d[6],d[3],d[7],false)
		end
		createList[i]=nil
	end
end

function gadget:Initialize()
	GG.Reward=Reward
	GG.creepOwner=creepOwner
	for ud,n in pairs(blobs) do
		reload[UnitDefs[ud].name]=WeaponDefs[UnitDefs[ud].weapons[1].weaponDef].reload*32
	end
end

else

--UNSYNCED

return false

end
