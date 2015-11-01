
local Main = EmotePokerClient

local CARDSIZE = 64
local CARDWIDTH = CARDSIZE / 1.4
local CARDPAD = 8

local GOLD_ICON = "|TInterface/MONEYFRAME/UI-GoldIcon:0|t"

-------------------------------------------------------------------------------
local function SetNameColor( self, data )
	if not data.active then
		self.name:SetTextColor( 0.3, 0.3, 0.3 )
		return
	end
	
	if not Main.state.round_complete and Main.state.turn == self.index then
		self.name:SetTextColor( 0.05,1,0.09 )
		return
	end

	if data.acted then
		if data.folded then
			self.name:SetTextColor( 0.3, 0.3, 0.3 )
		else
			self.name:SetTextColor( 1,1,1 )
		end
	else
		self.name:SetTextColor( 0.1,0.4,0.9 )
	end

end

-------------------------------------------------------------------------------
local function Update( self, data )
	
	self.name:SetText( string.format( "%s", data.alias ))
	
	SetNameColor( self, data )
	
	info = string.format( "%s%s|nBet: %s", data.credit, GOLD_ICON, data.bet )
	
	if not Main.state.hand_complete then
		if data.folded then
			if not data.active then
				info = info .. " (OUT)" 
			else
				info = info .. " (FOLD)" 
			end
		end
			
	end
	self.info:SetText( info )
	
	if data.hand then
		Main:SetCardTexture( self.cards[1], data.hand[1] )
		Main:SetCardTexture( self.cards[2], data.hand[2] )
	else
		if data.name == UnitName( "player" ) and Main.cards then
			Main:SetCardTexture( self.cards[1], Main.cards[1] )
			Main:SetCardTexture( self.cards[2], Main.cards[2] )
		else
			if not data.active or data.folded then
				self.cards[1]:Hide()
				self.cards[2]:Hide()
			else
				Main:SetCardTexture( self.cards[1], 0 )
				Main:SetCardTexture( self.cards[2], 0 )
			end
		end
	end
	
	if Main.state.dealer == self.index then
		self.button:Show()
	else
		self.button:Hide()
	end
	
	SetPortraitTexture( self.face, data.name )
	
	self.frame:Show()
end

-------------------------------------------------------------------------------
local function Hide( self)
	self.frame:Hide()
end

-------------------------------------------------------------------------------
function Main:CreatePlayerFrame( index )
	local widget = { index = index }
	widget.cards = {}
	
	local f = CreateFrame( "Frame", nil, self.frame )
	f:SetSize( 100, 120 )
	
	f:SetPoint( "TOPLEFT", 40 + ((index-1) % 4) * 100, -140 - math.floor((index-1)/4) * 150 )
	
	widget.frame = f
	
	local card 
	
	local cardtop = -55
	
	card = f:CreateTexture()
	card:SetSize( CARDSIZE, CARDSIZE )
	card:SetPoint( "TOPLEFT", 20, cardtop  )
	self:SetCardTexture( card, 0 )
	widget.cards[1] = card
	
	card = f:CreateTexture(nil,nil,nil,1)
	card:SetSize( CARDSIZE, CARDSIZE )
	card:SetPoint( "TOPLEFT", 35, cardtop-10  )
	self:SetCardTexture( card, 0 )
	widget.cards[2] = card
	
	local text
	
	text = f:CreateFontString()
	text:SetPoint( "TOPLEFT", 28, -2 )
	text:SetFont( "Fonts\\ARIALN.TTF", 18, "OUTLINE" )
	widget.name = text
	
	text = f:CreateFontString()
	text:SetPoint( "TOPLEFT", 4, -28 )
	text:SetFont( "Fonts\\ARIALN.TTF", 12, "OUTLINE" )
	text:SetJustifyH( "LEFT" )
	widget.info = text
	
	local face = f:CreateTexture() 
	face:SetSize( 24, 24 )
	face:SetPoint( "TOPLEFT" )
	widget.face = face
	
	local button = f:CreateTexture()
	button:SetTexture( 0.95,0.45,0.09 )
	button:SetSize( 4,4 )
	button:SetPoint( "TOPLEFT" )
	button:Hide()
	widget.button = button
	
	widget.Update = Update
	widget.Hide = Hide
	
	return widget
end
