local waveTypes=VFS.Include("LuaRules/Header/waveTypes.lua", nil, VFS.MOD)

local waveKeys={}
for i,d in pairs(waveTypes) do
	waveKeys[i]={
		key=""..(i-1),
		name=d.name,
		desc="Set "..d.name.." as the lowest possible wave level vote",
	}
end

local options={
	{
		key="startblobs",
		name="Starting blob count",
		desc="The Master Converter starts with this many blobs loaded",
		type="number",
		def=10,
		min=1,
		max=100,
		step=1,
	},
	{
		key="minwave",
		name="Minimum Wave Level Vote",
		desc="The lowest wave level players can vote for, increase for games with higher start blob counts",
		type="list",
		def="1",
		items=waveKeys,
	},
	{
		key="maxblobs",
		name="Maximum blob strength",
		desc="If more than this many blobs of one type are loaded into a unit they won't have any additional effect.\nAdditional blobs will still need to be depleted to kill the unit",
		type="number",
		def=5000,
		min=20,
		max=5000,
		step=1,
	},
}
return options
