local AceGUI = LibStub("AceGUI-3.0") 
local Main = RPPoker

-------------------------------------------------------------------------------

Main.UI = {
	playergroup = nil;
	players = {};
}

local Module = Main.UI

-------------------------------------------------------------------------------
function Main.UI:Init() 
 
	local f = AceGUI:Create( "Frame" )
	f:SetTitle( "EmotePoker" )
	f:SetStatusText( "Status Bar" )
	f:SetLayout( "Flow" ) 
	f:Hide()
	
	local e
	
	e = AceGUI:Create( "Label" )
	e:SetFullWidth( true )
	e:SetText( "Table Cards:" )
	e:SetFont( "Fonts\\ARIALN.TTF", 16 )
	f:AddChild( e )
	self.tablecards = e 
	
	self.playergroup = AceGUI:Create( "InlineGroup" )
	self.playergroup:SetFullWidth( true )
	f:AddChild( self.playergroup )
	
	local button 
	
	button = AceGUI:Create( "Button" )
	button:SetText( "Add Player" )
	button:SetCallback( "OnClick", self.AddPlayerClicked )
	button:SetWidth( 100 )
	f:AddChild( button ) 
	
	
	button = AceGUI:Create( "Button" )
	button:SetText( "Undo" )
	button:SetCallback( "OnClick", self.UndoClicked )
	button:SetWidth( 100 )
	f:AddChild( button ) 
	self.undo_button = button
	
	button = AceGUI:Create( "Button" )
	button:SetText( "Redo" )
	button:SetCallback( "OnClick", self.RedoClicked )
	button:SetWidth( 100 )
	f:AddChild( button ) 
	self.redo_button = button
	
	button = AceGUI:Create( "Button" )
	button:SetText( "Actions" )
	button:SetCallback( "OnClick", function() Main:ShowActionsPopup() end )
	button:SetWidth( 100 )
	f:AddChild( button )
	
	button = AceGUI:Create( "Button" )
	button:SetText( "Resend" )
	button:SetCallback( "OnClick", function() Main.Game:SendStatus() end )
	button:SetWidth( 100 )
	f:AddChild( button )
	 
	self.pactions = {}
	
	local playeractions = AceGUI:Create( "InlineGroup" )
	playeractions:SetTitle( "Player actions" )
	playeractions:SetLayout( "Flow" )
	playeractions:SetFullWidth( true )
	f:AddChild( playeractions )
	self.pactions.frame = playeractions
	
	
	e = AceGUI:Create( "Button" )
	e:SetText( "Call" )
	e:SetWidth( 90 )
	e:SetCallback( "OnClick", self.PlayerActionCall )
	playeractions:AddChild( e )
	self.pactions.call = e
	
	e = AceGUI:Create( "Button" )
	e:SetText( "Bet" )
	e:SetWidth( 90 )
	e:SetCallback( "OnClick", self.PlayerActionBet )
	playeractions:AddChild( e )
	self.pactions.bet = e
	
	e = AceGUI:Create( "EditBox" )
	e:DisableButton( true )
	e:SetLabel( "Bet Amount" )
	e:SetWidth( 90 )
	playeractions:AddChild( e )
	self.pactions.betamt = e
	
	e = AceGUI:Create( "Button" )
	e:SetText( "Fold" )
	e:SetWidth( 90 )
	e:SetCallback( "OnClick", self.PlayerActionFold )
	playeractions:AddChild( e )
	self.pactions.fold = e
	
	e = AceGUI:Create( "Button" )
	e:SetText( "All-in" )
	e:SetWidth( 90 )
	e:SetCallback( "OnClick", self.PlayerActionAllIn )
	playeractions:AddChild( e )
	self.pactions.allin = e
	
	e = AceGUI:Create( "Button" )
	e:SetText( "Next Round" )
	e:SetCallback( "OnClick", self.NextRoundClicked )
	f:AddChild( e )
	self.nextround = e
	
	self.options = {}
	local options = AceGUI:Create( "InlineGroup" )
	options:SetTitle( "Options" )
	options:SetLayout( "Flow" )
	options:SetFullWidth( true )
	f:AddChild( options )
	self.options.frame = options
	
	e = AceGUI:Create( "EditBox" )
	e:SetLabel( "Ante" )
	e:SetWidth( 80 )
	e:SetCallback( "OnEnterPressed", self.AnteEdited )
	options:AddChild( e )
	self.options.ante = e
	
	e = AceGUI:Create( "EditBox" )
	e:SetLabel( "Small Blind" )
	e:SetWidth( 80 )
	e:SetCallback( "OnEnterPressed", self.SmallBlindEdited )
	options:AddChild( e )
	self.options.smallblind = e
	
	e = AceGUI:Create( "EditBox" )
	e:SetLabel( "Big Blind" )
	e:SetWidth( 80 )
	e:SetCallback( "OnEnterPressed", self.BigBlindEdited )
	options:AddChild( e )
	self.options.bigblind = e
	
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
			
			credit = math.floor( credit )
			
			Main.Game:AddPlayer( data.playername, alias, credit )
			self:UpdatePlayerStatus()
			
			f:Hide() 
		end)
    end
	
	local alias_default = name
	if TRP3_API then
		alias_default = TRP3_API.r.name( name )
	end
	
	self.addplayer.playername = name
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
	self.adjustcredit.amount:SetText( "" )
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
function Main.UI:UpdateTableCards()
	local cards = ""
	for _, c in ipairs( Main.Game.table ) do
		if cards ~= "" then cards = cards .. " / " end
		cards = cards .. Main.Game:SmallCardName( c )
	end
	
	self.tablecards:SetText( "Table Cards: " .. cards )
