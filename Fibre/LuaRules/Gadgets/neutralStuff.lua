function gadget:GetInfo()
	return {
		name = "neutral Stuff",
		desc = "Allows pre-spawning neutral buildings on a map",
		author = "KDR_11k (David Becker)",
		date = "2007-12-04",
		license = "None",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

function gadget:GameFrame(f)
	if Spring.GetModOptions()["doomsday"]=="1" then
		placed = true
		local x,y,z,c = 0,0,0,0
		for _,u in ipairs(Spring.GetAllUnits()) do
			local tx, ty, tz = Spring.GetUnitPosition(u)
			x=x+tx
			y=y+ty
			z=z+tz
			c=c+1
		end
		Spring.CreateUnit("neutral_doomsday", x/c, y/c, z/c, 0, Spring.GetGaiaTeamID())
	end
	local geoMode = Spring.GetModOptions().replacegeos
	if not geoMode then
		geoMode="no"
	end
	if geoMode ~= "no" then
		--local geo = FeatureDefNames.geovent.id
		for _,f in ipairs(Spring.GetAllFeatures()) do
			if FeatureDefs[Spring.GetFeatureDefID(f)].geoThermal then
				local x,y,z = Spring.GetFeaturePosition(f)
				Spring.DestroyFeature(f)
				Spring.CreateUnit(geoMode, x,y,z, 0, Spring.GetGaiaTeamID())
			end
		end
	end
	gadgetHandler.RemoveGadget("neutral Stuff")
end

end
