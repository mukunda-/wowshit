  
SurveyHunt = LibStub( "AceAddon-3.0" ):NewAddon( 
					"SurveyHunt", 
					"AceComm-3.0", 
					"AceEvent-3.0",
					"AceSerializer-3.0" )
					 

local Main = SurveyHunt
 
local FRAMEWIDTH = 300
local FRAMEHEIGHT = 400

local DIGCD = 3
local CHECKCD = 5
local DIGTHRESHOLD = 50

local zone = "The Hinterlands"

Main.spots = {}
Main.pdata = {}

function Main:SaveData()
	SurveyHuntSaved = SurveyHuntSaved or {}
	SurveyHuntSaved.spots = self.spots
end

function Main:LoadData()
	SurveyHuntSaved = SurveyHuntSaved or {}
	self.spots = SurveyHuntSaved.spots or {}
end

-------------------------------------------------------------------------------
function GetPos( player )
	local y, x = UnitPosition( player )
	
	if not y then return 0,0 end
	
	y = -y 
	x = -x
	return x, y
end
  
-------------------------------------------------------------------------------
function Main:OnInitialize() 
	self:RegisterEvent( "CHAT_MSG_WHISPER", "OnWhisper" ) 
	self:LoadData()
	
	SLASH_SCH1 = "/sch"
	
end 

-------------------------------------------------------------------------------
function Main:OnEnable() 
	self:ShowFrame()
	self.frame:Hide()
	
	GHI_Comm().AddRecieveFunc( "SCH_DIG", OnGhiDig )
	GHI_Comm().AddRecieveFunc( "SCH_CHECK", OnGhiCheck )
end

-------------------------------------------------------------------------------
function Main:ShowFrame()

	if not self.frame then
		local f = CreateFrame( "Frame", nil, UIParent )
		self.frame = f
		
		f:SetBackdrop( {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background";  -- path to the background texture
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border";   -- path to the border texture
			tile = true;      -- true to repeat the background texture to fill the frame, false to scale it
			tileSize = 32;    -- size (width or height) of the square repeating background tiles (in pixels)
			edgeSize = 32;    -- thickness of edge segments and square size of edge corners (in pixels)
			insets = {        -- distance from the edges of the frame to those of the background texture (in pixels)
				left = 11;
				right = 12;
				top = 12;
				bottom = 11;
			};
		})
		
		f:SetWidth( FRAMEWIDTH )
		f:SetHeight( FRAMEHEIGHT )
		f:SetPoint( "CENTER" )
		f:EnableMouse(true)
		
		f:SetScript("OnMouseDown", function(self,button)
			if button == "LeftButton" then
				self:SetMovable( true )
				self:StartMoving() 
			end
		end)
		
		f:SetScript( "OnMouseUp", function(self)
			self:StopMovingOrSizing()
			self:SetMovable( false )
		end)
		
		local button = CreateFrame( "Button", nil, self.frame, "UIPanelCloseButton" )
		button:SetPoint( "TOPRIGHT", f )
		button:SetScript( "OnClick", function() f:Hide() end )
		  
		local status = f:CreateFontString()
		status:SetAllPoints()
		status:SetFont( "Fonts\\ARIALN.TTF", 8, "OUTLINE" )
		self.status = status
		
		self:UpdateStatusText()
	end
	
	self.frame:Show()
end

-------------------------------------------------------------------------------
function OnGhiDig( name )
	if not UnitInParty( name ) then
		return
	end
	
	Main:Dig( name, "addon" )
end

-------------------------------------------------------------------------------
function OnGhiCheck( name )
	if not UnitInParty( name ) then
		return
	end
	
	Main:Check( name, "addon" )
end 

-------------------------------------------------------------------------------
function Main:OnWhisper( event, msg, sender )
	sender = Ambiguate( sender, "none" )
	if not UnitInParty( sender ) then
		return
	end
	
	if msg:lower() == "dig" then
		self:Dig( sender, "whisper" )
	elseif msg:lower() == "check" then
		self:Check( sender, "whisper" )
	end
	
end

-------------------------------------------------------------------------------
function Main:SetupPD( player )
	if not self.pdata[player] then
		self.pdata[player] = {
			digtime = 0;
			checktime = 0;
		}
	end
end