end

-------------------------------------------------------------------------------
function Main.UI:Update()
	self:UpdatePlayerStatus()
	self:UpdateTableCards()
	
	self.undo_button:SetDisabled( not Main.Game.history[1] )
	self.redo_button:SetDisabled( not Main.Game.redo[1] )
	
	if not Main.Game.round_complete and Main.Game.round ~= "SHOWDOWN" then
	
		self.pactions.call:SetDisabled( false )
		self.pactions.bet:SetDisabled( false )
		self.pactions.betamt:SetDisabled( false )
		local p = Main.Game:CurrentPlayer()
		local ca = Main.Game:CallAmount(p)
		
		if ca == 0 then
			self.pactions.call:SetText( "Check" )
			self.pactions.bet:SetText( "Bet" )
			self.pactions.fold:SetDisabled( true )
		else
			
			self.pactions.call:SetText( "Call" )
			self.pactions.bet:SetText( "Raise" )
			self.pactions.fold:SetDisabled( false )
			
			if p.credit < ca then
				self.pactions.call:SetDisabled( true )
			end
			
			if p.credit <= ca or Main.Game.raises >= Main.Game.max_raises then
				self.pactions.bet:SetDisabled( true )
				self.pactions.betamt:SetDisabled( true )
			end
		end
	
		self.pactions.allin:SetDisabled( false )
	else
		self.pactions.call:SetDisabled( true )
		self.pactions.bet:SetDisabled( true )
		self.pactions.betamt:SetDisabled( true )
		self.pactions.fold:SetDisabled( true )
		self.pactions.allin:SetDisabled( true )
	end
	self.pactions.betamt:SetText("")
	
	if not Main.Game.round_complete then
		self.nextround:SetText( "Round in progress." )
		self.nextround:SetDisabled( true )
	else
		self.nextround:SetDisabled( false )
		if Main.Game.round == "" then
			self.nextround:SetText( "Deal" )
		elseif Main.Game.round == "PREFLOP" then
			self.nextround:SetText( "Deal Flop" )
		elseif Main.Game.round == "POSTFLOP" then
			self.nextround:SetText( "Deal Turn" )
		elseif Main.Game.round == "POSTTURN" then
			self.nextround:SetText( "Deal River" )
		elseif Main.Game.round == "POSTRIVER" then
			self.nextround:SetText( "Showdown" )
		elseif Main.Game.round == "ELIMINATED" then
			self.nextround:SetText( "Eliminated" )
		end
	end
	
	self.frame:SetStatusText( "ROUND: " .. Main.Game.round )
	
	self.options.ante:SetText( Main.Game.ante )
	self.options.smallblind:SetText( Main.Game.small_blind )
	self.options.bigblind:SetText( Main.Game.big_blind )
	
	if Main.Game.hand_complete then
		self.options.ante:SetDisabled( false )
		self.options.smallblind:SetDisabled( false )
		self.options.bigblind:SetDisabled( false )
	else
		self.options.ante:SetDisabled( true )
		self.options.smallblind:SetDisabled( true )
		self.options.bigblind:SetDisabled( true )
	end
	
	
end

-------------------------------------------------------------------------------
function Main.UI.PlayerActionCall()
	local p = Main.Game:CurrentPlayer()
	if Main.Game:CallAmount(p) == 0 then
		Main.Game:PlayerCheck()
	else
		Main.Game:PlayerCall()
	end
end

-------------------------------------------------------------------------------
function Main.UI.PlayerActionBet()
	local self = Main.UI
	
	local p = Main.Game:CurrentPlayer()
	local amt = tonumber(self.pactions.betamt:GetText())
	
	if not amt or amt <= 0 then
		Main:Print( "Invalid bet amount." )
		return
	end
	
	if Main.Game:CallAmount(p) == 0 then
		Main.Game:PlayerBet( amt )
	else
		Main.Game:PlayerRaise( amt )
	end
end

-------------------------------------------------------------------------------
function Main.UI.PlayerActionFold()
	Main.Game:PlayerFold()
end

-------------------------------------------------------------------------------
function Main.UI.PlayerActionAllIn()
	Main.Game:PlayerAllIn()
end

-------------------------------------------------------------------------------
function Main.UI.NextRoundClicked()
	
	if Main.Game.round == "" then
		Main.Game:DealHand()
	else
		Main.Game:NextRound()
	end
end

-------------------------------------------------------------------------------
function Module.AnteEdited( text )
	Main.Game:SetBettingOption( "ante", Main.UI.options.ante:GetText(), "Change Ante" )
end

-------------------------------------------------------------------------------
function Module.SmallBlindEdited( text )
	Main.Game:SetBettingOption( "small_blind", Main.UI.options.smallblind:GetText(), "Change Small Blind" )
end

-------------------------------------------------------------------------------
function Module.BigBlindEdited( text )
	Main.Game:SetBettingOption( "big_blind", Main.UI.options.bigblind:GetText(), "Change Big Blind" )
end
