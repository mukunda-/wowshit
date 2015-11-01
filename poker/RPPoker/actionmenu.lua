local Main = RPPoker

local Menu

local function ResetAll()
	Main.UI:ConfirmAction( "Reset the system?", function() Main.Game:Reset() end )
end

local function CancelHand()
	Main.UI:ConfirmAction( "Cancel the current hand?", function() Main.Game:CancelHand() end )
end 

local function ShuffleDealer()
	Main.Game:ShuffleDealer()
end

-------------------------------------------------------------------------------
local function InitializeMenu( self, level )
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
	info.text    = "Actions"
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton( info, level )
	
	AddMenuButton( "Shuffle Dealer", ShuffleDealer )
	AddMenuButton( "Cancel Hand", CancelHand )
	AddMenuButton( "Reset All", ResetAll )
end

function Main:ShowActionsPopup()
	if not Menu then
		Menu = CreateFrame( "Button", "PokerActionsMenu", 
		                      UIParent, "UIDropDownMenuTemplate" )
		Menu.displayMode = "MENU"
	end
	
	UIDropDownMenu_Initialize( PokerActionsMenu, InitializeMenu )
	UIDropDownMenu_SetWidth( PokerActionsMenu, 100 )
	UIDropDownMenu_SetButtonWidth( PokerActionsMenu, 124 ) 
	UIDropDownMenu_JustifyText( PokerActionsMenu, "LEFT" )
	
	local x,y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	ToggleDropDownMenu( 1, nil, PokerActionsMenu, "UIParent", x / scale, y / scale )
	
end
