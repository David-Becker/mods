function gadget:GetInfo()
	return {
		name = "Blob count display",
		desc = "Draws the blob counts for higher units",
		author = "KDR_11k (David Becker)",
		date = "2008-09-14",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

if gadgetHandler:IsSyncedCode() then
	return false
end

local red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE, CMD_EJECT = VFS.Include("LuaRules/Header/header.lua", nil, VFS.MOD)

local colors={
	red={1,.2,.2},
	green={.2,1,.2},
	blue={.2,.2,1},
	black={.2,.2,.2},
	ANY={1,1,1},
}

local GetVisibleUnits=Spring.GetVisibleUnits
local GetUnitDefID=Spring.GetUnitDefID
local PushMatrix=gl.PushMatrix
local Texture=gl.Texture
local Translate=gl.Translate
local Billboard=gl.Billboard
local Color=gl.Color
local TexRect=gl.TexRect
local Text=gl.Text
local PopMatrix=gl.PopMatrix
local GetUnitTeam=Spring.GetUnitTeam
local GetTeamColor=Spring.GetTeamColor
local GetUnitBasePosition=Spring.GetUnitBasePosition
local GetUnitHeight=Spring.GetUnitHeight
local GetCOBUnitVar=Spring.GetCOBUnitVar
local GetUnitLOSState=Spring.GetUnitLosState


function gadget:DrawWorld()
	local _,spec = Spring.GetSpectatingState()
	local ateam=Spring.GetLocalAllyTeamID()
	local maxBlob=SYNCED.maxBlob
	if not Spring.IsGUIHidden() then
		for _,u in ipairs(GetVisibleUnits()) do
			if spec or GetUnitLOSState(u,ateam).los then
				local ud = GetUnitDefID(u)
				if higherUnits[ud] then
					PushMatrix()
					Texture("bitmaps/statusArrow.tga")
					local x,y,z=GetUnitBasePosition(u)
					local h = GetUnitHeight(u)
					Translate(x,y+h,z)
					Billboard()
					local r,g,b = GetTeamColor(GetUnitTeam(u))
					Color(r,g,b,.4)
					TexRect(-15,30,15,0,true,true)
					for i,c in pairs(higherUnits[ud].contInv) do
						local col = colors[c]
						Color(col[1],col[2],col[3],1)
						Texture("bitmaps/statusBlob.tga")
						TexRect(-12,-5 + 10*i, -4,3+10*i,false, false)
						local blob=GetCOBUnitVar(u,i-1)
						if blob < maxBlob then
							Color(1,1,1,1)
						else
							Color(1,1,0,1)
						end
						Text(""..blob,0,-5 + 10*i,8,"ln")
					end
					PopMatrix()
				end
			end
		end
	end
end
