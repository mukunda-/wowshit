 
local PROTOCOL = 1

EmotePokerClient = LibStub( "AceAddon-3.0" ):NewAddon( 
					"EmotePokerClient", 
					"AceComm-3.0", 
					"AceEvent-3.0",
					"AceSerializer-3.0" )

local Main = EmotePokerClient

Main.pframes = {}

local FRAMEWIDTH = 470
local FRAMEHEIGHT = 340

local CARDSIZE = 64
local CARDWIDTH = CARDSIZE / 1.4
local CARDPAD = 8
local GOLD_ICON = "|TInterface/MONEYFRAME/UI-GoldIcon:0|t"

function Main:CardValue( card )
	card = card - 1
	local number = math.floor(card / 4)
	local suit   = card - number*4
	number = number + 1
	suit   = suit + 1
	
	return number, suit
end

-------------------------------------------------------------------------------
function Main:OnInitialize()
	self:RegisterComm( "EPKSTATUS" ) 
	self:RegisterComm( "EPCARDS" ) 
	
	--self:RegisterEvent( "CHAT_MSG_WHISPER", "OnWhisper" )
end

-------------------------------------------------------------------------------
function Main:SetCardTexture( tex, card )
	tex:SetTexture( "Interface\\Addons\\EmotePokerClient\\Textures\\cards" )
	
	if card ~= 0 then
		local num, suit = self:CardValue( card )
		card = (suit-1) * 13 + num
	end
	
	local left = (card % 8) * 1/8
	local top = math.floor( card / 8 ) * 1/8
	tex:SetTexCoord( left, left + 1/8, top, top + 1/8 )
	tex:Show()
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
		
		self.frame.cards = {}
		-- table cards
		for i = 1,5 do
			local card = f:CreateTexture()
			card:SetSize( CARDSIZE, CARDSIZE )
			self.frame.cards[i] = card
			card:SetPoint( "TOPLEFT", FRAMEWIDTH/2 - CARDWIDTH/2 - 2 * (CARDWIDTH+CARDPAD) + (i-1) * (CARDWIDTH+CARDPAD), -40 )
			card:Hide()
		end
		
		local status = f:CreateFontString()
		status:SetPoint( "LEFT" )
		status:SetPoint( "RIGHT" )
		status:SetPoint( "BOTTOM", 0, 20 )
		status:SetHeight( 40 )
		status:SetFont( "Fonts\\ARIALN.TTF", 18, "OUTLINE" )
		status:SetText( "" )
		self.status = status
	end
	
	self.frame:Show()
end

-------------------------------------------------------------------------------
function Main:GetPlayerFrame( index )
	if not self.pframes[index] then
		local widget = self:CreatePlayerFrame( index )
		self.pframes[index] = widget
		
	end
	return self.pframes[index]
end

-------------------------------------------------------------------------------
function Main:SaveState( msg )
	
	self.state = {
	
		turn           = msg.tn;
		round          = msg.r;
		round_complete = msg.rc;
		hand_complete  = msg.hc;
		dealer         = msg.d;
		ante           = msg.an;
		smallblind     = msg.sb;
		bigblind       = msg.bb;
		set            = msg.b;
		noraise        = msg.rs;
		bet            = msg.b;
		table          = msg.t;
		players        = {};
	}
	
	for k,p in ipairs( msg.p ) do
		
		table.insert( self.state.players, {
			name   = p.n;
			alias  = p.al;
			credit = p.c;
			bet    = p.b;
			allin  = p.ai;
			folded = p.f;
			active = p.ac;
			acted  = p.z;
			hand   = p.h;
		})
	end
end

-------------------------------------------------------------------------------
function Main:UpdateStatus( msg )
	self:ShowFrame()
	
	self:SaveState( msg )
	
	for i = 1,5 do
		if msg.t[i] then
			self:SetCardTexture( self.frame.cards[i], msg.t[i] )
		else
			self.frame.cards[i]:Hide()
		end
	end
	
	local pot = 0
	local credit = 0
	
	local pcount = 0
	for k,p in ipairs( self.state.players ) do
		pcount = pcount + 1
		local pframe = self:GetPlayerFrame( pcount )
		pframe:Update( p )
		
		pot = pot + p.bet
		
		if p.name == UnitName( "player" ) then
			credit = p.credit
		end
	end
	
	local statustext = ""
	
	if self.state.players[self.state.turn] and self.state.players[self.state.turn].name == UnitName("player") and not self.state.round_complete then
		-- our turn!
		local p = self.state.players[self.state.turn]
		
		local actions = {}
		local ca = self.state.bet - p.bet
		if ca <= 0 then
			table.insert( actions, "Check" )
			table.insert( actions, "Bet" )
			
		else
			if p.credit <= ca then
				table.insert( actions, "All-In" )
			else
				table.insert( actions, string.format( "Call (%sg)", ca ))
				if not self.state.noraise then 
					table.insert( actions, string.format( "Raise", ca ))
				end
			end
			table.insert( actions, string.format( "Fold", ca ))
				
			
		end
		statustext = statustext .. string.format("Your turn. Actions: %s|n", table.concat( actions, " | " ))
	else
		
	end
	
	statustext = statustext .. string.format( "Credit: %sg | Current Bet: %sg | Pot %sg", 
								credit, self.state.bet, pot )
	
	self.status:SetText( statustext )
	
	self.frame:SetHeight( FRAMEHEIGHT + 150 * math.floor((pcount-1)/4) )
	
	for i = pcount+1, #self.pframes do
		self.pframes[i]:Hide()
	end
end

-------------------------------------------------------------------------------
local oodshown = false
local function ShowOutOfDate( v )
	if oodshown then return end
	oodshown = true
	
	local v = tonumber(v) or 0
	
	if v > PROTOCOL then
		print( "<EmotePokerClient> Your host has a newer version and you need to update this addon to see the poker table." )
	else
		print( "<EmotePokerClient> Your host is using an outdated version and is incompatble with you. You will not be able to see the poker table." )
	end
end

-------------------------------------------------------------------------------
function Main:OnCommReceived( prefix, packed_message, dist, sender )
	
	if prefix == "EPKSTATUS" then
		local result, ver, msg = self:Deserialize( packed_message )
		if result == false then return end -- bad message
		if ver ~= PROTOCOL then 
			ShowOutOfDate( ver )
			return 
		end
		
		self:UpdateStatus( msg ) 
	elseif prefix == "EPCARDS" then
		local result, ver, card1, card2 = self:Deserialize( packed_message )
		if result == false then return end
		if ver ~= PROTOCOL then 
			ShowOutOfDate( ver )
			return 
		end
		
		self.cards = { card1, card2 }
	end
end
--[[
function Main:OnWhisper( event, msg, sender )
	if not UnitInParty( sender ) then return end
	
	if msg:sub( 1, 4 ) ~= "<EP>" then return end
	
	local card1, card2 = string.match( msg, "<EP> Your cards: ([2-9JQKA]+) / ([2-9JQKA]+)" )
	print( card1, card2 )
end]]