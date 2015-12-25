  
SurveyHunt = LibStub( "AceAddon-3.0" ):NewAddon( 
					"SurveyHunt", 
					"AceComm-3.0", 
					"AceEvent-3.0",
					"AceSerializer-3.0" )
					 

local Main = SurveyHunt
 
local FRAMEWIDTH = 400
local FRAMEHEIGHT = 300

local DIGCD = 3
local CHECKCD = 30
local DIGTHRESHOLD = 40

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
function Main:OnInitialize() 
	self:RegisterEvent( "CHAT_MSG_WHISPER", "OnWhisper" ) 
	self:LoadData()
	
	SLASH_SCH1 = "/sch"
	
	GHI_Comm().AddReceiveFunc( "SCH_DIG", OnGhiDig )
	GHI_Comm().AddReceiveFunc( "SCH_CHECK", OnGhiCheck )
end 

-------------------------------------------------------------------------------
function Main:OnEnable() 
	self:ShowFrame()
	self.frame:Hide()
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
		status:SetFont( "Fonts\\ARIALN.TTF", 14, "OUTLINE" )
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
	
	print( name )
	self:Dig( name, "addon" )
end

-------------------------------------------------------------------------------
function OnGhiCheck( name )
	if not UnitInParty( name ) then
		return
	end
	
	print( name )
end

-------------------------------------------------------------------------------
function Main:OnCommReceived( prefix, msg, dist, sender )

	sender = Ambiguate( sender, "none" )
	
	if prefix ~= "GHI2" then return end
	
	local data,data2 = self:Deserialize(msg)
	
	if not UnitInParty( sender ) then
		return
	end
	
	if prefix == "SURVEYHUNT" then
		
		if msg == "DIG" then
			self:Dig( sender, "addon" )
		elseif msg == "CHECK" then
			self:Check( sender, "addon" )
		end
		
	end 
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
function SetupPD( player )
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
			GHI_Comm().Send( "NORMAL", player, "SCH_DIG", "|cff0000ffThe shovel works, but the hunt hasn't started!" )
		end
		return
	end
	
	local pd = self.pdata
	SetupPD( player )
	
	if GetTime() - pd[player].digtime < DIGCD then
		return
	end
	
	pd[player].digtime = GetTime()
	
	local x,y = UnitPosition( player )
	
	for k,v in pairs( self.spots ) do
		if Distance2( v.x, v.y, x, y ) < DIGTHRESHOLD then
			v.found = player
			
			if response == "whisper" then
				SendChatMessage( "<You found \"" .. v.name .. "\"!> (Keep hunting, and claim the prize later from Tammy!)", "WHISPER", _, player )
			elseif response == "addon" then
				
				GHI_Comm().Send( "NORMAL", player, "SCH_DIG", "|cff00ff00You found \"" .. v.name .. "\"! |cff808080(Keep hunting, and claim the prize later from Tammy!)" )
			end
			
			return
		end
	end
	
	if response == "whisper" then
		SendChatMessage( "<There's nothing here!>", "WHISPER", _, player  )
	elseif response == "addon" then
		GHI_Comm().Send( "NORMAL", player, "SCH_DIG", "|cff808080There's nothing here!", "WHISPER" )
	end
end

-------------------------------------------------------------------------------
function Main:Check( player, response )
	if not self.on then 
	
		if response == "whisper" then
		
			SendChatMessage( "<The tracker works! But the hunt hasn't started.>", "WHISPER", _, player  )
		elseif response == "addon" then
		
			GHI_Comm().Send( "NORMAL", player, "SCH_CHECK", "|cff0000ffThe tracker works, but the hunt hasn't started!" )
		end
		
		return
	end
end

-------------------------------------------------------------------------------
function Main:AddSpot( name )
	local x,y = UnitPosition( "player" )
	table.insert( self.spots, { x = x, y = y, name = name } )
	
	self:UpdateStatusText()
	print( "SPOT ADDED" )
	
	self:ShowFrame()
	self:SaveData()
end

-------------------------------------------------------------------------------
function Distance2( x,y, x2,y2 )
	return (x2-x)^2+(y2-y)^2
end

-------------------------------------------------------------------------------
function Main:RemoveSpot()
	local x,y = UnitPosition( "player" )
	-- findclosest point
	
	local best
	local distance = 999999*999999
	
	for k,v in pairs( self.spots ) do
		if Distance2( v.x, v.y, x, y ) < distance then
			best = k
		end
	end
	
	if best then
		table.remove( self.spots, k )
		print( "SPOT REMOVED" )
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

	local result = "SCAVENGER HUNT STATUS|n"
	
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
	main.on = on
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
		Main:AddSpot( msg:sub(5) )
	elseif args[1] == "remove" then
		Main:RemoveSpot()
	elseif args[1] == "eraseall" then
		Main:EraseAll()
	elseif args[1] == "on" then
		Main:ActivateHunt( true )
	elseif args[1] == "off" then
		Main:ActivateHunt( false )
	end
end






