function gadget:GetInfo()
	return {
		name = "defaultCommand",
		desc = "gives certain units default commands",
		author = "KDR_11k (David Becker)",
		date = "2007-11-18",
		license = "None",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED
return false

else
local CMD_ALIGN = 32600

function gadget:DefaultCommand()
	return CMD_ALIGN
end

end
