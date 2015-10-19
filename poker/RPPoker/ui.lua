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
	
	self.pactions = {}
	
	local playeractions = AceGUI:Create( "InlineGroup" )
	playeractions:SetTitle( "Player actions" )
	playeractions:SetLayout( "Flow" )
	playeractions:SetFullWidth( true )
	f:AddChild( playeractions )
	self.pactions.frame = playeractions
	
	local e
	
	e = AceGUI:Create( "Button" )
	e:SetText( "Call" )
	e:SetWidth( 120 )
	e:SetCallback( "OnClick", self.PlayerActionCall )
	playeractions:AddChild( e )
	self.pactions.call = e
	
	e = AceGUI:Create( "Button" )
	e:SetText( "Bet" )
	e:SetWidth( 120 )
	e:SetCallback( "OnClick", self.PlayerActionBet )
	playeractions:AddChild( e )
	self.pactions.bet = e
	
	e = AceGUI:Create( "EditBox" )
	e:DisableButton( true )
	e:SetLabel( "Bet Amount" )
	e:SetWidth( 120 )
	playeractions:AddChild( e )
	self.pactions.betamt = e
	
	e = AceGUI:Create( "Button" )
	e:SetText( "Fold" )
	e:SetWidth( 120 )
	e:SetCallback( "OnClick", self.PlayerActionFold )
	playeractions:AddChild( e )
	self.pactions.fold = e
	
	e = AceGUI:Create( "Button" )
	e:SetText( "All-in" )
	e:SetWidth( 120 )
	e:SetCallback( "OnClick", self.PlayerActionAllIn )
	playeractions:AddChild( e )
	self.pactions.alllin = e
	
	self.frame = f
	 
end
 
-------------------------------------------------------------------------------
function Main.UI:ConfirmAction( desc, action )

	if not self.confirm then
		self.confirm = {}
		local f = AceGUI:Create( "Frame" )
		f:SetTitle( "Confirm Action" )
		f:EnableResize( false )
		f:SetWidth( 400 )
		f:SetHeight( 200 )
		f:SetLayout( "Flow" )
		self.confirm.frame = f
		
		local text = AceGUI:Create( "Label" )
		text:SetFullWidth( true )
		f:AddChild( text )
		self.confirm.text = text
		
		local okay = AceGUI:Create( "Button" )
		okay:SetText( "Confirm" )
		okay:SetWidth( 100 )
		f:AddChild(okay)
		okay:SetCallback( "OnClick", function()  
			Main.UI.confirm.frame:Hide()
			
			if Main.UI.confirm.action then 
				Main.UI.confirm.action()
			end 
		end)
		 
		local notokay = AceGUI:Create( "Button" )
		notokay:SetText( "Cancel" )
		notokay:SetWidth( 100 )
		f:AddChild(notokay)
		notokay:SetCallback( "OnClick", function()
			Main.UI.confirm.frame:Hide()
		end)
	end
	
	self.confirm.text:SetText( desc .. "|n".. "|n" )
	self.confirm.action = action
	self.confirm.frame:Show()
	self.confirm.frame:DoLayout()
end
 
-------------------------------------------------------------------------------
function Main.UI:ShowAddPlayer( name )

	if not self.addplayer then
		self.addplayer = {}
		local f = AceGUI:Create( "Frame" )
		f:SetLayout( "List" ) 
		f:SetTitle( "Add Player" )
		f:EnableResize( false )
		f:SetWidth( 400 )
		f:SetHeight( 200 ) 
		self.addplayer.frame = f
		
		local e
	
		e = AceGUI:Create( "Label" )
		f:AddChild( e )
		self.addplayer.name = e
		
		e = AceGUI:Create( "EditBox" )
		e:SetLabel( "Alias" )
		e:DisableButton( true )
		f:AddChild( e ) 
		self.addplayer.alias = e
		
		e = AceGUI:Create( "EditBox" )
		e:SetLabel( "Credit" )
		e:DisableButton(true)
		f:AddChild( e ) 
		self.addplayer.credit = e
		
		e = AceGUI:Create( "Button" )
		e:SetText( "Okay" )
		f:AddChild( e )
		
		e:SetCallback( "OnClick", function()
		
			local data = Main.UI.addplayer
			
			local credit = tonumber( data.credit:GetText() )
			local alias = data.alias:GetText()
			if not credit or alias == "" then
				Main:Print( "Invalid input." )
				return
			end
			
			credit =math.floor( credit )
			
			Main.Game:AddPlayer( name, alias, credit )
			self:UpdatePlayerStatus()
			
			f:Hide() 
		end)
    end
	
	local alias_default = name
	if TRP3_API then
		alias_default = TRP3_API.r.name( name )
	end
	
	self.addplayer.name:SetText( name )
	self.addplayer.alias:SetText( alias_default )
	self.addplayer.credit:SetText( 0 )
	self.addplayer.frame:Show()
end

-------------------------------------------------------------------------------
-- Show adjust credit dialog.
--
-- @param player Name of player to affect.
--
function Main.UI:AdjustCredit( player )

	if not self.adjustcredit then
		self.adjustcredit = {}
		local f = AceGUI:Create( "Frame" )
		f:SetLayout( "List" ) 
		f:SetTitle( "Adjust Credit" )
		f:EnableResize( false )
		f:SetWidth( 400 )
		f:SetHeight( 200 ) 
		self.adjustcredit.frame = f
		
		local e 
		e = AceGUI:Create( "Label" )
		f:AddChild(e)
		self.adjustcredit.name = e
		
		e = AceGUI:Create( "EditBox" )
		e:SetLabel( "Amount" )
		e:DisableButton(true)
		f:AddChild(e)
		self.adjustcredit.amount = e
		
		e = AceGUI:Create( "Button" )
		e:SetText( "Okay" )
		f:AddChild(e)
		e:SetCallback( "OnClick", function()
			local player = Main.UI.adjustcredit.player
			local amount = tonumber( Main.UI.adjustcredit.amount:GetText() )
			if not amount then
				Main:Print( "Invalid Input" )
				return
			end
			
			amount = math.floor( amount )
			
			Main.Game:AdjustCredit( player, amount )
			f:Hide()
		end)
		
		self.adjustcredit.frame:Hide()
	end
	
	local label = Main.Game:GetPlayerString( player ) 
	if not label then return end
	
	self.adjustcredit.player = player
	self.adjustcredit.name:SetText( label )
	self.adjustcredit.amount:SetText( 0 )
	self.adjustcredit.frame:Show()
end

-------------------------------------------------------------------------------
function Main.UI:UpdatePlayerStatus()
	
	local layout_changed
	
	if #self.players ~= #Main.Game.players then
		-- redo layout
		self.playergroup:ReleaseChildren()
		self.players = {}
		layout_changed = true
	end
	
	local index = 0
	for _,data in ipairs( Main.Game.players ) do 
		index = index + 1
		local p = self.players[index]
		if p == nil then
			p = AceGUI:Create( "PokerPlayerStatus" )
			self.playergroup:AddChild( p )
			self.players[index] = p
			layout_changed = true
		end
		p:UpdateInfo( data )
	end
	
	if layout_changed then
		self.frame:DoLayout()
	end
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

-------------------------------------------------------------------------------
function Main.UI:Update()
	self:UpdatePlayerStatus()
end

function Main.UI.PlayerActionBet()

end

function Main.UI.PlayerActionCall()

end

function Main.UI.PlayerActionFold()

end

function Main.UI.PlayerActionAllIn()

end

