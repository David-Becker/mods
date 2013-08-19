function gadget:GetInfo()
	return {
		name = "BlockBomber",
		desc = "Prevents bombers from receiving move commands",
		author = "KDR_11k (David Becker)",
		date = "2007-11-18",
		license = "None",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local bomber = UnitDefNames.unit_bomber.id

function gadget:AllowCommand(u,ud,team,cmd,param,opts)
	if ud == bomber then
		if cmd == CMD.MOVE then
			return false
		end
	end
	return true
end

end
