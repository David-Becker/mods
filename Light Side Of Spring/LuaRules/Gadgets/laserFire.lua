function gadget:GetInfo()
	return {
		name = "laserFire",
		desc = "fire command",
		author = "KDR_11k (David Becker)",
		date = "2008-06-14",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local CMD_FIRE = 32601

local laser = UnitDefNames.laser.id

function gadget:AllowCommand(u, ud, team, cmd, param, opt)
	if cmd==CMD_FIRE then
		return ud==laser
	else
		return true
	end
end

function gadget:CommandFallback(u, ud, team, cmd, param, opt)
	if cmd == CMD_FIRE then
		local _,f = Spring.CallCOBScript(u, "Fire", 1,0)
		--Spring.Echo(f)
		return true, f==1
	end
	return false
end

function gadget:UnitCreated(u, ud, team)
	if ud==laser then
		Spring.InsertUnitCmdDesc(u, {
			name="Fire",
			tooltip="I'M CHARGING MY LASER",
			type=CMDTYPE.ICON,
			cursor="Attack",
			id=CMD_FIRE,
			action="onoff",
		})
	end
end

else

--UNSYNCED

return false

end
