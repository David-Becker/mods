function widget:GetInfo()
	return {
		name = "Default Commands",
		desc = "Allows using the rightclick for some commands",
		author = "KDR_11k (David Becker)",
		date = "2008-09-07",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE = VFS.Include("LuaUI/Header/header.lua", nil, VFS.MOD)


function widget:DefaultCommand()
	local mx, my = Spring.GetMouseState()
	local s,t = Spring.TraceScreenRay(mx, my)
	if s == "unit" and Spring.GetUnitTeam(t) == Spring.GetLocalTeamID() then
		if higherUnits[Spring.GetUnitDefID(t)] then
			return CMD_JOIN
		elseif blobs[Spring.GetUnitDefID(t)] then
			return CMD_MERGE
		end
	end
end
