function gadget:GetInfo()
	return {
		name = "repair",
		desc = "handles repair commands",
		author = "KDR_11k (David Becker)",
		date = "2008-03-19",
		license = "None",
		layer = 1,
		enabled = true
	}
end

local repair = UnitDefNames.repair.id
local CMD_REPAIR = 32620
local repRange = 600
local repairHealth = 400
local repairCost = 40

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local repairBeams = {}

repaird = {
		name="Repair Unit",
		tooltip="Repair the target unit",
		action="repair",
		cursor="Repair",
		type=CMDTYPE.ICON_UNIT,
		id=CMD_REPAIR
	}

function gadget:UnitCreated(u, ud, team)
	if ud == repair then
		Spring.InsertUnitCmdDesc(u, repaird)
	end
end

function gadget:AllowCommand(u, ud, team, cmd, param, opts)
	if cmd == CMD_REPAIR then
		if ud == repair then
			if Spring.GetUnitDefID(param[1]) and u ~= param[1] then
				local x,y,z = Spring.GetUnitPosition(u)
				local tx, ty, tz = Spring.GetUnitPosition(param[1])
				if (math.sqrt((tx-x)*(tx-x) + (tz-z)*(tz-z)) < repRange) then
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
	if cmd == CMD_REPAIR then
		if Spring.GetUnitDefID(param[1]) then
			local charge = Spring.GetUnitCOBValue(u, 1024)
			local hp, maxHP = Spring.GetUnitHealth(param[1])
			if hp < maxHP and charge >= repairCost then
				--Spring.CallCOBScript(u, "EmitRepair", 0)
				local ax,ay,az = Spring.GetUnitPosition(u)
				local bx,by,bz = Spring.GetUnitPosition(param[1])
				table.insert(repairBeams, {
					ax=ax, ay=ay+5, az=az,
					bx=bx, by=by, bz=bz,
					ttl = Spring.GetGameFrame() + 16,
				})
				hp = hp + repairHealth
				Spring.SetUnitHealth(param[1], math.min(hp, maxHP))
				Spring.SetUnitCOBValue(u, 1024, charge - repairCost)
			end
			return true, hp > maxHP
		else
			return true, true
		end
	end
	return false
end

function gadget:GameFrame(f)
	for i,b in pairs(repairBeams) do
		if b.ttl <= f then
			repairBeams[i]=nil
		end
	end
end

function gadget:Initialize()
	_G.repairBeams=repairBeams
	Spring.SetCustomCommandDrawData(CMD_REPAIR, "Repair", {0,1,.5,1})
end

else

local Vertex = gl.Vertex

local function DrawBeam(ax,ay,az,bx,by,bz,width)
	Vertex(ax, ay - width, az)
	Vertex(ax, ay + width, az)
	Vertex(bx, by - width, bz)
	Vertex(bx, by + width, bz)
end

function gadget:DrawWorld()
	gl.Color(0,1,.5,.7)
	gl.DepthTest(GL.LEQUAL)
	local f = Spring.GetGameFrame()
	for _,b in spairs(SYNCED.repairBeams) do
		gl.BeginEnd(GL.TRIANGLE_STRIP,DrawBeam,b.ax,b.ay,b.az,b.bx,b.by,b.bz,(b.ttl - f)*.25)
	end
	gl.DepthTest(false)
	gl.Color(0,1,.5,1)
	for _,u in ipairs(Spring.GetSelectedUnits()) do
		if Spring.GetUnitDefID(u) == repair then
			local x,y,z = Spring.GetUnitPosition(u)
			gl.DrawGroundCircle(x,y,z,repRange, 100)
		end
	end
	gl.Color(1,1,1,1)
end

end
