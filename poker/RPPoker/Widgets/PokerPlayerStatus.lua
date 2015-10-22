-- PokerPlayerStatus widget

local TYPE, VERSION = "PokerPlayerStatus", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= VERSION then return end

local Main = RPPoker

local g_menu = nil
local g_context = nil

-------------------------------------------------------------------------------
local function Menu_RemovePlayer()
	local player = g_context.player
	
	local data = Main.Game:GetPlayer( player )
	if not data then return end
	
	Main.UI:ConfirmAction( 
		"Remove player: " .. player .. "/" .. data.alias .. "?", 
		function() 
			Main.Game:RemovePlayer( player )
			Main.UI:Update()
		end )
end

-------------------------------------------------------------------------------
local function Menu_AdjustCredit()
	Main.UI:AdjustCredit( g_context.player )
end

-------------------------------------------------------------------------------
local function Menu_ToggleBreak()
	Main.Game:TogglePlayerBreak( g_context.player )
end

-------------------------------------------------------------------------------
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
	info.text    = g_context.player
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton( info, level )

	
	AddMenuButton( "Toggle Break", Menu_ToggleBreak )
	AddSeparator()
	AddMenuButton( "Adjust Credit", Menu_AdjustCredit )
	 
	AddSeparator()
	 
	
	AddMenuButton( "Remove Player", Menu_RemovePlayer )
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
local function Control_OnEnter(frame)
	frame.hot:Show()
end

-------------------------------------------------------------------------------
local function Control_OnLeave(frame)
	frame.hot:Hide()
end	

-------------------------------------------------------------------------------
local function Control_OnClick( frame, button )

	if button == "RightButton" then
		g_context = frame.obj
		ShowMenu()
	end
end
 
-------------------------------------------------------------------------------
local methods = {
	OnAcquire = function(self)
		self:SetHeight( 24 ) 
		self:SetFullWidth( true )
	end;
	
	UpdateInfo = function( self, player )
	
		self.player = player.name
		
		local nametext = player.alias
		if not player.active then
			nametext = "(B) " .. nametext
		end
		
		self.frame.text_name:SetText( nametext )
		self.frame.text_gold:SetText( "Credit: " .. player.credit .. " |TInterface/MONEYFRAME/UI-GoldIcon:0|t" )
		self.frame.text_bet:SetText( "Bet: " .. player.bet .. " |TInterface/MONEYFRAME/UI-GoldIcon:0|t" )
		
		if Main.Game.hand_complete then
			self.frame.turn:Hide()
			
			self.frame.text_status:SetText( "" )
		else
			if Main.Game:CurrentPlayer() == player then
				self.frame.turn:Show()
			else
				self.frame.turn:Hide()
			end
			
			if player.folded then
				if player.bet == 0 then
					self.frame.text_status:SetText( "FOLDED" )
				else
					self.frame.text_status:SetText( "BREAK" )
				end
			elseif player.allin then
				self.frame.text_status:SetText( "ALL-IN" )
			elseif player.acted then
				self.frame.text_status:SetText( "ACTED" )
			else
				self.frame.text_status:SetText( "" )
			end
		end
		
		
	end;
}


-------------------------------------------------------------------------------
local function Constructor()
	local name = "PokerPlayerStatus" .. AceGUI:GetNextWidgetNum( TYPE )
	local frame = CreateFrame( "Button", name, UIParent )
	frame:Hide()
	frame:EnableMouse(true)
	frame:RegisterForClicks( "RightButtonUp" )
	
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
	
	local text = frame:CreateFontString()
	text:SetFont( "Fonts\\ARIALN.TTF", 12 )
	text:SetPoint( "LEFT", 300, 0 ) 
	frame.text_bet = text
	
	local text = frame:CreateFontString()
	text:SetFont( "Fonts\\ARIALN.TTF", 12 )
	text:SetPoint( "LEFT", 450, 0 ) 
	frame.text_status = text
	 
	frame:SetScript( "OnEnter", Control_OnEnter )
	frame:SetScript( "OnLeave", Control_OnLeave )
	frame:SetScript( "OnClick", Control_OnClick )
	 
	
	local widget = {
		frame = frame;
		type  = TYPE;	
		
		player = "";
	}
	
	for method, func in pairs(methods) do
		widget[method] = func
	end
	
	return AceGUI:RegisterAsWidget( widget )
end

-------------------------------------------------------------------------------
AceGUI:RegisterWidgetType( TYPE, Constructor, VERSION )
