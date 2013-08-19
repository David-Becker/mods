function widget:GetInfo()
	return {
		name = "Node ranges",
		desc = "Draws node coverage when placing a node",
		author = "KDR_11k (David Becker)",
		date = "2007-11-18",
		license = "None",
		layer = 1,
		enabled = true
	}
end

local node=UnitDefNames.node.id
local citadel=UnitDefNames.citadel.id
local nodeConnect=500
local nodeRange=200

function widget:DrawWorld()
	local _,cmd,_,_=Spring.GetActiveCommand()
	if cmd == -node then
		for _,u in pairs(Spring.GetTeamUnits(Spring.GetLocalTeamID())) do
			if Spring.GetUnitDefID(u)==node or Spring.GetUnitDefID(u)==citadel then
				local x,y,z=Spring.GetUnitBasePosition(u)
				gl.Color(.2,.2,1,1)
				gl.DrawGroundCircle(x,y,z,nodeConnect, 30)
				gl.Color(.2,.2,1,.5)
				gl.DrawGroundCircle(x,y,z,nodeRange, 20)
				gl.Color(1,1,1,1)
			end
		end
	end
end
