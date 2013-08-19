function gadget:GetInfo()
	return {
		name = "transmitter",
		desc = "handles transmitter commands",
		author = "KDR_11k (David Becker)",
		date = "2007-12-02",
		license = "None",
		layer = 1,
		enabled = true
	}
end

local transmitter = UnitDefNames.transmitter.id
local CMD_ALIGN = 32600
local transRange = 700
local node = UnitDefNames.node.id

if (gadgetHandler:IsSyncedCode()) then

--SYNCED
transd = {
		name="Align",
		tooltip="Aim the transmitter at a node",
		action="guard",
		type=CMDTYPE.ICON_UNIT,
		id=CMD_ALIGN
	}

function gadget:UnitCreated(u, ud, team)
	if ud == transmitter then
		Spring.InsertUnitCmdDesc(u, transd)
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opts)
	if cmd == CMD_ALIGN then
		if ud == transmitter then
			if Spring.GetUnitDefID(param[1]) == node then
				local x,y,z = Spring.GetUnitPosition(u)
				local tx, ty, tz = Spring.GetUnitPosition(param[1])
				if (math.sqrt((tx-x)*(tx-x) + (tz-z)*(tz-z)) < transRange) then
					return true
				else
					return false
				end
			else
				return false
			end
		else
			return false
		end
	end
	return true
end

function gadget:CommandFallback(u, ud, team, cmd, param, opts)
	if cmd == CMD_ALIGN then
		if Spring.GetUnitDefID(param[1]) == node then
			Spring.CallCOBScript(u, "AimDish", 0, param[1])
			return true, false
		else
			return true, true
		end
	end
	return false
end

else

function gadget:DrawWorld()
	for _,u in ipairs(Spring.GetSelectedUnits()) do
		if Spring.GetUnitDefID(u) == transmitter then
			local x,y,z = Spring.GetUnitPosition(u)
			gl.Color(.5,.5,1,1)
			gl.DrawGroundCircle(x,y,z,transRange, 100)
			gl.Color(1,1,1,1)
		end
	end
end

end
