-- PokerPlayerStatus widget

local TYPE, VERSION = "PokerPlayerStatus", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= VERSION then return end

local Main = RPPoker

local g_menu = nil

print( "LOADED POKER PLAYER WIDGET" )

local function Control_OnClick(frame)
	
end

local function Control_OnEnter(frame)
	frame.hot:Show()
end

local function Control_OnLeave(frame)
	frame.hot:Hide()
end	


-------------------------------------------------------------------------------
local methods = {
	OnAcquire = function(self)
		self:SetHeight( 24 ) 
		self:SetFullWidth( true )
	end;
	
	UpdateInfo = function( self, player )
	
		self.frame.text_name:SetText( player.alias )
		self.frame.text_gold:SetText( "Credit: " .. player.credit .. " |TInterface/MONEYFRAME/UI-GoldIcon:0|t" )
		
		if Main.Game:CurrentPlayer() == player then
			self.frame.turn:Show()
		else
			self.frame.turn:Hide()
		end
		
	end;
}

local function Menu_RemovePlayer()
	
end

local function InitializeMenu()
	local info
	
	local function AddMenuButton( text, func )
		info = UIDropDownMenu_CreateInfo()
		info.text = text
		info.func = func
		info.notCheckable = true
		UIDropDownMenu_AddButton( info, level )
	end
	
	local function AddSeparator()
		info = UIDropDownMenu_CreateInfo()
		info.notClickable = true
		info.disabled = true
		UIDropDownMenu_AddButton( info, level )
	end

	info = UIDropDownMenu_CreateInfo()
	info.text    = "Player Actions:"
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton( info, level )

	AddMenuButton( "Remove Player", Menu_RemovePlayer )
	
	AddSeparator()
	
	AddMenuButton( L["Show Versions"], function() Delleren:WhoCommand() end )
	AddMenuButton( L["Open Configuration"], function() Delleren.Config:Open() end )
	
	AddSeparator()
	
	AddMenuButton( L["Close"], function() end )
end

-------------------------------------------------------------------------------
local function ShowMenu()
	if not g_menu then
		g_menu = CreateFrame( "Button", "PokerStatusMenu", 
		                      UIParent, "UIDropDownMenuTemplate" )
		g_menu.displayMode = "MENU"
	end
	 
	UIDropDownMenu_Initialize( PokerStatusMenu, InitializeMenu )
	UIDropDownMenu_SetWidth( PokerStatusMenu, 100 )
	UIDropDownMenu_SetButtonWidth( PokerStatusMenu, 124 ) 
	UIDropDownMenu_JustifyText( PokerStatusMenu, "LEFT" )
	
	local x,y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	ToggleDropDownMenu( 1, nil, g_menu, "UIParent", x / scale, y / scale )
end

-------------------------------------------------------------------------------
local function Constructor()
	local name = "PokerPlayerStatus" .. AceGUI:GetNextWidgetNum( TYPE )
	local frame = CreateFrame( "Frame", name, UIParent )
	frame:Hide()
	frame:EnableMouse(true)
	
	local hot = frame:CreateTexture( nil, "BACKGROUND" )
	frame.hot = hot
	hot:SetTexture( 0.1,0.1,0.3,1 )
	hot:SetBlendMode( "ADD" )
	hot:Hide()
	hot:SetAllPoints()
	
	local turn = frame:CreateTexture( nil, "BACKGROUND" )
	frame.turn = turn
	turn:SetTexture( 0.1, 0.05, 0.0, 1 )
	turn:SetBlendMode( "ADD" )
	turn:Hide()
	turn:SetAllPoints()
	
	local text = frame:CreateFontString()
	text:SetFont( "Fonts\\ARIALN.TTF", 12 )
	text:SetPoint( "LEFT", 10, 0 )
	text:SetText( "Unknown" )
	frame.text_name = text;
	
	local text = frame:CreateFontString()
	text:SetFont( "Fonts\\ARIALN.TTF", 12 )
	text:SetPoint( "LEFT", 150, 0 ) 
	frame.text_gold = text
	
	
	frame:SetScript( "OnEnter", Control_OnEnter )
	frame:SetScript( "OnLeave", Control_OnLeave )
	
	local widget = {
		frame = frame;
		type  = TYPE;	
	}
	
	for method, func in pairs(methods) do
		widget[method] = func
	end
	
	return AceGUI:RegisterAsWidget( widget )
end

-------------------------------------------------------------------------------
AceGUI:RegisterWidgetType( TYPE, Constructor, VERSION )
