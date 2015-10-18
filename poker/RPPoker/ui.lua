local AceGUI = LibStub("AceGUI-3.0") 
local Main = RPPoker

-------------------------------------------------------------------------------

Main.UI = {
	playergroup = nil;
	players = {};
}

-------------------------------------------------------------------------------
function Main.UI:Init() 
 
	local f = AceGUI:Create( "Frame" )
	f:SetTitle( "RPPoker" )
	f:SetStatusText( "Status Bar" )
	f:SetLayout( "Flow" ) 
	 
	self.playergroup = AceGUI:Create( "InlineGroup" )
	self.playergroup:SetFullWidth( true )
	f:AddChild( self.playergroup )
	
	local button = AceGUI:Create( "Button" )
	button:SetText( "Add Player" )
	button:SetCallback( "OnClick", self.AddPlayerClicked )
	f:AddChild( button ) 
	
	local button = AceGUI:Create( "Button" )
	button:SetText( "Undo" )
	button:SetCallback( "OnClick", self.UndoClicked )
	f:AddChild( button ) 
	
	local button = AceGUI:Create( "Button" )
	button:SetText( "Redo" )
	button:SetCallback( "OnClick", self.RedoClicked )
	f:AddChild( button ) 
	
	local btn = AceGUI:Create( "Button" )
	f:AddChild( btn )
	
	self.frame = f
	
	self:CreateAddPlayerFrame()
end

-------------------------------------------------------------------------------
function Main.UI:CreateConfirmFrame()
	if self.confirm then return end
	self.confirm = {}
	
	local f = AceGUI:Create( "Frame" )
	f:SetTitle( "Confirm Action" )
	
	self.confirm.frame = f
	
	local text = AceGUI:Create( "Label" )
	text:SetFullWidth( true )
	f:AddChild( text )
	self.confirm.text = text
	
	local okay = AceGUI:Create( "Button" )
	okay:SetText( "Confirm" )
	okay:SetCallback( "OnClick", self.OnConfirmAction )
	self.confirm.okay = okay
end

-------------------------------------------------------------------------------
function Main.UI.OnConfirmAction()
	local self = Main.UI
	self.confirm.frame:Hide()
	
	if self.confirm.action then
		self.confirm.action()
	end
end

-------------------------------------------------------------------------------
function Main.UI:ConfirmAction( text, func )
	self.confirm.func = func
	self.confirm.text:SetText( text )
	self.confirm.frame:Show()
end

-------------------------------------------------------------------------------
function Main.UI:CreateAddPlayerFrame()
	if self.addplayer then return end
	
	local f = AceGUI:Create( "Frame" )
	f:SetLayout( "List" ) 
	f:SetTitle( "Add Player" )
	f:EnableResize( false )
	f:SetWidth( 400 )
	f:SetHeight( 200 )
	f:Hide()
	
	self.addplayer = {}
	self.addplayer.frame = f
	
	local text = AceGUI:Create( "Label" )
	text:SetText( "New Player" )
	f:AddChild(text)
	self.addplayer.name = text
	
	local text = AceGUI:Create( "EditBox" )
	text:SetLabel( "Alias" )
	text:SetText( "" )
	text:DisableButton(true)
	f:AddChild( text )
	self.addplayer.alias = text
	
	local text = AceGUI:Create( "EditBox" )
	text:SetLabel( "Credit" )
	text:SetText( 0 )
	text:DisableButton(true)
	f:AddChild( text )
	self.addplayer.credit = text
	
	local button = AceGUI:Create( "Button" )
	button:SetText( "Okay" )
	button:SetCallback( "OnClick", self.AddPlayerConfirm )
	f:AddChild( button )	
end

-------------------------------------------------------------------------------
function Main.UI:ShowAddPlayer( name )
	self.addplayer.name:SetText( name )
	
	local alias = name
	if TRP3_API then
		alias = TRP3_API.r.name( name )
	end
	
	self.addplayer.alias:SetText( alias )
	self.addplayer.credit:SetText( 0 )
	self.addplayer.frame:Show()
end

-------------------------------------------------------------------------------
function Main.UI:UpdatePlayerStatus()
	
	local layout_changed
	local count = 0
	for _,data in ipairs( Main.Game.players ) do 
		count = count + 1
		local p = self.players[count]
		if p == nil then
			p = AceGUI:Create( "PokerPlayerStatus" )
			self.playergroup:AddChild( p )
			self.players[count] = p
			layout_changed = true
		end
		p:UpdateInfo( data )
	end
	
	for i = count+1, #self.players do
		AceGUI:Release( self.players[i] )
		layout_changed = true
	end
	
	self.frame:DoLayout()
end

-------------------------------------------------------------------------------
function Main.UI.AddPlayerConfirm()
	local self = Main.UI
	
	local credit = tonumber( self.addplayer.credit:GetText() )
	local alias = self.addplayer.alias:GetText()
	if not credit or alias == "" then
		Main:Print( "Invalid input." )
		return
	end
	
	Main.Game:AddPlayer( name, alias, credit )
	self:UpdatePlayerStatus()
	
	self.addplayer.frame:Hide()
end

-------------------------------------------------------------------------------
function Main.UI.AddPlayerClicked()
	local self = Main.UI
	
	local name = UnitName( "target" )
	
	if not name or not UnitInParty( "target" ) then 
		Main:Print( "Must be targeting a party member." )
		return
	end
	
	if Main.Game:GetPlayer( name ) then
		Main:Print( "Player is already in the game." )
		return
	end
	
	self:ShowAddPlayer( name )
end

-------------------------------------------------------------------------------
function Main.UI.UndoClicked()
	local self = Main.UI
	Main.Game:Undo()
end

-------------------------------------------------------------------------------
function Main.UI.RedoClicked()
	local self = Main.UI
	Main.Game:Redo()
end

function Main.UI:UpdateAll()
	self:UpdatePlayerStatus()
end