function gadget:GetInfo()
	return {
		name = "relics",
		desc = "Handles the relics",
		author = "KDR_11k (David Becker)",
		date = "2009-03-15",
		license = "Public Domain",
		layer = 18,
		enabled = true
	}
end

local base = UnitDefNames.base.id
local sepcore = UnitDefNames.sepcore.id
local relic = UnitDefNames.relic.id
local tank = UnitDefNames.tank.id
local controller = UnitDefNames.controller.id

local relicRadius=300
local relicMaxCharge=300

local relicUnitType = {
	[base]=controller,
	[sepcore]=tank,
}

local gaia = Spring.GetGaiaTeamID()

if not ((Spring.GetModOptions().relics or "1")=="1") or Spring.GetModOptions().pointmode =="geovent" then
	return false
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED
local geovent = FeatureDefNames.geovent.id

local relics={}
local relicCharge={}
local relicUnit={}

local squads

function gadget:Initialize()
	local i = 1
	for _,f in ipairs(Spring.GetAllFeatures()) do
		if Spring.GetFeatureDefID(f) == geovent then
			local x,y,z=Spring.GetFeaturePosition(f)
			relics[i]={pos={x,y,z}}
			i=i+1
		end
	end
	if i==1 then
		Spring.Echo("removed")
		gadgetHandler:RemoveGadget() --nothing to do here
	end
	for _,t in ipairs(Spring.GetTeamList()) do
		relicCharge[t]=0
	end
	squads=GG.squads
	_G.relicCharge=relicCharge
	_G.relics=relics
end

function gadget:AllowCommand(u,ud,team)
	if ud == relic then
		return false
	end
	return true
end

function gadget:GameFrame(f)
	if f == 3 then
		for _,f in ipairs (Spring.GetAllFeatures()) do
			if Spring.GetFeatureDefID(f)==geovent then
				Spring.DestroyFeature(f)
			end
		end
		for i,d in pairs(relics) do
			d.unit = Spring.CreateUnit(relic,d.pos[1],d.pos[2],d.pos[3],0,gaia)
		end
	end
	if (f-8) % 16 < .1 then
		for i,d in pairs(relics) do
			local owner=nil
			local count=1
			for _,u in ipairs(Spring.GetUnitsInCylinder(d.pos[1],d.pos[3],relicRadius)) do
				if squads[u] then
					local team = Spring.GetUnitTeam(u)
					if not owner then
						owner=team
					elseif owner ~= team then
						owner=false
						break
					end
					count=count + 1
				end
			end
			if owner then
				Spring.TransferUnit(d.unit,owner,false)
				relicCharge[owner]=relicCharge[owner]+count
				Spring.CallCOBScript(d.unit,"SetCharge",0,math.min(relicCharge[owner]/relicMaxCharge,1)*65536)
			else
				Spring.TransferUnit(d.unit,gaia,false)
				Spring.CallCOBScript(d.unit,"SetCharge",0,0)
			end
		end
		for t,c in pairs(relicCharge) do
			if c >= relicMaxCharge then
				if relicUnit[t] then
					relicCharge[t]=relicMaxCharge
				else
					for ud,rud in pairs(relicUnitType) do
						local baseUnit = Spring.GetTeamUnitsByDefs(t,ud)[1]
						if baseUnit then
							local x,y,z=Spring.GetUnitPiecePosDir(baseUnit,Spring.GetUnitPieceMap(baseUnit).spawner)
							relicUnit[t]=Spring.CreateUnit(rud,x,y,z,0,t)
							local rp = GG.rallyPoints[baseUnit]
							Spring.GiveOrderToUnit(relicUnit[t],CMD.MOVE,{rp[1],rp[2],rp[3]},{})
						end
					end
				end
			end
		end
	end
end

function gadget:UnitDestroyed(u,ud,team)
	if relicUnit[team]==u then
		relicUnit[team]=nil
		relicCharge[team]=0
	end
end

function gadget:UnitCreated(u, ud, team)
	if ud == relic then
		Spring.SetUnitAlwaysVisible(u,true)
		Spring.SetUnitNoSelect(u,true)
	end
end

else

--UNSYNCED

local left, right, top, bottom = 0,0,0,0

function gadget:DrawWorldPreUnit()
	gl.Color(.4,.4,.4,1)
	for _,d in spairs(SYNCED.relics) do
		gl.DrawGroundCircle(d.pos[1],d.pos[2],d.pos[3],relicRadius,50)
	end
	gl.Color(1,1,1,1)
end

local border=2

function gadget:DrawScreen(vsx,vsy)
	local team = Spring.GetLocalTeamID()
	left = vsx*.75
	right = vsx*.95
	top = vsy-50
	bottom = top - 15
	gl.Color(.2,.2,.2,1)
	gl.Rect(left - border, top + border, right + border, bottom - border)
	if SYNCED.relicCharge[team] < relicMaxCharge then
		gl.Color(.8,.8,.2,1)
	else
		gl.Color(0,.8,0,1)
	end
	gl.Rect(left, top, left + (SYNCED.relicCharge[team] / relicMaxCharge)*(right - left), bottom)
	gl.Text("Logistics Charge", left, top - 5, 12,"oc")
end

function gadget:IsAbove(x,y)
	if x > left and x < right and y > bottom and y < top then
		return true
	end
	return false
end

function gadget:GetTooltip()
	local team = Spring.GetLocalTeamID()
	return "Logistics Charge: "..math.floor((SYNCED.relicCharge[team] / relicMaxCharge)*100).."%\n"..
		"Your progress towards fielding a heavy unit.\n"..
		"Bring squads near Logistics Beacons to increase it (more beacons and squads = more charge)\n"..
		"It will remain at 100% when your heavy unit is on the field"
end

function gadget:Initialize()
	if not SYNCED.relics then
		gadgetHandler:RemoveGadget()
	end
end

end