-------------------------------------------------------------------------------
function Main:Dig( player, response )
	if not self.on then 
		
		if response == "whisper" then
			
			SendChatMessage( "<The shovel works! But the hunt hasn't started.>", "WHISPER", _, player  )
		elseif response == "addon" then
		
			GHI_Comm().Send( "ALERT", player, "SCH_DIGR", "|cffff33ffThe shovel works, but the hunt hasn't started!", "", "" )
		end
		return
	end
	
	local pd = self.pdata
	self:SetupPD( player )
	pd = pd[player]
	
	if GetTime() - pd.digtime < DIGCD then
		return
	end
	
	pd.digtime = GetTime()
	
	local x,y = GetPos( player )
	
	for k,v in pairs( self.spots ) do
		if not v.found and Distance2( v.x, v.y, x, y ) < DIGTHRESHOLD then
			v.found = player
			
			if response == "whisper" then
				SendChatMessage( "<You found [" .. v.name .. "]!> (Keep hunting, and claim the prize later from Tammy!)", "WHISPER", _, player )
			elseif response == "addon" then
				
				GHI_Comm().Send( "ALERT", player, "SCH_DIGR", "|cff00ff00You found |cffffffff[" .. v.name .. "]|cff00ff00! |cff808080(Keep hunting, and claim the prize later from Tammy!)", "", "" )
			end
			
			self:UpdateStatusText()
			self:SaveData()
			return
		end
	end
	
	if response == "whisper" then
		SendChatMessage( "<There's nothing here!>", "WHISPER", _, player  )
	elseif response == "addon" then
		GHI_Comm().Send( "ALERT", player, "SCH_DIGR", "|cff808080There's nothing here!", "", "" )
	end
	
end

-------------------------------------------------------------------------------
function Main:Check( player, response )
	if not self.on then 
	
		if response == "whisper" then
		
			SendChatMessage( "<The tracker works! But the hunt hasn't started.>", "WHISPER", _, player  )
		elseif response == "addon" then
		
			GHI_Comm().Send( "ALERT", player, "SCH_CHECKR", "|cffff33ffThe tracker works, but the hunt hasn't started!", "", "" )
		end
		
		return
	end
	
	local pd = self.pdata
	self:SetupPD( player )
	pd = pd[player]
	
	if GetTime() - pd.checktime < CHECKCD then
		local cd = math.ceil(CHECKCD - (GetTime() - pd.checktime))
		
		if response == "whisper" then
			SendChatMessage( "<You can't scan again for another " .. cd .. " seconds.>", "WHISPER", _, player )
		elseif response == "addon" then
			GHI_Comm().Send( "ALERT", player, "SCH_CHECKR", "|cff808080You can't scan again for another " .. cd .. " seconds.", "", "" )
		end
		
		return
	end
	
	pd.checktime = GetTime()
	
	local k = self:GetNearestSpot( player, true )
	
	if k then
		
		local x,y = self.spots[k].x, self.spots[k].y
		local x2,y2 = GetPos( player )
		
		
		x = x-x2
		y = y-y2
		
		local dist = x*x+y*y
		
		local dcol
		local dplain 
		
		if dist < 40 * 40 then
			dcol = "|cFF00FF00CLOSE|r"
			dplain = "CLOSE"
		elseif dist < 90 * 90 then
			dcol = "|cFFFFFF00MEDIUM|r"
			dplain = "MEDIUM"
		else
			dcol = "|cFFFF2000FAR|r"
			dplain = "FAR"
		end
		
		
		local angle = math.atan2( y, x )
		if angle < 0 then angle = math.pi * 2 + angle end
		local p = math.pi * 2 / 8
		angle = angle + p / 2
		if angle > math.pi*2 then angle = angle - math.pi*2 end
		local index = math.floor(angle / p)
		
		local directions = { "EAST", "SOUTHEAST", "SOUTH", "SOUTHWEST", "WEST", "NORTHWEST", "NORTH", "NORTHEAST", "EAST" }
		local direction = directions[index+1]
	
		
		if response == "whisper" then
			SendChatMessage( "<The tracker reads, \"RANGE: " .. dplain .. " || DIRECTION: " .. direction .. "\">", "WHISPER", _, player  )
		elseif response == "addon" then
			GHI_Comm().Send( "ALERT", player, "SCH_CHECKR", "|cff80ffffThe tracker reads, \"RANGE: " .. dcol .. "|cff80ffff | DIRECTION: |cffffffff" .. direction .. "|cff80ffff\"", "", "" )
		end
		
	else
		
		if response == "whisper" then
			SendChatMessage( "<There's no more treasure! Return to base!>", "WHISPER", _, player  )
		elseif response == "addon" then
			GHI_Comm().Send( "ALERT", player, "SCH_CHECKR", "|cff808080There's no more treasure! Return to base!", "", "" )
		end
	end
	
