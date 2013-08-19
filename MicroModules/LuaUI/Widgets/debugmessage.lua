function widget:GetInfo()
	return {
		name = "Debug Message",
		desc = "Shows debug messages (spectator only)",
		author = "KDR_11k (David Becker)",
		date = "2008-09-15",
		license = "Public Domain",
		layer = 1,
		enabled = false
	}
end

function widget:Initialize()
	widgetHandler:RegisterGlobal("DebugMessageOutput",Spring.Echo)
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal("DebugMessageOutput")
end
