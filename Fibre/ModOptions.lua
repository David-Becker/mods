local options= {
	{
		key = "nodepartcost",
		name = "Growing Node Cost",
		desc = "Adds a growing parts cost to nodes",
		type = "bool",
		def = true
	},
	{
		key = "doomsday",
		name = "King of the Doomsday",
		desc = "Spawn a capturable doomsday device in the center of the map",
		type = "bool",
		def = false
	},
	{
		key="replacegeos",
		name="Replace geos with",
		desc="Choose a neutral unit to spawn instead of geovents",
		type="list",
		def="no",
		items = {
			{ key = "no", name = "Nothing", desc = "Don't replace geos" },
			{ key = "node", name = "Unclaimed Nodes", desc = "Nodes" },
			{ key = "neutral_nukelauncher", name = "Missile Silos", desc = "A single-use nuclear missile silo" },
			{ key = "neutral_supercharger", name = "Superchargers", desc = "A powerful energy source" },
		}
	},
	{
		key = "infiniterange",
		name = "Infinite unit range (USE AT YOUR OWN PERIL!)",
		desc = "Makes all units capable of moving anywhere",
		type = "bool",
		def = false
	},
	{
		key="creeprate",
		name="Spawn rate for hostiles",
		desc="affect the rate at which units appear for a hostile bot",
		type="list",
		def="1.0",
		items = {
			{ key = "0.75", name = "Fast", desc = "Faster spawning" },
			{ key = "1.0", name = "Normal", desc = "Regular spawn rates" },
			{ key = "1.5", name = "Slow", desc = "Slow spawning" },
		}
	},
}

return options
