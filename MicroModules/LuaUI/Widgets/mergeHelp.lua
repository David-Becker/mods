function widget:GetInfo()
	return {
		name = "Merge Help",
		desc = "Shows what unit will result from the merge",
		author = "KDR_11k (David Becker)",
		date = "2008-09-17",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE = VFS.Include("LuaUI/Header/header.lua", nil, VFS.MOD)

local mergeNames={
	[red]= {
		[red]="Rocket Artillery Turret",
		[green]="Bomber Plane",
		[blue]="Tank Hunter Vehicle",
	},
	[green]= {
		[red]="Missile Turret",
		[green]="Fighter Plane",
		[blue]="Disruptor Tank",
	},
	[blue]= {
		[red]="Cannon Turret",
		[green]="Air Fortress Gunship",
		[blue]="Battle Tank",
	},
}

function widget:DrawScreen()
	for _,u in ipairs(Spring.GetSelectedUnits()) do
		local ud=Spring.GetUnitDefID(u)
		if blobs[ud] then
			local mx, my = Spring.GetMouseState()
			local s,t = Spring.TraceScreenRay(mx, my)
			if s == "unit" and Spring.GetUnitTeam(t) == Spring.GetLocalTeamID() then
				if blobs[Spring.GetUnitDefID(t)] then
					gl.Text("Merge into "..mergeNames[ud][Spring.GetUnitDefID(t)],mx+30,my-10,14,"ol")
				end
			end
			break
		end
	end
end
