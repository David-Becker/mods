local black, tankblack

if UnitDefNames then --not defined for modoptions
	black=UnitDefNames.black.id
	tankblack=UnitDefNames.tankblack.id
else
	black=1
	tankblack=2
end

return {
	{
		name="Laughable",
		tooltip="1 shadow blob",
		content= {
			[black]=1,
		},
	},
	{
		name="Easy",
		bc=0,
		tooltip="4 shadow blobs, 1 tank (0 blobs per tank)",
		content= {
			[black]=4,
			[tankblack]=1,
		},
	},
	{
		name="Medium",
		bc=2,
		tooltip="10 shadow blobs, 2 tanks (2 blobs per tank)",
		content= {
			[black]=10,
			[tankblack]=2,
		},
	},
	{
		name="Hard",
		bc=5,
		tooltip="30 shadow blobs, 3 tanks (5 blobs per tank)",
		content= {
			[black]=30,
			[tankblack]=3,
		},
	},
	{
		name="Very Hard",
		bc=15,
		tooltip="50 shadow blobs, 4 tanks (15 blobs per tank)",
		content= {
			[black]=50,
			[tankblack]=4,
		},
	},
}
