function gadget:GetInfo()
	return {
		name = "dirtsplashes",
		desc = "Adds those dirt thingies",
		author = "KDR_11k (David Becker)",
		date = "2008-09-10",
		license = "Public Domain",
		layer = 10,
		enabled = true
	}
end

local blastWeapons={
	"redblobgun", "tankredgun", "turretredgun", "airredgun",
	"greenblobgun", "turretgreengun",
	"airbluecannon",
	"tankblackgun",
}

local bonus= {
	[WeaponDefNames.tankredgun.id]=100,
	[WeaponDefNames.tankblackgun.id]=500,
	[WeaponDefNames.airredgun.id]=100,
	[WeaponDefNames.airbluecannon.id]=100,
	[WeaponDefNames.turretredgun.id]=20,
}
local singleColor={
	[WeaponDefNames.tankblackgun.id]=true,
	[WeaponDefNames.turretredgun.id]=true,
}

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local GetGroundHeight=Spring.GetGroundHeight
local sqrt=math.sqrt
local min=math.min
local GetUnitCOBValue=Spring.GetUnitCOBValue

function gadget:Explosion(weapon,x,y,z,owner)
	local h = GetGroundHeight(x,z)
	if weapon and y < h + 10 and h > 0 then
		local damage=WeaponDefs[weapon].damages[1]
		if bonus[weapon] and owner then
			if not singleColor[weapon] then
				damage=sqrt((damage+bonus[weapon]*min(GetUnitCOBValue(owner,1025),GG.maxBlob))/500)*500
			else
				damage=sqrt((damage+bonus[weapon]*min(GetUnitCOBValue(owner,1024),GG.maxBlob))/500)*500
			end
		end
		SendToUnsynced("dirtblast",x,h+2,z,damage/15)
		--return true
	end
	return false
end

function gadget:Initialize()
	for _,w in pairs(blastWeapons) do
		Script.SetWatchWeapon(WeaponDefNames[w].id, true)
	end
end

else

--UNSYNCED

local Texture=gl.Texture
local PushMatrix=gl.PushMatrix
local Translate=gl.Translate
local Scale=gl.Scale
local Rotate=gl.Rotate
local Color=gl.Color
local Culling=gl.Culling
local CallList=gl.CallList
local PopMatrix=gl.PopMatrix
local Vertex=gl.Vertex
local TexCoord=gl.TexCoord
local CreateList=gl.CreateList
local FRONT=GL.FRONT
local BACK=GL.BACK
local GetGameFrame=Spring.GetGameFrame

local mOSplash=nil
local mISplash=nil
local mBase=nil --meshes

local function OuterSplash()
	local vdata= {
		{-0.25881883502, 1.52522826195, 0.965925872326, 0.0303074717522, 0.58837968111}, --0
		{-0.055873170495, 0.0199065506458, 0.208521723747, 0.390970051289, 0.52200782299}, --6
		{-0.965925693512, 1.52522826195, 0.258819460869, 0.117437630892, 0.7860917449}, --1
		{-0.208521664143, 0.0199065506458, 0.0558733046055, 0.41225323081, 0.567994236946}, --7
		{-0.707106888294, 1.52522826195, -0.707106649876, 0.282581150532, 0.925409257412}, --2
		{-0.152648508549, 0.0199065506458, -0.152648448944, 0.451578229666, 0.599951505661}, --8
		{0.258818924427, 1.52522826195, -0.965925872326, 0.492144495249, 0.977992236614}, --3
		{0.0558732002974, 0.0199065506458, -0.208521723747, 0.500945627689, 0.611378788948}, --9
		{0.965925812721, 1.52522826195, -0.258819162846, 0.703498184681, 0.933144032955}, --5
		{0.208521723747, 0.0199065506458, -0.0558732450008, 0.550313174725, 0.599951505661}, --10
		{0.707106769085, 1.52522826195, 0.707106769085, 0.873648881912, 0.799987673759}, --4
		{0.152648508549, 0.0199065506458, 0.152648508549, 0.589638411999, 0.567994236946}, --11
		{-0.25881883502, 1.52522826195, 0.965925872326, 0.967984199524, 0.605610132217}, --0
		{-0.055873170495, 0.0199065506458, 0.208521723747, 0.610921740532, 0.522007882595}, --6
	}
	for _,d in pairs(vdata) do
		TexCoord(d[4],1 - d[5])
		Vertex(d[1],d[2],d[3])
	end
end