end

-------------------------------------------------------------------------------
function Main:AddSpot( msg )
	
	local x,y,name = string.match( msg, "add (-?%d+) (-?%d+) (.+)" )
	if not x then
		x,y = GetPos( "player" )
		name = string.sub(msg,5)
	end
	
	if name == "" then
		print( "NAME MISSING!" )
		return
	end
	
	table.insert( self.spots, { x = x, y = y, name = name } )
	
	self:UpdateStatusText()
	
	print( string.format("/sch add %d %d %s", x, y, name)  )
	
	self:ShowFrame()
	self:SaveData()
end

-------------------------------------------------------------------------------
function Distance2( x,y, x2,y2 )
	return (x2-x)^2+(y2-y)^2
end

-------------------------------------------------------------------------------
function Main:GetNearestSpot( player, unfound )
	local x,y = GetPos( player )
	-- findclosest point
	
	local best
	local distance = 999999*999999
	
	for k,v in pairs( self.spots ) do
		local d = Distance2( v.x, v.y, x, y )
		if d < distance then 
			if not v.found or not unfound then
				best = k
				distance = d
			end
		end
	end
	
	if best then 
		return best
	end
	
	return  nil
end

-------------------------------------------------------------------------------
function Main:RemoveSpot( index )

	if not index then
		index = self:GetNearestSpot( "player" )
	end
	
	if index then
		
		if self.spots[index] then
			table.remove( self.spots, index )
			print( "SPOT REMOVED" )
		end
		
	end
	
	self:ShowFrame()
	self:UpdateStatusText()
	self:SaveData()
end

-------------------------------------------------------------------------------
function Main:EraseAll()
	self.spots = {}
	print( "ALL SPOTS CLEARED! SORRY!" )
	
	self:UpdateStatusText() 
end

-------------------------------------------------------------------------------
function Main:UpdateStatusText()

	local result = "SCAVENGER HUNT STATUS " .. (self.on and "(ACTIVE)" or "(INACTIVE)") .. "|n"
	
	for k,v in ipairs( self.spots ) do
		local color
		if v.found then
			color = "|cff00ff00"
		else
			color = "|cffeeeeee"
		end
		
		local text = string.format( "%s%d - [%d, %d] - %s - %s|r|n",
			color, k, v.x, v.y, v.name, v.found or "NOT FOUND" )
			
		result = result .. text
	end
	
	self.status_text = result
	self.status:SetText( self.status_text )
end

-------------------------------------------------------------------------------
function Main:ActivateHunt( on )
	self.on = on
	if on then
		print( "SURVEY HUNT ACTIVATED" )
	else
		print( "SURVEY HUNT DEACTIVATED" )
	end
	self:ShowFrame()
	self:UpdateStatusText()
	self:SaveData()
end

function Main:Unclaim( index )
	index = tonumber(index)
	if not index then return end
	
	if self.spots[index] then
	
		self.spots[index].found = nil
		
		self:ShowFrame()
		self:UpdateStatusText()
		self:SaveData()
		print( "SPOT UNCLAIMED" )
		return
	end
	
	print( "UNKNOWN SPOT", index )
end

-------------------------------------------------------------------------------
function SlashCmdList.SCH( msg )

	local args = {}
	
	for i in string.gmatch( msg, "%S+" ) do
		table.insert( args, i )
	end
	
	if args[1] == "show" then
		Main:ShowFrame()
	elseif args[1] == "add" then
		Main:AddSpot( msg )
	elseif args[1] == "remove" then
		Main:RemoveSpot( args[2] )
	elseif args[1] == "eraseall" then
		Main:EraseAll()
	elseif args[1] == "on" then
		Main:ActivateHunt( true )
	elseif args[1] == "off" then
		Main:ActivateHunt( false )
	elseif args[1] == "unclaim" then
		Main:Unclaim( args[2] )
	end
end






