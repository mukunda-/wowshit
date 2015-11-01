local Main = RPPoker
local PROTOCOL = 1

-------------------------------------------------------------------------------
Main.Game = {
 
	history = {};
	redo    = {};
	
	sending_status = false;
	status_time = 0;
}

local DEFAULT_STATE = {
	players = {};
	
	-- player, index is the seat number
	--   name    character name
	--   alias   roleplay name
	--   credit  money remaining
	--   hand    two cards (hole)
	--   rank    the rank of their hand, filled in at the showdown.
	--   bet     how much money they bet in the current hand
	--   acted   they have acted during the current betting round
	--   allin   if they are all in for the hand
	--   folded  if they are folded for the rest of the hand
	--   active  if they are sitting at the table.
	--   show    if they are showing their hand

-- nil assignments are just for documentation purpose

	dealer      = 1;
--	button_icon = nil;
--	turn_icon   = nil;

-- TODO; copy these from config on game start
	ante        = 0;
	small_blind = 5;
	big_blind   = 10;
	multiplier  = 0; -- init to 1.0?

	deck        = {};

	round          = ""; -- the round of the current hand, 
						  -- may be "PREFLOP", "POSTFLOP", 
						  -- "POSTTURN", "POSTRIVER" or "SHOWDOWN"
	round_complete = true; -- if the current betting round is complete
						  -- and waiting for confirmation to continue to
						  -- the next round
						  
	hand_complete  = true; -- if all rounds in a hand are completed and
						   -- ready to start a new hand
 
	turn = 1;            -- whose turn is it

	pot  = 0;              -- total amount of credit in the pot (and side pots)
	bet  = 0;              -- current bet

	raises = 0;            -- number of times the bet was raised in the round
						   -- capped by max_raises in config

	table  = {};           -- community cards
	
	riverbet = nil;
	
	history_note = "";
	
}

-------------------------------------------------------------------------------
function Main.Game:LoadState( state )
	for k, v in pairs( state ) do
		self[k] = v
	end
end

-------------------------------------------------------------------------------
local state_keys = {
	"players", "dealer", "ante", "small_blind",
	"big_blind", "multiplier", "deck", "state",
	"round", "round_complete", "hand_complete",
	"turn", "pot", "bet", "raises", "table",
	"history_note", "riverbet"
}

local NUM_HISTORY_ENTRIES = 10
local GOLD_ICON = "|TInterface/MONEYFRAME/UI-GoldIcon:0|t"
  
-------------------------------------------------------------------------------
Main.CARD_NAMES = { "Ace", "Two", "Three", "Four", "Five", "Six", "Seven", 
                       "Eight", "Nine", "Ten", "Jack", "Queen", "King" }
Main.CARD_SUITS = { "Clubs", "Diamonds", "Hearts", "Spades" }

Main.SMALL_CARD_NAMES = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }
Main.SMALL_CARD_SUITS = { "c", "d", "h", "s" }

-------------------------------------------------------------------------------
Main.RANKS = {
	ROYAL_FLUSH    = 9;
	STRAIGHT_FLUSH = 8;
	FOUR_KIND      = 7;
	FULL_HOUSE     = 6;
	FLUSH          = 5;
	STRAIGHT       = 4;
	THREE_KIND     = 3;
	TWO_PAIR       = 2;
	ONE_PAIR       = 1;
	HIGH_CARD      = 0;
}

-------------------------------------------------------------------------------
-- Returns a comma separated list of entries from an array as a string.
--
local function CommaList( list )
	local text = ""
	for _,v in ipairs( list ) do
		if text ~= "" then
			text = text .. ", "
		end
		text = text .. v
	end
	return text
end

-------------------------------------------------------------------------------
-- Returns a comma separated list of entries from an array as a string with
-- 'and' as the last separator.
--
local function CommaAndList( list )
	
	local text = ""
	for k,v in ipairs( list ) do
		if text ~= "" then
			if k == #list then
				text = text .. " and "
			else
				text = text .. ", "
			end
		end
		text = text .. v
	end
	return text
end