local function InnerSplash()
	local vdata= {
		{-0.210963919759, 1.93301963806, 0.787328720093, 0.0303074717522, 0.58837968111}, --0
		{-0.0455423668027, 0.0252288486809, 0.169966608286, 0.390970051289, 0.52200782299}, --6
		{-0.787328600883, 1.93301963806, 0.210964426398, 0.117437630892, 0.7860917449}, --1
		{-0.169966563582, 0.0252288486809, 0.0455424785614, 0.41225323081, 0.567994236946}, --7
		{-0.576364696026, 1.93301963806, -0.576364517212, 0.282581150532, 0.925409257412}, --2
		{-0.12442420423, 0.0252288486809, -0.124424152076, 0.451578229666, 0.599951505661}, --8
		{0.210963994265, 1.93301963806, -0.787328720093, 0.492144495249, 0.977992236614}, --3
		{0.0455423928797, 0.0252288486809, -0.169966608286, 0.500945627689, 0.611378788948}, --9
		{0.787328660488, 1.93301963806, -0.21096418798, 0.703498184681, 0.933144032955}, --5
		{0.169966608286, 0.0252288486809, -0.0455424301326, 0.550313174725, 0.599951505661}, --10
		{0.576364576817, 1.93301963806, 0.576364576817, 0.873648881912, 0.799987673759}, --4
		{0.12442420423, 0.0252288486809, 0.12442420423, 0.589638411999, 0.567994236946}, --11
		{-0.210963919759, 1.93301963806, 0.787328720093, 0.967984199524, 0.605610132217}, --0
		{-0.0455423668027, 0.0252288486809, 0.169966608286, 0.610921740532, 0.522007882595}, --6
	}
	for _,d in pairs(vdata) do
		TexCoord(d[4],1 - d[5])
		Vertex(d[1],d[2],d[3])
	end
end

local function Base()
	local vdata= {
		{0.0, 0.0, 0.0, 0.733098506927, 0.265741109848}, --0
		{0.541657626629, 0.0706363543868, 0.541657626629, 0.856502175331, 0.0520000383258}, --1
		{0.739917933941, 0.0706363543868, -0.198260486126, 0.609695136547, 0.0520000010729}, --2
		{0.198260322213, 0.0706363543868, -0.739917933941, 0.486291617155, 0.265741109848}, --3
		{-0.541657626629, 0.0706363543868, -0.54165738821, 0.609695076942, 0.47948217392}, --4
		{-0.739917755127, 0.0706363543868, 0.198260694742, 0.856501996517, 0.47948217392}, --5
		{-0.198260217905, 0.0706363543868, 0.739917933941, 0.979905426502, 0.265741229057}, --6
		{0.541657626629, 0.0706363543868, 0.541657626629, 0.856502175331, 0.0520000383258}, --1
	}
	for _,d in pairs(vdata) do
		TexCoord(d[4],1 - d[5])
		Vertex(d[1],d[2],d[3])
	end
end


local blasts={}


function gadget:Initialize()
	mOSplash=CreateList(gl.BeginEnd, GL.TRIANGLE_STRIP,OuterSplash)
	mISplash=CreateList(gl.BeginEnd, GL.TRIANGLE_STRIP,InnerSplash)
	mBase=CreateList(gl.BeginEnd, GL.TRIANGLE_FAN,Base)
end

function gadget:DrawWorld()
	Texture("bitmaps/dirtblast.png")
	gl.DepthTest(GL.LEQUAL)
	PushMatrix()
		local f = GetGameFrame()
		for i,d in pairs(blasts) do
			local t=(f - d[5])/math.sqrt(d[4]/20)/20
			local width=d[4]*(1-(1-t)*(1-t)*(1-t)*(1-t))
			Color(1,1,1,math.min(1,2*(1-t)))
			PushMatrix()
				Translate(d[1],d[2],d[3])
				Rotate(d[6],0,1,0)
				Culling(BACK)
				PushMatrix()
					Scale(width,width,width)
					CallList(mBase)
				PopMatrix()
				PushMatrix()
					Translate(0,-(t*t)*d[4]*.85,0)
					Scale(width,width,width)
					--Scale(width,d[4]*(1-(1-t)*(1-t))*2,width)
					CallList(mISplash)
				PopMatrix()
				Culling(FRONT)
				PushMatrix()
					Translate(0,-(t*t)*d[4],0)
					Scale(width,width,width)
					--Scale(width,d[4]*(1-(1-t)*(1-t))*2,width)
					CallList(mOSplash)
				PopMatrix()
			PopMatrix()
			if t > 1 then
				blasts[i]=nil
			end
		end
		Culling(false)
	PopMatrix()
	Texture(false)
	Color(1,1,1,1)
end

local GetPositionLosState=Spring.GetPositionLosState
local GetSpectatingState=Spring.GetSpectatingState
local GetLocalAllyTeamID=Spring.GetLocalAllyTeamID
local IsPosInAirLos=Spring.IsPosInAirLos

function gadget:RecvFromSynced(name,x,y,z,size)
	if name=="dirtblast" then
		local alos=IsPosInAirLos(x,y,z,GetLocalAllyTeamID())
		local _,spec=GetSpectatingState()
		if alos or spec then
			table.insert(blasts, {
				x,y,z,size,GetGameFrame(),math.random(360)
			})
		end
	end
end

end
