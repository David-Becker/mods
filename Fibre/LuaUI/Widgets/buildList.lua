function widget:GetInfo()
	return {
		name = "Build list",
		desc = "Provides an always visible build list on the right side of the screen",
		author = "KDR_11k (David Becker)",
		date = "2007-11-18",
		license = "None",
		layer = 1,
		enabled = true
	}
end

local citadel=UnitDefNames.citadel.id
local enabled = false
local count = 0
local entries = {}
local myCitadel
local nextCommand

local buttonSizeX=62
local buttonSizeY=50
local borderX = 1
local borderY = 1
local buttonsPerRow=2
local posFromTop=80
local posFromRight=10

local vsx, vsy = widgetHandler:GetViewSizes()

local left = vsx - buttonSizeX * buttonsPerRow - posFromRight
local top = vsy - posFromTop
local right = vsx - posFromRight
local bottom = top

function widget:MousePress(x,y,button)
	if button == 1 then
		if x >= left and x <= right and y >= bottom and y <= top then
			local icon = buttonsPerRow*math.floor((top - y)/buttonSizeY) + math.floor((x - left)/buttonSizeX)
			if entries[icon] then
				Spring.SelectUnitArray({myCitadel})
				nextCommand=-entries[icon].id
			end
			return true
		end
	end
end

function widget:IsAbove(x,y)
	return enabled and x >= left and x <= right and y >= bottom and y <= top
end

function widget:GetTooltip(x,y)
	if x >= left and x <= right and y >= bottom and y <= top then
		local icon = buttonsPerRow*math.floor((top - y)/buttonSizeY) + math.floor((x - left)/buttonSizeX)
		if entries[icon] then
			return entries[icon].tooltip
		else
			return ""
		end
	end
end

function widget:GameFrame()
	if nextCommand and Spring.IsUnitSelected(myCitadel) then
		if Spring.SetActiveCommand(Spring.FindUnitCmdDesc(myCitadel,nextCommand)) then
			nextCommand=nil
		end
	end
end

function widget:Initialize()
	local factoryProduct={}
	factoryProduct[UnitDefNames.factory_light.id] = UnitDefNames.unit_light.id
	factoryProduct[UnitDefNames.factory_armor.id] = UnitDefNames.unit_armor.id
	factoryProduct[UnitDefNames.factory_bomber.id] = UnitDefNames.unit_bomber.id
	factoryProduct[UnitDefNames.factory_gunship.id] = UnitDefNames.unit_gunship.id
	for i,bo in ipairs (UnitDefs[citadel].buildOptions) do
		local e = {}
		e.id = bo
		e.name = UnitDefs[bo].humanName
		e.tooltip = UnitDefs[bo].humanName.."\n"..
				  UnitDefs[bo].tooltip .."\n"..
				  "Cost: "..UnitDefs[bo].energyCost.."\n"..
				  "Energy: "..UnitDefs[bo].energyMake.."/"..UnitDefs[bo].energyStorage.."\n"
		if factoryProduct[bo] then
			e.tooltip = e.tooltip.."Unit cost: P:"..UnitDefs[factoryProduct[bo]].metalCost.." E:"..UnitDefs[factoryProduct[bo]].energyCost.."\n"
		end
		entries[count] = e
		count = count + 1
	end
	bottom = vsy - posFromTop - buttonSizeY * math.ceil(count / buttonsPerRow)
	myCitadel = Spring.GetTeamUnitsByDefs(Spring.GetLocalTeamID(), citadel) [1]
	if myCitadel then
		enabled=true
	end
end

function widget:UnitCreated(u, ud, team)
	if ud == citadel and team == Spring.GetLocalTeamID() then
		enabled = true --not Spring.GetSpectatingState()
		myCitadel = u
	end
end

function widget:ViewResize(x, y)
	vsx, vsy = widgetHandler:GetViewSizes()

	left = vsx - buttonSizeX * buttonsPerRow - posFromRight
	top = vsy - posFromTop
	right = vsx - posFromRight
	if bottom then
		bottom = vsy - posFromTop - buttonSizeY * math.ceil(count / buttonsPerRow)
	end
end

function widget:DrawScreen()
	if enabled then
		gl.Color(.2,.2,.2,1)
		gl.Rect(left, top, right, bottom)
		gl.Color(1,1,1,1)
		for i, e in pairs(entries) do
			gl.Texture("#"..e.id)
			gl.TexRect(left + buttonSizeX*math.floor(i % buttonsPerRow) + borderX,
			           top - buttonSizeY * math.floor(i/buttonsPerRow) - borderY,
					   left + buttonSizeX*math.floor(i % buttonsPerRow +1) - borderX,
			           top - buttonSizeY * math.floor(i/buttonsPerRow +1) + borderY, false, true)
			local _,ac = Spring.GetActiveCommand()
			if ac == -e.id then
				gl.Color(1,1,1,.3)
				gl.Texture(false)
				gl.Rect(left + buttonSizeX*math.floor(i % buttonsPerRow),
				           top - buttonSizeY * math.floor(i/buttonsPerRow),
						   left + buttonSizeX*math.floor(i % buttonsPerRow +1),
				           top - buttonSizeY * math.floor(i/buttonsPerRow +1))
				gl.Color(1,1,1,1)
			end
		end
		gl.Texture(false)
	end
end
