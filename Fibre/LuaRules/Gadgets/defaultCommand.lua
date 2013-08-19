function gadget:GetInfo()
	return {
		name = "defaultCommand",
		desc = "gives certain units default commands",
		author = "KDR_11k (David Becker)",
		date = "2007-11-18",
		license = "None",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

else
local CMD_ALIGN = 32600
local CMD_REPAIR = 32620
local CMD_TELEPORT = 32601
local CMD_BEACON = 32123

local defCom = {}
function gadget:Initialize()
	defCom[UnitDefNames.transmitter.id]=CMD_ALIGN
	defCom[UnitDefNames.repair.id]=CMD_REPAIR
	defCom[UnitDefNames.teleporter.id]=CMD_TELEPORT
	defCom[UnitDefNames.beacon.id]=CMD_BEACON
	defCom[UnitDefNames.factory_light.id]=CMD_BEACON
	defCom[UnitDefNames.factory_armor.id]=CMD_BEACON
	defCom[UnitDefNames.factory_gunship.id]=CMD_BEACON
	defCom[UnitDefNames.factory_bomber.id]=CMD_BEACON
	GG.activeCommand=0
end

function gadget:DefaultCommand()
	local type = false
	for _,u in ipairs(Spring.GetSelectedUnits()) do
		if defCom[Spring.GetUnitDefID(u)] and type == false then
			type=defCom[Spring.GetUnitDefID(u)]
		elseif type ~= defCom[Spring.GetUnitDefID(u)] then
			type=nil
		end
	end
	return type
end

end
