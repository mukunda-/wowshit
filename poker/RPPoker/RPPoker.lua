
local g_players = {}

-- player, index is the seat number
--   name    player name
--   credit  money remaining
--   hand    two cards (hole)
--   bet     how much money they bet in the current hand
--   acted   they have acted during the current betting round
--   allin   if they are all in for the hand
--   folded  if they are folded for the rest of the hand
--   active  if they are sitting at the table.

local g_dealer -- player index of current dealer

local BUTTON_ICON = 2 -- dealer icon (circle)
local TURN_ICON   = 4 -- turn icon (triangle)

local g_ante        = 250
local g_small_blind = 500
local g_big_blind   = 1000
local g_multiplier  = 1.0

local g_deck = {}

local STATE_SETUP = 1 -- adding players
local STATE_LIVE  = 2 -- playing a game

local g_stage

local STAGE_PREFLOP   = 1
local STAGE_POSTFLOP  = 2
local STAGE_POSTTURN  = 3
local STAGE_POSTRIVER = 4
local STAGE_SHOWDOWN  = 5

local g_turn -- whose turn is it

local g_flopped -- has the flop been dealt
local g_turned  -- has the turn been dealt

local g_pot = 0 -- amount of credit in the pot
local g_bet = 0 -- current bet

local g_raises  -- number of times the bet was raised in the round
local g_max_raises = 3

-- game state
local g_state = STATE_SETUP

-------------------------------------------------------------------------------
-- Loads a new shuffled deck.
--
local function NewDeck()
	g_deck = {}
	
	-- insert 52 cards.
	for i = 1,52 do
		table.insert( g_deck, i )
	end
	
	-- shuffle
	for i = 52,2,-1 do
		local j = math.random( 1, i )
		local k = g_deck[i]
		g_deck[i] = g_deck[j]
		g_deck[j] = k
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
local function DrawCard()
	if g_deck[1] == nil then NewDeck() end
	
	local a = g_deck[1]
	table.remove( g_deck, 1 )
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
local function DealCard( player )

	local p = player or CurrentPlayer()
	
	if p.folded then return false end -- (player is taking a break.)
	
 	table.insert( p.hand, DrawCard() )
end

-------------------------------------------------------------------------------
-- Initialize a new player table.
--
local function CreatePlayer( name, credit )
	return {
		name   = name;
		credit = credit;
		hand   = {}; -- aka hole
		folded = true;
		allin  = false;
		acted  = true;
		bet    = 0;
		active = true;
	}
end

-------------------------------------------------------------------------------
-- Get the player whose turn is active
--
local function CurrentPlayer()
	return g_players[g_turn]
end

-------------------------------------------------------------------------------
-- Increment the turn to the next non-folded player.
--
local function NextTurn()
	local t = g_turn
	for i = 1,#g_players do
		g_turn = g_turn + 1
		if g_players[g_turn] == nil then g_turn = 1 end
		if not g_players[g_turn].folded then
			return true
		end
	end
	
	g_turn = t
	return false -- no other players remaining
end

-------------------------------------------------------------------------------
-- Set the current turn.
--
local function SetTurn( index )
	g_turn = index
	
	assert( g_players[g_turn] ~= nil and not g_players[g_turn].folded )
end

-------------------------------------------------------------------------------
-- Add a new player to the poker table.
--
local function AddPlayer( name, credit ) 
	for k,v in pairs(g_players) do
		if v.name == name then return end -- player already added
	end
	
	table.insert( g_players, CreatePlayer( name, credit ) );
end

-------------------------------------------------------------------------------
-- Remove a player from the poker table.
--
local function RemovePlayer( name )
	for k,v in pairs(g_players) do
		if v.name == name then 
			table.remove( g_players, k ) 
			return
		end
	end
end

-------------------------------------------------------------------------------
-- Reset the table.
--
local function ResetGame()
	g_dealer = math.random( 1, #g_players )
	g_pot    = 0
	NewDeck()
end

-------------------------------------------------------------------------------
-- Tell a player what cards they have
--
-- @param player Player data.
--
local function TellCards( player )
	
	local msg = string.format( "Your cards: %s, %s. Credit: %dg",
							   CardName( p.hand[1] ), 
							   CardName( p.hand[2] ),
							   p.credit )
	
	SendChatMessage( msg, "WHISPER", _, player.name )
end

-------------------------------------------------------------------------------
-- Add a bet from a player to the pot.
--
-- If they have insufficient funds then it marks them as all-in and
-- bets as much as they have.
--
local function AddBet( player, amount )
	g_bet = g_bet + amount
	
	-- player goes all in if they cant afford the bet
	-- take care to not allow players to bet higher than they own
	-- the clipping is only for antes and blinds
	if player.credit < amount then
		amount = player.credit
		player.allin = true
	end
	
	g_pot = g_pot + amount
	player.bet = player.bet + amount
	player.credit = player.credit - amount
	
	if player.credit == 0 then player.allin = true end
	
end

-------------------------------------------------------------------------------
-- Deal cards.
--
local function PlayerDealCards() 
	assert( g_turn == g_dealer )
	
	local x = g_dealer
	
	for i = 1,#g_players*2 do
		x = x + 1
		if x >= #g_players then x = 1 end
		
		if not g_players[x].folded then
			DealCard( g_players[x] )
		end
	end
end

-------------------------------------------------------------------------------
-- Ante up for all players.
--
local function PlayerAnteUp()
	for _,p in pairs(g_players) do
	
		if not p.folded then
			AddBet( p, g_ante )
		end
	end
end

-------------------------------------------------------------------------------
-- Bet the small blind.
--
local function PlayerBetSmallBlind()
	local p = CurrentPlayer()
	AddBet( CurrentPlayer(), g_small_blind )
end

-------------------------------------------------------------------------------
-- Bet the big blind.
--
local function PlayerBetBigBlind()
	
	local p = CurrentPlayer()
	AddBet( CurrentPlayer(), g_big_blind )
end

-------------------------------------------------------------------------------
-- Player folds.
--
local function PlayerFold()
	local p = CurrentPlayer()
	assert( not p.folded )
	
	p.folded = true
	
end

-------------------------------------------------------------------------------
local function AnnounceTurn()
	local p = CurrentPlayer()
	
	local text = string.format( "%s's turn. Actions: 
end

-------------------------------------------------------------------------------
local function PartyPrint( text )
	local channel
	
	if <playerinraid> then
		channel = "RAID"
	else
		channel = "PARTY"
	end
	
	SendChatMessage( text, channel )
end

-------------------------------------------------------------------------------
-- Start a new hand.
--
local function DealHand()
	
	-- emote: deals a new hand. <a> and <b> place the blinds (1000g)
	
	SendChatMessage( "deals a new hand.", "EMOTE" )
	
	g_betting_round = 1
	g_raises = 0
	
	for k,v in pairs( g_players ) do
		v.folded = false
		v.hand   = {}
		v.bet    = 0
		v.acted  = false
		v.allin  = false
		
		if not v.active then
			-- sit out this hand
			v.folded = true
		end
	end
	
	-- pass the button
	g_dealer = g_dealer + 1
	if g_dealer >= #g_players then g_dealer = 1 end
	
	SetTurn( g_dealer )
	PlayerDealCards()
	
	for k,v in pairs( g_players ) do
		TellCards( v )
	end
	
	NextTurn()
	
	-- put up the blinds
	PlayerBetSmallBlind()
	NextTurn()	
	PlayerBetBigBlind()
	NextTurn()
	AnnounceTurn()
	
end
