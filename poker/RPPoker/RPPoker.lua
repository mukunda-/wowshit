local Main = RPPoker

-------------------------------------------------------------------------------
Main.Game = {
 
	history = {};
	redo    = {};
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

-- nil assignments are just for documentation purpose

	dealer      = 1;
--	button_icon = nil;
--	turn_icon   = nil;

-- TODO; copy these from config on game start
	ante        = 0;
	small_blind = 0;
	big_blind   = 0;
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
	
	history_note = "";
}

-------------------------------------------------------------------------------
function Main.Game:LoadState( state )
	for k, v in pairs( state ) do
		self[k] = v
	end
end

Main.Game:LoadState( DEFAULT_STATE )

-------------------------------------------------------------------------------
local state_keys = {
	"players", "dealer", "ante", "small_blind",
	"big_blind", "multiplier", "deck", "state",
	"round", "round_complete", "hand_complete",
	"turn", "pot", "bet", "raises", "table",
	"history_note"
}

local NUM_HISTORY_ENTRIES = 10
local GOLD_ICON = "|TInterface/MONEYFRAME/UI-GoldIcon:0|t"
  
-------------------------------------------------------------------------------
Main.CARD_NAMES = { "Ace", "Two", "Three", "Four", "Five", "Six", "Seven", 
                       "Eight", "Nine", "Ten", "Jack", "Queen", "King" }
Main.CARD_SUITS = { "Clubs", "Diamonds", "Hearts", "Spades" }

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
--		pot    = 0;
		active = true;
	}
end

