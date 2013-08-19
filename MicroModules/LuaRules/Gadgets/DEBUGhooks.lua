function gadget:GetInfo()
	return {
		name = "Debug Hooks",
		desc = "Allows placing debug hooks that aren't visible until checked with the matching widget",
		author = "KDR_11k (David Becker)",
		date = "2008-09-15",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

local function Debug(...)
	SendToUnsynced("DEBUGMESSAGE",...)
end

function gadget:Initialize()
	GG.Debug=Debug
end

--SYNCED

else

--UNSYNCED

function gadget:RecvFromSynced(name, ...)
	if name=="DEBUGMESSAGE" and Script.LuaUI("DebugMessageOutput") then
		local spec=Spring.GetSpectatingState()
		if spec then
			Script.LuaUI.DebugMessageOutput(...)
		end
	end
end

end
