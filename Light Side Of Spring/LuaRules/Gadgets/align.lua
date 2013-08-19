function gadget:GetInfo()
	return {
		name = "align",
		desc = "align command",
		author = "KDR_11k (David Becker)",
		date = "2008-06-14",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local CMD_ALIGN = 32600

function gadget:AllowCommand(u, ud, team, cmd, param, opt)
	if cmd==CMD_ALIGN then
		local x,y,z = Spring.GetUnitBasePosition(u)
		Spring.CallCOBScript(u, "Align", 0, Spring.GetHeadingFromVector(param[1]-x, param[3]-z))
		return false
	else
		return true
	end
end

function gadget:UnitCreated(u, ud, team)
	Spring.InsertUnitCmdDesc(u, {
		name="Align",
		tooltip="align to",
		type=CMDTYPE.ICON_MAP,
		cursor="Attack",
		id=CMD_ALIGN,
	})
end

else

--UNSYNCED

return false

end
