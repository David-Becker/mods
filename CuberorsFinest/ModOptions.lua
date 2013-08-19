local options={
	{
		key="pointmode",
		name="Point placement method",
		desc="The method that will be used to determine where to spawn points, some options may work better on different maps",
		type="list",
		def="metal",
		items = {
			{ key = "metal", name = "Metal spots", desc = "Place the points on the map's metal spots (not recommended on maps with weird metal layouts)" },
			{ key = "geovent", name = "Geothermal Vents", desc = "Use the geovents (e.g. on Kernel Panic maps)" },
		}
	},
	{
		key="relics",
		name="Enable Logistics Beacons",
		desc="Geovents turn into logistics beacons that allow you to summon heavy units. Ignored if the vents are already used for point placement",
		type="bool",
		def="true",
	    section = "Rules",
	},
}
return options