-------------------------------------------------------------------------------
local function CopyTable( tbl )
	local copy = {}
	for k,v in pairs( tbl ) do 
		if type(v) == "table" then
			copy[k] = CopyTable(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- NOTE THIS FREE LINE HERE!
Main.Game:LoadState( CopyTable(DEFAULT_STATE) )

-------------------------------------------------------------------------------
function Main.Game:CopyState()

    local copy = {}
	
	for k, v in pairs( state_keys ) do
		if type(self[v]) == "table" then
			copy[v] = CopyTable( self[v] )
		else
			copy[v] = self[v]
		end
	end
	
    return copy
end


-------------------------------------------------------------------------------
function Main.Game:SaveState()
	Main.Config.db.char.state = self:CopyState()
	
	self:SendStatus()
end

-------------------------------------------------------------------------------
function Main.Game:PushHistory( note )
	self.redo = {} -- reset redo stack
	
	self.history_note = note
	table.insert( self.history, 1, self:CopyState() ) 
	
	while self.history[NUM_HISTORY_ENTRIES+1] do
		table.remove( self.history, NUM_HISTORY_ENTRIES+1 )
	end
end

-------------------------------------------------------------------------------
function Main.Game:Undo()
	local state = self.history[1]
	if not state then 
		Main:Print( "Cannot undo further." )
		return 
	end
	table.remove( self.history, 1 )
	table.insert( self.redo, 1, self:CopyState() )
	self:LoadState( state )
	Main.UI:Update()
	
	Main:Print( "Undid: " .. self.history_note )
end

-------------------------------------------------------------------------------
function Main.Game:Redo()
	local state = self.redo[1]
	if not state then
		Main:Print( "Cannot redo further." )
		return
	end
	
	Main:Print( "Redid: " .. self.history_note )
	table.remove( self.redo, 1 )
	table.insert( self.history, 1, self:CopyState() )
	self:LoadState( state )
	Main.UI:Update()
	
end

-------------------------------------------------------------------------------
-- Loads a new shuffled deck.
--
function Main.Game:NewDeck()
	self.deck = {}
	
	-- insert 52 cards.
	for i = 1,52 do
		table.insert( self.deck, i )
	end
	
	-- shuffle
	for i = 52,2,-1 do
		local j = math.random( 1, i )
		local k = self.deck[i]
		
		self.deck[i] = self.deck[j]
		self.deck[j] = k
	end
end

-------------------------------------------------------------------------------
-- Draws a card from the deck.
--
-- If there is no deck or the previous deck has run out of cards, this
-- also calls NewDeck.
--
-- @returns card index.
--
function Main.Game:DrawCard()
	if self.deck[1] == nil then self:NewDeck() end
	
	local a = self.deck[1]
	table.remove( self.deck, 1 )
	return a
end

-------------------------------------------------------------------------------
-- Give a card to the current player.
--
-- Errors if they already have 2 cards.
--
-- @param player Player to give the card to. Defaults to CurrentPlayer()
-- @returns true if a card was given, false if the player is folded.
--
function Main.Game:DealCard( player )

	local p = player or self:CurrentPlayer()
	
	if p.folded then return false end -- (player is taking a break.)
	
 	table.insert( p.hand, self:DrawCard() )
end

-------------------------------------------------------------------------------
-- Initialize a new player table.
--
function Main.Game:CreatePlayer( name, alias, credit )
	return {
		name   = name;
		alias  = alias or name;
		credit = credit or 0;
		hand   = {}; -- aka hole
		folded = true;
		allin  = false;
		acted  = true;
		bet    = 0;
		male   = UnitSex( name ) == 2;
--		pot    = 0;
		active = true;
	}
end

-------------------------------------------------------------------------------
function Main.Game:TogglePlayerBreak( name )
	local p = self:GetPlayer(name)
	if not p then return end
	if not self.hand_complete then 
		Main:Print( "Cannot switch during a hand." )
		return
	end
	p.active = not p.active
	
	Main.UI:UpdatePlayerStatus()
	self:SaveState()
end

-------------------------------------------------------------------------------
-- Get the player whose turn is active
--
function Main.Game:CurrentPlayer()
	return self.players[self.turn]
end

-------------------------------------------------------------------------------
-- Increment the turn to the next player that isn't folded.
--
-- @returns false if there are no players remaining.
--
function Main.Game:NextTurn()
	local t = self.turn
	for i = 1, #self.players do
		self.turn = self.turn + 1
		if self.players[self.turn] == nil then self.turn = 1 end
		if not self.players[self.turn].folded then
			return true
		end
	end
	
	self.turn = t
	return false -- no other players remaining
end

-------------------------------------------------------------------------------
-- Set the current turn.
--
function Main.Game:SetTurn( index )
	self.turn = index
	
	assert( self.players[self.turn] ~= nil 
	        and not self.players[self.turn].folded )
end

-------------------------------------------------------------------------------
function Main.Game:GetPlayer( name )
	for k,v in pairs(self.players) do
		if v.name == name then return v, k end
	end
end

-------------------------------------------------------------------------------
-- Add a new player to the poker table.
--
-- @param name Name of player.
--
function Main.Game:AddPlayer( name, alias, credit ) 

	for k,v in pairs(self.players) do

		if v.name == name then return end -- player already added
	end

	Main.Game:PushHistory( "Add Player" )
	
	table.insert( self.players, self:CreatePlayer(name, alias, credit) )
	
	Main:Print( "Added player: " .. alias .. " (" .. name .. ")"
                .. " Credit: " .. credit .. GOLD_ICON )
	
	Main.Game:SaveState()
end

-------------------------------------------------------------------------------
-- Remove a player from the poker table.
--
-- @param name Name of player.
--
function Main.Game:RemovePlayer( name )
	for k,v in pairs(self.players) do
		if v.name == name then 
			Main.Game:PushHistory( "Remove Player" )
			table.remove( self.players, k ) 
			Main:Print( "Removed player: " .. v.alias .. " (" .. name .. ")"
                .. " Credit: " .. v.credit .. GOLD_ICON )
			Main.Game:SaveState()
			return
		end
	end
	
end

-------------------------------------------------------------------------------
-- Reset the table.
--
function Main.Game:ResetGame()
	--self.dealer = math.random( 1, #self.players )
	self.pot    = 0
	
	self.ante        = 0
	self.small_blind = 5
	self.big_blind   = 10
	self.multiplier  = 1
	self.max_raises  = Main.Config.db.profile.max_raises
	
end

-------------------------------------------------------------------------------
-- Returns the name of a card.
--
function Main.Game:CardName( card )
	local number, suit = self:CardValue( card )
	
	return Main.CARD_NAMES[number] .. " of " .. Main.CARD_SUITS[suit]
end

function Main.Game:SmallCardName( card )
	local number, suit = self:CardValue( card )
	return Main.SMALL_CARD_NAMES[number] .. Main.SMALL_CARD_SUITS[suit]
end

-------------------------------------------------------------------------------
-- Parses a card value.
--
-- @param card      Card value (1-52).
-- @param aces_high Number aces as 14 instead of 1.
-- @returns Number of card, Suit of card
--
function Main.Game:CardValue( card, aces_high )
	card = card - 1
	local number = math.floor(card / 4)
	local suit   = card - number*4
	number = number + 1
	suit   = suit + 1
	
	if aces_high and number == 1 then number = 14 end
	
	return number, suit
end

-------------------------------------------------------------------------------
-- Tell a player what cards they have
--
-- @param player Player data.
--
function Main.Game:TellCards( player )
	 
	if not player.hand[1] then return end
	
	local msg = string.format( "<EP> Your cards: %s / %s (%s, %s). Credit: %dg",
							   self:SmallCardName( player.hand[1] ),
							   self:SmallCardName( player.hand[2] ),
							   self:CardName( player.hand[1] ), 
							   self:CardName( player.hand[2] ),
							   player.credit )
	
	SendChatMessage( msg, "WHISPER", _, player.name )
	Main:SendCommMessage( "EPCARDS", 
		Main:Serialize( PROTOCOL, player.hand[1], player.hand[2] ), 
		"WHISPER", player.name )
end

-------------------------------------------------------------------------------
function Main.Game:TellActions()
	local p = self:CurrentPlayer()
	
	local msg = "<EP> CREDIT: " .. p.credit .. "g || ACTIONS: "
	
	local actions = {}
	
	local ca = self:CallAmount(p)
	if ca == 0 then
		table.insert( actions, "Check" )
		table.insert( actions, "Bet" )
	else
		
		if p.credit <= ca then
			table.insert( actions, "All-In" )
		else
			table.insert( actions, string.format( "Call (%sg)", ca ) )
			
			if self.raises < self.max_raises then
				table.insert( actions, "Raise" )
			end
		end
		
		table.insert( actions, "Fold" )
	end
	
	msg = msg .. CommaList( actions ) 
	
	Main:UpdatePlayerRank( p )
	
	if Main:RankIndex( p.rank ) >= 1 then
		msg = msg .. " || You have " .. Main:FormatRank( p.rank ) .. "."
	end
	
	SendChatMessage( msg, "WHISPER", _, p.name )
end

-------------------------------------------------------------------------------
-- Add a bet from a player to the pot.
--
-- If they have insufficient funds then it marks them as all-in and
-- bets as much as they have.
--
function Main.Game:AddBet( player, amount, noraise )
	
	-- player goes all in if they cant afford the bet
	-- take care to not allow players to bet higher than they own
	-- the clipping is only for antes and blinds
	
	
	if player.credit < amount then
	
		amount = player.credit
		player.allin = true
		player.acted = true
	end
	
	player.bet = player.bet + amount
	
	if not noraise then
		self.bet = math.max( self.bet, player.bet )
	end
	
	player.credit = player.credit - amount
	
	if player.credit == 0 then 
		player.allin = true
		player.acted = true
	end
	
end

-------------------------------------------------------------------------------
function Main.Game:Refund( player, amount )
	player.credit = player.credit + amount
	player.bet = player.bet - amount
	if player.credit > 0 then
	
		player.allin = false
	end
	
	Main:PartyPrint( "%s was refunded %sg since nobody else could match their bet.", player.alias, amount )
	
	-- reset the bet cap, not sure if this is necessary.
	self.bet = 0
	for _,p in pairs( self.players ) do
		self.bet = math.max( p.bet )
	end
end

-------------------------------------------------------------------------------
-- Deal cards.
--
function Main.Game:PlayerDealCards() 
	assert( self.turn == self.dealer )
	
	local x = self.dealer
	
	for i = 1,#self.players*2 do
		x = x + 1
		if x > #self.players then x = 1 end
		
		if not self.players[x].folded then
			self:DealCard( self.players[x] )
		end
	end
end

-------------------------------------------------------------------------------
-- Ante up for all players.
--
function Main.Game:PlayerAnteUp()

	if self.ante > 0 then
		for _,p in pairs(self.players) do
		
			if not p.folded then
				self:AddBet( p, self.ante )
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Bet the small blind.
--
function Main.Game:PlayerBetSmallBlind()
	local p = self:CurrentPlayer()
	self:AddBet( self:CurrentPlayer(), self.small_blind )
end

-------------------------------------------------------------------------------
-- Bet the big blind.
--
function Main.Game:PlayerBetBigBlind()
	
	local p = self:CurrentPlayer()
	self:AddBet( self:CurrentPlayer(), self.big_blind )
end

-------------------------------------------------------------------------------
function Main.Game:AnnounceTurn()
	local p = self:CurrentPlayer()
	
	local actions = ""
	--local text = string.format( "%s's turn. Actions: 
end

-------------------------------------------------------------------------------
-- Returns the amount of players that aren't folded.
--
function Main.Game:ActivePlayers() 
	local count = 0
	for _,p in pairs(self.players) do
		if not p.folded then
			count = count + 1 
		end
	end
	return count
end

-------------------------------------------------------------------------------
-- Returns true if no more players can perform actions during the hand.
--
function Main.Game:CheckNoActionsLeft() 
	local count = 0
	
	local found
	
	for _,p in pairs(self.players) do
		if not p.folded and not p.allin then
		
			found = p
			if self:CallAmount(p) ~= 0 then 
				-- this player hasn't matched the bet yet, so they
				-- need to act.
				return false 
			end
			count = count + 1
		end
	end
	
	if count < 2 then
		-- the round should end
		for _,p in pairs( self.players ) do
			p.acted = true
		end
		return true
	end
	
end

-------------------------------------------------------------------------------
-- If there's only one player remaining that can act (the rest are all-in or
-- folded), then make them check.
--
function Main.Game:AutoCheck()
	local player = self:CurrentPlayer()
	
	if self:CallAmount(player) > 0 then 
		-- they haven't matched the bet yet
		return false 
	end
	
	local count = 0
	for _,p in pairs( self.players ) do
		if p ~= player and not p.folded and not p.allin then
			-- there is another player that can act
			return false
		end
	end
	
	player.acted = true
	return true
end

-------------------------------------------------------------------------------
function Main.Game:CallAmount( player )
	return self.bet - player.bet
end

-------------------------------------------------------------------------------
-- Reset the "acted" state for each player, do this after the 
-- bet is raised.
--
function Main.Game:ResetActed()
	for k,v in pairs(self.players) do
		
		if not v.folded and not v.allin then
			v.acted = false
		end
	end
end

-------------------------------------------------------------------------------
-- Player action: Call
--
function Main.Game:PlayerCall()
	local p = self:CurrentPlayer()
	assert( not p.folded )
	assert( not p.acted )
	
	if self:CallAmount(p) == 0 then
		Main:Print( "Player must check, not call." )
		return
	end
	
	if p.credit < self:CallAmount(p) then
		Main:Print( "Insufficient credit." )
		return
	end
	
	self:PushHistory( "Player Call" )
	
	p.acted = true
	self:AddBet( p, self.bet - p.bet )
	
	self:ContinueBettingRound()
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
-- Player action: Check
--
function Main.Game:PlayerCheck()
	local p = self:CurrentPlayer()
	assert( not p.folded )
	assert( not p.acted )
	
	if self.round_complete then	
		Main:Print( "The round has ended." )
		return
	end	
	
	if self:CallAmount(p) ~= 0 then
		Main:Print( "Check not allowed." )
		return
	end
	
	self:PushHistory( "Player Check" )
	
	p.acted = true
	
	self:ContinueBettingRound()
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
-- Player action: Bet
--
-- @param amount Amount to add to the bet, minimum is the big blind.
--
function Main.Game:PlayerBet( amount )
	local p = self:CurrentPlayer()
	assert( not p.folded )
	assert( not p.acted )
	
	if self.round_complete then	
		Main:Print( "The round has ended." )
		return
	end	
	
	if self:CallAmount(p) ~= 0 then
		Main:Print( "Player must raise, not bet." )
		return
	end
	
	if amount < self.big_blind then
		Main:Print( "Must bet at least the big blind amount." )
		return
	end
	
	if amount > p.credit then
		Main:Print( "Insufficient funds." )
		return
	end
	
	self:PushHistory( "Player Bet" )
	
	if self.round == "POSTRIVER" and not self.riverbet then
		self.riverbet = self.turn
		
	end
	self:ResetActed()
	p.acted = true
	self:AddBet( p, amount )
	
	self:ContinueBettingRound()
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
-- Player action: Call and raise
--
-- @param amount Amount to add to the bet, minimum is the big blind.
--
function Main.Game:PlayerRaise( amount )
	local p = self:CurrentPlayer()
	assert( not p.folded )
	assert( not p.acted )
	
	if self.round_complete then	
		Main:Print( "The round has ended." )
		return
	end	
	
	if self.raises >= self.max_raises then
		Main:Print( "Cannot raise higher (capped)." )
		return
	end
	
	if amount < self.big_blind then 
		Main:Print( "Must raise at least the big blind amount." )
		return
	end
	
	amount = amount + self:CallAmount(p)
	if amount > p.credit then
		Main:Print( "Insufficient credit." )
		return
	end
	
	self:PushHistory( "Player Raise" )
	
	self.raises = self.raises + 1
	
	self:ResetActed()
	p.acted = true
	self:AddBet( p, amount )
	
	self:ContinueBettingRound()
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
-- Player action: Fold
--
function Main.Game:PlayerFold()
	local p = self:CurrentPlayer()
	assert( not p.folded )
	
	if self.round_complete then	
		Main:Print( "The round has ended." )
		return
	end	
	
	self:PushHistory( "Player Fold" )
	
	p.folded = true
	p.acted = true
	self:ContinueBettingRound()
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
-- Player action: All-in
--
function Main.Game:PlayerAllIn()
	local p = self:CurrentPlayer()
	assert( not p.folded )
	
	if self.round_complete then	
		Main:Print( "The round has ended." )
		return
	end	
	
	self:PushHistory( "Player All-In" )
	
	local noraise = true
	
	if p.credit > self:CallAmount(p) then
		local raise = p.credit - self:CallAmount(p)
		
		-- full raise rule
		if raise > self.big_blind then
			self:ResetActed()
			noraise = false
		end
	end
	
	self:AddBet( p, p.credit, noraise )
	p.acted = true
	
	self:ContinueBettingRound()
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
-- Returns the next non-folded player from the index.
--
function Main.Game:FindNextPlayer( index )
	
	for i = 1,#self.players do
		index = index + 1
		if index > #self.players then index = 1 end
		if not self.players[index].folded then
			break
		end
	end
	
	return index
end

-------------------------------------------------------------------------------
-- Returns true if all players have "acted" during the current round.
--
function Main.Game:AllPlayersActed()
	for _,p in pairs( self.players ) do
		if not p.acted then return false end
	end
	
	return true
end

-------------------------------------------------------------------------------
-- Start a betting round
--
-- @param reset_pos Reset the turn to the person left of the dealer.
--
function Main.Game:StartBettingRound( reset_pos )
	self.round_complete = false
	
	if reset_pos then
		local t = self:FindNextPlayer( self.dealer )
		self:SetTurn(t)
	end
	
	self:ResetActed()
	self:ContinueBettingRound()
end

-------------------------------------------------------------------------------
function Main.Game:ContinueBettingRound()

	assert( not self.round_complete )

	if self:ActivePlayers() == 1 then
		-- everyone else folded.
		self.round = "ELIMINATED"
		self.round_complete = true
		Main:ClearTurnTarget()
		return
	end
	
	if self:CheckNoActionsLeft() then
		self.round = "POSTRIVER"
		self.round_complete = true
		Main:ClearTurnTarget()
		return
	end
	
	-- find next turn
	while( not self:AllPlayersActed() ) do
		local p = self:CurrentPlayer()
		if p.acted then
			self:NextTurn()
		else
			break
		end
	end
	 
	if self:AllPlayersActed() then
		self.round_complete = true
	--[[else -- replaced by CheckNoActionsLeft()
		if self:AutoCheck() then
			self.round_complete = true
		end]]
		
		Main:ClearTurnTarget()
	else
		self:TellActions()
		Main:SetTurnTarget( self:CurrentPlayer().name )
	end
end

-------------------------------------------------------------------------------
function Main.Game:DealFlop()
	assert( self.round == "PREFLOP" and self:AllPlayersActed() )
	
	self:PushHistory( "Deal Flop" )
	self:DrawCard() -- burn
	
	self.round = "POSTFLOP"
	for i = 1,3 do table.insert( self.table, self:DrawCard() ) end
	self:StartBettingRound( true )
	 
	Main.Emote:AddTemplate( "FLOP", self:CardName( self.table[1] ),
						            self:CardName( self.table[2] ), 
						            self:CardName( self.table[3] ))
	
	Main:PartyPrint( "**FLOP DEALT**" )
	self:PrintTableCards()
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main.Game:DealTurn()
	assert( self.round == "POSTFLOP" and self:AllPlayersActed() )
	
	self:PushHistory( "Deal Turn" )
	self:DrawCard() -- burn and turn
	
	self.round = "POSTTURN"
	table.insert( self.table, self:DrawCard() )
	self:StartBettingRound( true )
	 
	Main.Emote:AddTemplate( "TURN", self:CardName( self.table[1] ), 
						            self:CardName( self.table[2] ), 
						            self:CardName( self.table[3] ), 
						            self:CardName( self.table[4] ) )
								
	Main:PartyPrint( "**TURN DEALT**" )
	self:PrintTableCards()
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main.Game:DealRiver()
	assert( self.round == "POSTTURN" and self:AllPlayersActed() )
	
	self:PushHistory( "Deal River" )
	self:DrawCard()
	
	self.round = "POSTRIVER"
	table.insert( self.table, self:DrawCard() )
	self:StartBettingRound( true )
	 
	Main.Emote:AddTemplate( "RIVER", self:CardName( self.table[1] ),
						             self:CardName( self.table[2] ), 
						             self:CardName( self.table[3] ), 
						             self:CardName( self.table[4] ),
						             self:CardName( self.table[5] ) )
								
	Main:PartyPrint( "**RIVER DEALT**" )
	self:PrintTableCards()
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
-- Deal the remaining cards on the table if they aren't there.
--
function Main.Game:DealRemainingTable()
	if #self.table == 5 then return end
	
	local c = 
	assert( #self.table == 0 or #self.table == 3 or #self.table == 4 )
	
	if #self.table == 0 then
		self:DrawCard()
		table.insert( self.table, self:DrawCard() )
		table.insert( self.table, self:DrawCard() )
		table.insert( self.table, self:DrawCard() ) 
	end
	
	while #self.table < 5 do
		self:DrawCard()
		table.insert( self.table, self:DrawCard() )
	end
	
	self:PrintTableCards()
	Main.Emote:AddTemplate( "DEALREST", self:CardName( self.table[1] ),
						                self:CardName( self.table[2] ), 
						                self:CardName( self.table[3] ), 
						                self:CardName( self.table[4] ),
						                self:CardName( self.table[5] ) )
end


-------------------------------------------------------------------------------
-- Process winners and give refunds to players who have bet too much.
-- 
function Main.Game:ProcessWinners()
	
	local iswinner = {} 
	
	local wins = self:GetWinners( true )
	
	for potnum,v in ipairs( wins ) do
		local winner_and_names = {}
		local winner_names = {}
		for _,p in pairs( v.winners ) do
			self.players[p].show = true
			self.players[p].credit = self.players[p].credit + math.floor(v.amount/#v.winners)
			table.insert( winner_names, self.players[p].alias )
			iswinner[p] = true
		end
		
		winner_and_names = CommaAndList( winner_names )
		winner_names = CommaList( winner_names )
		
		local potname = ""
		local potnamef = ""
		if potnum == 1 and #wins ~= 1 then
			potname = "main pot "
			potnamef = potname
		elseif potnum > 1 then
			potname = "side pot "
			potnamef = potname
			if #wins > 2 then
				potnamef = potname
				local things = { "first", "second", "third", "fourth", 
				                 "fifth", "sixth", "seventh", "eighth", 
								 "nineth", "tenth", "eleventh", "twelfth", 
								 "thirteenth", "fourteenth", "fifteenth" }
				if things[ potnum-1 ] then
					potnamef = things[ potnum-1 ] .. " " .. potname
				end
				
				potname = potname .. (potnum-1) .. " "
			end
		end
		
		local rankname = Main:FormatRank( v.rank )
		
		Main:PartyPrint( "%sWINNER%s (%s): %s WITH %s", 
							string.upper(potname),
							#v.winners == 1 and "" or "S",
							v.amount .. "g",
							winner_names,
							string.upper(rankname) )
										 
		if #wins == 1 then
			if #v.winners == 1 then
				Main.Emote:Add( "%s wins the hand (%sg) with %s.",
								 winner_and_names, v.amount, rankname )
			else
				Main.Emote:Add( "%s split the pot (%sg) with %s.",
								 winner_and_names, v.amount, rankname )
			end
		elseif #wins > 1 then
			if #v.winners == 1 then
				Main.Emote:Add( "%s wins the %s(%sg) with %s.", 
			                 winner_and_names, potnamef, v.amount, rankname )
			else
				Main.Emote:Add( "%s split the %s(%sg) with %s.", 
			                 winner_and_names, potnamef, v.amount, rankname )
			end
		end
	end
	
	-- The player who bet on the river is the 
	-- default first player to reveal their hand. otherwise
	-- to the left of the dealer
	local index
	if self.riverbet then index = self.riverbet-1 else index = self.dealer end
	local last_winner = nil
	for counter = 1, #self.players do
		index = index + 1
		if index > #self.players then index = 1 end
		if iswinner[index] then
			last_winner = index
		end
		
	end
	
	local showcards = true
	index = self.riverbet or self.dealer
	if self.riverbet then index = self.riverbet-1 else index = self.dealer end
	for counter = 1, #self.players do 
		index = index + 1
		if index > #self.players then index = 1 end
		if index == last_winner then
			showcards = false
		end
		
		if not iswinner[index] then
			local p = self.players[index]
			
			if not p.folded then
				if showcards then
					local rank = Main:FormatRank( p.rank )
					Main:PartyPrint( "%s: %s", p.alias, string.upper( rank ))
					Main.Emote:Add( "%s had %s.", p.alias, rank )
					p.show = true
				else 
					
					Main:PartyPrint( "%s: MUCKED", p.alias )
					Main.Emote:Add( "%s mucked %s hand.", p.alias, p.male and "his" or "her" )
				end
			end
		end
	end
	
	for _, p in pairs( self.players ) do
		p.bet = 0
	end
end

-------------------------------------------------------------------------------
function Main.Game:DoShowdown()
	
	assert( self.round == "POSTRIVER" and self:AllPlayersActed() )
	self:PushHistory( "Showdown" )
	
	Main:PartyPrint( "**SHOWDOWN**" )
	
	self:DealRemainingTable()
	
	self:ProcessWinners( true ) 
	
	self.round = ""
	self.round_complete = true
	self.hand_complete = true
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main.Game:DoEliminated()
	assert( self.round == "ELIMINATED" )
	self:PushHistory( "Eliminated" )
	Main:PartyPrint( "**ELIMINATED**" )
	
	local winner
	for _, p in pairs( self.players ) do
		if not p.folded then 
			assert( not winner ) -- debug purposes, change to a break later
			winner = p
		end
	end
	assert( winner ) -- error if we dont find a winner
	
	local amount = 0
	for _, p in pairs( self.players ) do 
		amount = amount + p.bet
		p.bet = 0
	end
	
	winner.credit = winner.credit + amount
	Main:PartyPrint( "%s WINS (%sg).", winner.alias, amount )
	Main.Emote:AddTemplate( "ELIM", winner.alias, amount )
	
	self.round = ""
	self.round_complete = true
	self.hand_complete = true
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main.Game:EndHand()
	assert( not self.hand_complete )
	
	self:PushHistory( "End Hand" )
	
	self.hand_complete = true
	self.round = ""
	for _,p in pairs( self.players ) do 
		p.bet = 0
	end
	
	self:SaveState()
	
--[[	self:CheckPots()
	
	if self:ActivePlayers() == 1 then
		--  ??winner
	end]]
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main.Game:NextRound()
	if not self.round_complete then
		Main:Print( "The current round is not complete." )
		return
	end
	
	self:CheckPots()
	--[[
	if self:ActivePlayers() == 1 then
	
		self:PushHistory( "Ended Hand" )
		
		self.hand_complete = true
		self.round = "END"
		-- distribute pot
		
		self:SaveState()
		return
	end]]
	
	if self.round == "PREFLOP" then
		self:DealFlop()
	elseif self.round == "POSTFLOP" then
		self:DealTurn()
	elseif self.round == "POSTTURN" then
		self:DealRiver()
	elseif self.round == "POSTRIVER" then
		self:DoShowdown()
	elseif self.round == "ELIMINATED" then
		self:DoEliminated()
	end
end

-------------------------------------------------------------------------------
-- Check pots and refund players who were unmatched
--
function Main.Game:CheckPots()
	
	for _,player in pairs( self.players ) do
		
		local maxbet = 0
		for _, player2 in pairs( self.players ) do
			if player ~= player2 then
				
				maxbet = math.max( maxbet, player2.bet )
			end
		end
		
		if maxbet < player.bet then
			-- nobody has matched this player's bet, give a refund.
			self:Refund( player, player.bet - maxbet )
			self:CheckPots()
			return
			
		end	
	end
end

local function SameValues( a, b )
	if #a ~= #b then return false end
	
	local map = {}
	for _,v in pairs(a) do map[v] = true end
	for _,v in pairs(b) do if not map[v] then return false end end
	
	return true
end

-------------------------------------------------------------------------------
-- Get the winners of the different pots
--
-- @param rank true to process card ranks, false to just populate a list of
--             pots and eligible players.
--
function Main.Game:GetWinners( ranks )
	local winners = {}
	local bet2 = {}
	
	for k,v in pairs( self.players ) do
		Main:UpdatePlayerRank( v )
		bet2[k] = v.bet
	end
	
	local pots = {}
	
	while true do
		local bet = 0
		local amount = 0
		local players = {}
		--local allplayers = {}
		for k,v in pairs( self.players ) do
			if bet2[k] > 0 then
				if bet == 0 then 
					bet = bet2[k]
				else 
					bet = math.min( bet, bet2[k] )
				end
			end
		end
		
		if bet == 0 then break end
		
		for k,v in pairs( self.players ) do
			if bet2[k] > 0 then
				bet2[k] = bet2[k] - bet
				amount = amount + bet
				--table.insert( allplayers, k )
				if not v.folded then
					table.insert( players, k )
				end
			end
		end
		
		table.insert( pots, { 
			amount = amount; -- amount in the pot
			players = players; -- eligible players
			--all = allplayers; -- all players who have contributed
		})
	end
	
	-- merge pots with the same winners
	for i = 1,#pots do
	
		local j = i+1
		while j <= #pots do
			if SameValues( pots[i].players, pots[j].players ) then
				pots[i].amount = pots[i].amount + pots[j].amount
				table.remove( pots, j )
			else
				j = j + 1
			end
		end
	end
	
	
	if ranks then
		for _,v in pairs( pots ) do
			v.winners = {}; -- player or players that win the pot with the best cards
			
			local bestrank = 0
			
			for _,p in pairs( v.players ) do
				bestrank = math.max( self.players[p].rank, bestrank )
			end
			
			v.rank = bestrank
			
			for _,p in pairs( v.players ) do
				if self.players[p].rank == bestrank then
					table.insert( v.winners, p )
				end
			end
		end
	end
	
	return pots
end

-------------------------------------------------------------------------------
-- Start a new hand.
--
function Main.Game:DealHand()
	assert( self.hand_complete )
	
	-- check if there's enough players
	do
		local count = 0
		for k,v in pairs( self.players ) do
			if v.active and v.credit > 0 then
				count = count + 1
				if count >= 2 then break end
			end
		end
		
		if count < 2 then
			Main:Print( "Not enough players for a new hand." )
			return
		end
	end
	
	self:PushHistory( "Deal Hand" )
	
	-- emote: deals a new hand. <a> and <b> place the blinds (1000g)
	
	self.hand_complete = false
	self.round         = "PREFLOP"
	self.raises        = 0
	self.bet           = self.ante + self.big_blind
	self.pot           = 0
	self.riverbet      = nil
	self.table         = {}
	
	self:NewDeck()
	
	for k,v in pairs( self.players ) do
		v.folded = false
		v.hand   = {}
		v.bet    = 0
		v.acted  = false
		v.allin  = false
		v.show   = false
		
		if not v.active or v.credit <= 0 then
			-- sit out this hand
			v.folded = true
			v.acted  = true
			v.active = false
		end
	end
	
	-- may not need this clause down here with the new one above now
	if self:ActivePlayers() < 2 then
		Main:Print( "Not enough players for a new hand." )
		
		-- cancel
		self.hand_complete = true
		self.round = ""
		
		self:SaveState()
		Main.UI:Update()
		return
	end
	
	self:PlayerAnteUp() 
	
	-- pass the button
	self.dealer = self:FindNextPlayer( self.dealer )
	
	self:SetTurn( self.dealer )
	self:PlayerDealCards()
	
	for k,v in pairs( self.players ) do
		if not v.folded then
			self:TellCards( v )
		end
	end
	
	self:NextTurn()
	
	
	-- put up the blinds
	local smallblind = self:CurrentPlayer()
	self:PlayerBetSmallBlind()
	self:NextTurn()
	local bigblind = self:CurrentPlayer()
	self:PlayerBetBigBlind()
	self:NextTurn()
	
	Main:PartyPrint( "**NEW HAND**" )
	
	Main.Emote:Add( "deals a new hand." )
	
	if self.ante > 0 then
		Main:PartyPrint( "ANTE: %s (%sg), %s (%sg)", smallblind.alias, self.small_blind, bigblind.alias, self.big_blind )
		
		Main.Emote:Add( "The ante is %sg.", self.ante )
	end
	
	Main:PartyPrint( "BLINDS: %s (%sg), %s (%sg)", smallblind.alias, self.small_blind, bigblind.alias, self.big_blind )
	
	if self.big_blind > 0 then
		Main.Emote:Add( "%s and %s place the blinds (%sg and %sg).", smallblind.alias, bigblind.alias, self.small_blind, self.big_blind )
	end
	
	self:StartBettingRound( false )
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
-- Adjust a player's credit.
--
-- @param player Name of player.
-- @param amount Amount to add (may be negative).
function Main.Game:AdjustCredit( player, amount )
	local p = self:GetPlayer( player )
	if not p then return end
	
	if not self.hand_complete then
		Main:Print( "Cannot add credit to player right now." )
		return
	end
	
	self:PushHistory( "Adjust Credit" )
	
	local old = p.credit
	
	p.credit = p.credit + amount
	
	Main:Print( "Adjusting credit - " .. p.alias 
				.. " Old: " .. old .. GOLD_ICON
				.. " New: " .. p.credit .. GOLD_ICON )
	
	self:SaveState()
	
	Main.UI:UpdatePlayerStatus()
end

-------------------------------------------------------------------------------
-- Format a player string.
--
-- Returns "name" / "alias" or nil if the player doesn't exist.
--
-- @param player Name of player.
--
function Main.Game:GetPlayerString( player )
	local p = self:GetPlayer( player )
	if not p then return end
	
	if p.alias == p.name then return p.name end
	return p.name .. " / " .. p.alias
end

-------------------------------------------------------------------------------
-- Print the community cards on the table to the party.
--
function Main.Game:PrintTableCards()
	local cards = ""
	for _,v in ipairs( self.table ) do
		if cards ~= "" then cards = cards .. " / " end
		
		cards = cards .. self:SmallCardName( v )
	end
	
	Main:PartyPrint( "TABLE CARDS: %s", cards )
end

-------------------------------------------------------------------------------
-- Cancel the current hand, returning bets to players and resetting
-- the state.
--
function Main.Game:CancelHand()
	self:PushHistory( "Cancel Hand" )
	self.round = ""
	self.round_complete = true
	self.hand_complete = true
	self.pot = 0
	self.bet = 0
	
	for _,p in pairs( self.players ) do
		p.credit = p.credit + p.bet
		p.bet = 0
	end
	
	Main:PartyPrint( "*** The current hand was cancelled. ***" )
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main.Game:Reset()
	self:PushHistory( "Reset" )
	
	self:LoadState( CopyTable(DEFAULT_STATE) )
	
	self:SaveState()
	Main.UI:Update()
end
 
-------------------------------------------------------------------------------
-- Print a string.
--
-- @param text Text to print, may contain placeholders {1}, {2}, {3} etc which
--             will be replaced with the extra arguments given.
--
-- @param ...  Text replacements.
--
function Main:Print( text, ... )
	for i = 1, select( "#", ... ) do
		local a = tostring(select( i, ... ))
		text = string.gsub( key, "{" .. i .. "}", a )
	end
	
	print( "|cffa9003b<RP Poker>|r " .. text )
end

-------------------------------------------------------------------------------
function Main:PartyPrint( text, ... )

	if select( "#", ... ) ~= 0 then
		text = string.format( text, ... )
	end
	
	local channel
	
	if IsInRaid() then
		channel = "RAID"
	else
		channel = "PARTY"
	end
	
	SendChatMessage( text, channel )
end

-------------------------------------------------------------------------------
function Main.Game:SetBettingOption( index, text, desc )
	local amt = tonumber( text )
	if not amt or amt < 0 then
		Main:Print( "Invalid amount." )
		Main.UI:Update()
		return
	end
	
	if not self.hand_complete then
		Main:Print( "Cannot modify value until the hand is complete." )
		Main.UI:Update()
		return
	end
	
	if self[index] == amt then return end
	
	self:PushHistory( desc )
	self[index] = amt
	self:SaveState()
	Main.UI:Update()
end

local turn_target = nil

-------------------------------------------------------------------------------
function Main:SetTurnTarget( unit )
	turn_target = unit
	SetRaidTarget( unit, 0 )
	SetRaidTarget( unit, self.Config.db.profile.turn_icon )
end

-------------------------------------------------------------------------------
function Main:ClearTurnTarget()
	if turn_target then
		SetRaidTarget( turn_target, 0 ) 
		turn_target = nil
	end
end

-------------------------------------------------------------------------------
function Main.Game:SendStatus()
	if not IsInGroup() then return end
	
	if self.sending_status then return end
	self.sending_status = true
	
	-- throttle to max every 2 seconds
	if GetTime() < self.status_time + 2 then
		Main:ScheduleTimer( function()
			Main.Game:DoSendStatus()
		end, self.status_time+2 - GetTime() )
		
		return
	end
	
	self:DoSendStatus()
	
end

-------------------------------------------------------------------------------
function Main.Game:DoSendStatus()
	
	self.status_time = GetTime()
	self.sending_status = false
	
	local msg = {}
	
	msg.p = {}
	
	for _,p in ipairs( self.players ) do
		local data = {
			n = p.name;
			al = p.alias;
			c = p.credit;
			b = p.bet;
			ai = p.allin;
			f = p.folded;
			ac = p.active;
			z = p.acted;
		}
		if p.show then
			data.h = p.hand
		end
		table.insert( msg.p, data )
	end
	
	msg.d = self.dealer
	--msg.an = self.ante
	--msg.sb = self.small_blind
	--msg.bb = self.big_blind
	
	msg.t = self.table
	msg.tn = self.turn
	msg.r = self.round
	msg.rc = self.round_complete
	msg.hc = self.hand_complete
	msg.b = self.bet
	
	if self.raises >= self.max_raises then
		msg.rs = 1
	end
	
	
	Main:SendCommMessage( "EPKSTATUS", Main:Serialize( PROTOCOL, msg ), "RAID" )
end

-------------------------------------------------------------------------------
local function CheckHandComplete()
	if not Main.Game.hand_complete then
		Main:Print( "Cannot do that right now." )
		return true
	end
end

-------------------------------------------------------------------------------
function Main.Game:ShuffleDealer()
	if CheckHandComplete() then return end
	
	self:PushHistory( "Shuffle Dealer" )
	
	self.dealer = math.random( 1, #self.players )
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main.Game:MovePlayerUp( name )
	if CheckHandComplete() then return end
	
	local p,idx = self:GetPlayer(name)
	if idx == 1 then return end
	
	self:PushHistory( "Move Player Up" )
	self.players[idx] = self.players[idx-1]
	self.players[idx-1] = p
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main.Game:MovePlayerDown( name )
	if CheckHandComplete() then return end
	
	local p,idx = self:GetPlayer(name)
	if idx == #self.players then return end
	
	self:PushHistory( "Move Player Down" )
	self.players[idx] = self.players[idx+1]
	self.players[idx+1] = p
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main.Game:RetellCards( name )
	local p = self:GetPlayer(name)
	if not p then return end
	self:TellCards( p )
end

-------------------------------------------------------------------------------
function Main.Game:DrawACard( msg )
	if CheckHandComplete() then return end
	
	local c = self:DrawCard()
	
	local text = string.format("draws a %s.", self:CardName(c))
	
	if msg == "new" then
		self:NewDeck()
		Main:Print( "Deck reset!" )
	elseif msg == "instant" then
		SendChatMessage( text, "EMOTE" )
	else
		Main.Emote:Add( text )
	end
end

-------------------------------------------------------------------------------
function SlashCmdList.EMOTEPOKER( msg )
	Main.UI.frame:Show()
end

function SlashCmdList.DRAWCARD( msg )
	Main.Game:DrawACard( msg )
end