--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spCreateUnit              = Spring.CreateUnit
local spGetUnitBuildFacing      = Spring.GetUnitBuildFacing
local spGetUnitCommands         = Spring.GetUnitCommands
local spGetUnitPosition         = Spring.GetUnitPosition
local spGiveOrderArrayToUnitMap = Spring.GiveOrderArrayToUnitMap
local spValidUnitID             = Spring.ValidUnitID

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Squad Spawner",
		desc = "Spawns a squad for some units",
		author = "KDR_11k (David Becker)",
		date = "2008-10-21",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local newList={}

local squadType={}
local squadSpawn={}

function gadget:UnitFinished(u,ud,team)
	if not newList[u] then
		squadSpawn[u]={ud=ud,team=team}
	end
end

function gadget:UnitCreated(u,ud,team)
	newList[u]=true
end

local function ConvertQueue(cmds)
	local newQ={}
	for i,d in ipairs(cmds) do
		newQ[i]={d.id,d.params,{}} --ignore opts since I don't think any part of a factory queue gives a damn about that...
	end
	return newQ
end

function gadget:GameFrame(f)
	newList={}
	for u,d in pairs(squadSpawn) do
		if spValidUnitID(u) then
			if squadType[d.ud] then
				local x,y,z=spGetUnitPosition(u)
				local cmds = ConvertQueue(spGetUnitCommands(u))
				local h = spGetUnitBuildFacing(u)
				local units= {}
				local su={}
				for i,nud in pairs(squadType[d.ud]) do
					local nu = spCreateUnit(nud,x+i,y,z,h,d.team)
					if nu then
						units[nu]=true
						su[i]=nu
					end
				end
				if GG.RegisterSquad and UnitDefs[d.ud].customParams.loosesquad ~= "1" then
					GG.RegisterSquad(d.ud, u,su)
				end
				spGiveOrderArrayToUnitMap(units,cmds)
			end
		end
		squadSpawn[u]=nil
	end
end

function gadget:Initialize()
	for ud,d in pairs(UnitDefs) do
		local c = d.customParams
		local i=1
		local s={}
		while c["squadmember"..i] do
			s[i]=UnitDefNames[c["squadmember"..i]].id
			i=i+1
		end
		if i > 1 then
			squadType[ud]=s
		end
	end
end

else

--UNSYNCED

return false

end