-------------------------------------------------------------------------------
function Main.Game:TogglePlayerBreak( name )
	local p = self:GetPlayer(name)
	if not p then return end
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
		if v.name == name then return v end
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
	self.dealer = math.random( 1, #self.players )
	self.pot    = 0
	
	self.ante        = Main.Config.db.profile.ante
	self.small_blind = Main.Config.db.profile.small_blind
	self.big_blind   = Main.Config.db.profile.big_blind
	self.multiplier  = Main.Config.db.profile.multiplier
	
	self:NewDeck()
end

-------------------------------------------------------------------------------
-- Returns the name of a card.
--
function Main.Game:CardName( card )
	local number, suit = self:CardValue( card )
	
	return Main.CARD_NAMES[number] .. " of " .. Main.CARD_SUITS[suit]
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
	
	print( "tellcards", player.name, player.hand[1], player.hand[2] )
	local msg = string.format( "<EP> Your cards: %s, %s. Credit: %dg",
							   self:CardName( player.hand[1] ), 
							   self:CardName( player.hand[2] ),
							   player.credit )
	
	SendChatMessage( msg, "WHISPER", _, player.name )
	--self:SendChatMessage( msg, "WHISPER", player.name )
	
end

-------------------------------------------------------------------------------
-- Add a bet from a player to the pot.
--
-- If they have insufficient funds then it marks them as all-in and
-- bets as much as they have.
--
function Main.Game:AddBet( player, amount )
	
	-- player goes all in if they cant afford the bet
	-- take care to not allow players to bet higher than they own
	-- the clipping is only for antes and blinds
	
	if player.credit < amount then
		amount = player.credit
		player.allin = true
		player.acted = true
	end
	
	player.bet = player.bet + amount
	self.bet = math.max( self.bet, player.bet )
	
	player.credit = player.credit - amount
	
	if player.credit == 0 then 
		player.allin = true
		player.acted = true
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
				AddBet( p, self.ante )
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
	for k,v in pairs(self.players) do
		if not v.folded then
			count = count + 1 
		end
	end
	return count
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
	AddBet( p, self.bet - self.bet )
	
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
	
	self:PushHistory( "Player Bet" )
	
	self:ResetActed()
	p.acted = true
	self:AddBet( amount )
	
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
	
	if self.round_complete then	
		Main:Print( "The round has ended." )
		return
	end	
	
	if self.raises >= self.max_raises then
		Main:Print( "Cannot raise higher." )
		return
	end
	
	if amount < self.big_blind then 
		Main:Print( "Must raise at least the big blind amount." )
		return
	end
	
	amount = amount + CallAmount(p)
	if amount > p.credit then
		Main:Print( "Insufficient credit." )
		return
	end
	
	self:PushHistory( "Player Raise" )
	
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
	
	if p.credit > self:CallAmount(p) then
		local raise = p.credit - self:CallAmount(p)
		
		-- full raise rule
		if raise > self.big_blind then
			self:ResetActed()
		end
	end
	
	self:AddBet( p, p.credit )
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
	for i = 1, #self.players do
		if not self.players[i].acted then return false end
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

	if self:ActivePlayers() == 1 then
		-- everyone else folded.
		self.round_complete = true 
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
	
	
	Main:Emote( "FLOP", self:CardName( self.table[1] ),
						self:CardName( self.table[2] ), 
						self:CardName( self.table[3] ) )
						
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
	Main:Emote( "TURN", self:CardName( self.table[1] ),
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
	self:DrawCard() -- burn and turn
	
	self.round = "POSTRIVER"
	table.insert( self.table, self:DrawCard() )
	self:StartBettingRound( true )
	Main:Emote( "RIVER", self:CardName( self.table[1] ),
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

function Main.Game:DoShowdown()
	
	assert( self.round == "POSTRIVER" and self:AllPlayersActed() )
	self:PushHistory( "Showdown" )
	
	Main:PartyPrint( "**SHOWDOWN**" )
	
	local wins = self:GetWinners()
	for potnum,v in ipairs( wins ) do
		local winner_names = {}
		for _,p in pairs( v.winners ) do
			self.players[p].credit = self.players[p].credit + math.floor(v.amount/#v.winners)
			table.insert( winner_names, self.players[p].alias )
		end
		
		winner_names = CommaList( winner_names )
		if potnum == 1 then
			local potname = ""
			if potnum == 1 and #wins ~= 1 then
				potname = "MAIN POT "
			elseif potnum > 1 then
				potname = "SIDE POT "
				if #wins > 2 then
					potname = potname .. (potnum-1) .. " "
				end
			end
			
			Main:PartyPrint( string.format( "%sWINNER%s (%s): %s WITH %s", 
											potname,
											#v.winners == 1 and "" or "S",
											v.amount .. "g",
											winner_names,
											string.upper(Main:FormatRank( v.rank )) ))
		
		
		end
	end
	
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main.Game:NextRound()
	if not self.round_complete then
		Main:Print( "The current round is not complete." )
		return
	end
	
	self:CheckPots()
	
	if self:ActivePlayers() == 1 then
	
		self:PushHistory( "Ended Hand" )
		
		self.hand_complete = true
		-- distribute pot
		
		self:SaveState()
		return
	end
	
	if self.round == "PREFLOP" then
		self:DealFlop()
	elseif self.round == "POSTFLOP" then
		self:DealTurn()
	elseif self.round == "POSTTURN" then
		self:DealRiver()
	elseif self.round == "POSTRIVER" then
		self:DoShowdown()
	end
end

-------------------------------------------------------------------------------
function Main.Game:EndHand()
	assert( not self.hand_complete )
	
	self.hand_complete = true
	
	self:CheckPots()
	
	if self:ActivePlayers() == 1 then
		--  ??winner
	end
end

-------------------------------------------------------------------------------
-- Check pots and refund players who were unmatched
--
function Main.Game:CheckPots()
	
end

-------------------------------------------------------------------------------
function Main.Game:GetWinners()
	local winners = {}
	local bet2 = {}
	
	for k,v in pairs( self.players ) do
		Main:UpdatePlayerRank( v )
		bet2[k] = v.bet
	end
	
	local pots = {}
	
	while true do
		local bet = 9999999999999
		local amount = 0
		local players = {}
		for k,v in pairs( self.players ) do
			if bet2[k] > 0 then
				bet = math.min( bet, bet2[k] )
			end
		end
		
		if bet == 0 then break end
		
		for k,v in pairs( self.players ) do
			if bet2[k] > 0 then
				bet2[k] = bet2[k] - bet
				amount = amount + bet
				if not v.folded then
					table.insert( players, k )
				end
			end
		end
		
		table.insert( pots, { amount = amount, players = players, winners = {} } )
	end
	 
	for k,v in pairs( pots ) do
	
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
	
	return pots
end

-------------------------------------------------------------------------------
-- Start a new hand.
--
function Main.Game:DealHand()
	assert( self.hand_complete )
	
	self:PushHistory( "Deal Hand" )
	
	-- emote: deals a new hand. <a> and <b> place the blinds (1000g)
	
	self.hand_complete = false
	self.round  = "PREFLOP"
	self.raises = 0
	self.bet    = self.ante + self.big_blind
	self.pot    = 0
	self.table  = {}
	
	self:NewDeck()
	
	for k,v in pairs( self.players ) do
		v.folded = false
		v.hand   = {}
		v.bet    = 0
		v.acted  = false
		v.allin  = false
		
		if not v.active or v.credit == 0 then
			-- sit out this hand
			v.folded = true
			v.acted  = true
		end
	end
	
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
	
	print( "DEBUG: NEW HAND" )
	
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
	self:PlayerBetSmallBlind()
	self:NextTurn()
	self:PlayerBetBigBlind()
	self:NextTurn()
	
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
	
	if not self.hand_complete and p.folded or p.allin then
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
		if cards ~= "" then cards = cards .. ", " end
		
		cards = cards .. self:CardName( v )
	end
	
	Main:PartyPrint( "TABLE CARDS: " .. cards )
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
	self:SaveState()
	
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main.Game:Reset()
	self:PushHistory( "Reset" )
	
	self:LoadState( DEFAULT_STATE )
	self:SaveState()
	Main.UI:Update()
end

-------------------------------------------------------------------------------
function Main:SendChatMessage( text, chattype, dest )
	ChatThrottleLib:SendChatMessage( "NORMAL", self.cprefix, text, chattype, nil, dest )
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
function Main:PartyPrint( text )
	local channel
	
	if IsInRaid() then
		channel = "RAID"
	else
		channel = "PARTY"
	end
	
	self:SendChatMessage( text, channel )
end
