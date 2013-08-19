local options={
	{
		key="pointlimit",
		name="Point Limit:",
		desc="Number of points needed to win the match",
		type="number",
		def=21,
		min=1,
		max=9001,
		step=1,
	},
	{
		key="bouncywalls",
		name="Elastic Walls",
		desc="Prevents a horizontal out.",
		type="bool",
		def=false,
	},
	{
		key="bouncycenter",
		name="Elastic Center",
		desc="Prevents a center out.",
		type="bool",
		def=false,
	},
}
return options
