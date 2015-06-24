-- ♣ ♥ ♠ ♦

local g_players = {}

-- player, index is the seat number
--   name    player name
--   credit  money remaining
--   hand    two cards (hole)
--   rank    the rank of their hand, filled in at the showdown.
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

local g_round
local g_round_complete  
local g_hand_complete   = true

local ROUND_PREFLOP   = 1
local ROUND_POSTFLOP  = 2
local ROUND_POSTTURN  = 3
local ROUND_POSTRIVER = 4
local ROUND_SHOWDOWN  = 5

local g_turn -- whose turn is it

local g_flopped -- has the flop been dealt
local g_turned  -- has the turn been dealt

local g_pot = 0 -- total amount of credit in the pot (and side pots)
local g_bet = 0 -- current bet

local g_raises  -- number of times the bet was raised in the round
local g_max_raises = 3

local g_table = {} -- community cards

-- game state
local g_state = STATE_SETUP

local CARD_NAMES = { "Ace", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Jack", "Queen", "King" }
local CARD_SUITS = { "Clubs", "Diamonds", "Hearts", "Spades" }

local RANKS = {
	ROYAL_FLUSH = 9,
	STRAIGHT_FLUSH = 8,
	FOUR_KIND = 7,
	FULL_HOUSE = 6,
	FLUSH = 5,
	STRAIGHT = 4,
	THREE_KIND = 3,
	TWO_PAIR = 2,
	ONE_PAIR = 1,
	HIGH_CARD = 0,
	
	
}

-------------------------------------------------------------------------------
local function ReverseTableSort( a, b )
	return a > b
end

-------------------------------------------------------------------------------
local function EncodeRank( rank, v1, v2, v3, v4, v5 ) {
	return rank * 1048576 + (v1 or 0) * 65536 + (v2 or 0) * 4096 
		   + (v3 or 0) * 256 + (v4 or 0) * 16 + (v5 or 0)
}

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
		pot    = 0;
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
-- Increment the turn to the next player that isn't folded.
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
-- Returns the name of a card.
--
local function CardName( card )
	
	local number, suit = CardValue( card )
	
	return CARD_NAMES[number] .. " of " .. CARD_SUITS[suit]
end

-------------------------------------------------------------------------------
-- Parses a card value.
--
-- @param card      Card value (1-52).
-- @param aces_high Number aces as 14 instead of 1.
-- @returns Number of card, Suit of card
--
local function CardValue( card, aces_high )
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
	
	-- player goes all in if they cant afford the bet
	-- take care to not allow players to bet higher than they own
	-- the clipping is only for antes and blinds
	
	if player.credit < amount then
		amount = player.credit
		player.allin = true
		player.acted = true
	end
	
	g_pot = g_pot + amount
	
	player.bet = player.bet + amount
	g_bet = math.max( g_bet, player.bet )
	
	player.credit = player.credit - amount
	
	if player.credit == 0 then 
		player.allin = true
		player.acted = true
	end
	
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
local function AnnounceTurn()
	local p = CurrentPlayer()
	
	local actions = ""
	
	
	
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
-- Returns the amount of players that aren't folded.
--
local function ActivePlayers() 
	local count = 0
	for k,v in pairs(g_players) do
		if not v.folded then count = count + 1 end
	end
	return count
end

-------------------------------------------------------------------------------
local function CallAmount( player )
	return g_bet - player.bet
end

-------------------------------------------------------------------------------
-- Reset the "acted" state for each player, do this after the 
-- bet is raised.
--
local function ResetActed()
	for k,v in pairs(g_players) do
		
		if not v.folded and not v.allin then
			v.acted = false
		end
	end
end

-------------------------------------------------------------------------------
-- Player action: Call
--
local function PlayerCall()
	local p = CurrentPlayer()
	
	if p.credit < CallAmount(p) then
		print( "Insufficient credit." )
		return
	end
	
	p.acted = true
	AddBet( p, g_bet - p.bet )
	
	ContinueBettingRound()
end

-------------------------------------------------------------------------------
-- Player action: Check
--
local function PlayerCheck()
	local p = CurrentPlayer()
	
	if CallAmount(p) != 0 then
		print( "Check not allowed." )
		return
	end
	
	p.acted = true
	
	ContinueBettingRound()
end

-------------------------------------------------------------------------------
-- Player action: Bet
--
-- @param amount Amount to add to the bet, minimum is the big blind.
--
local function PlayerBet( amount )
	local p = CurrentPlayer()
	
	if CallAmount(p) != 0 then
		print( "Player must raise, not bet." )
		return
	end
	
	if amount < g_big_blind then
		print( "Must bet at least the big blind amount." )
		return
	end
	
	ResetActed()
	p.acted = true
	AddBet( amount )
	
	ContinueBettingRound()
end

-------------------------------------------------------------------------------
-- Player action: Call and raise
--
-- @param amount Amount to add to the bet, minimum is the big blind.
--
local function PlayerRaise( amount )
	local p = CurrentPlayer()
	
	if g_raises >= g_max_raises then
		print( "Cannot raise higher." )
		return
	end
	
	if amount < g_big_blind then 
		print( "Must raise at least the big blind amount." )
		return
	end
	
	amount = amount + CallAmount(p)
	if amount > p.credit then
		print( "Insufficient credit." )
		return
	end
	
	ResetActed()
	p.acted = true
	AddBet( p, amount )
	
	ContinueBettingRound()
end

-------------------------------------------------------------------------------
-- Player action: Fold
--
local function PlayerFold()
	local p = CurrentPlayer()
	assert( not p.folded )
	
	p.folded = true
	ContinueBettingRound()
end

-------------------------------------------------------------------------------
-- Player action: All-in
--
local function PlayerAllIn()
	local p = CurrentPlayer()
	assert( not p.folded )
	
	if p.credit > CallAmount(p) then
		local raise = p.credit = CallAmount(p)
		
		-- full raise rule
		if raise > g_big_blind then
			ResetActed()
		end
	end
	
	AddBet( p, p.credit )
	p.acted = true
	
	ContinueBettingRound()
end

-------------------------------------------------------------------------------
-- Returns the next non-folded player from the index.
--
local function FindNextPlayer( index )
	
	for i = 1,#g_players do
		index = index + 1
		if index >= #g_players then index = 1 end
		if not g_players[index].folded then
			break
		end
	end
	
	return index
end

-------------------------------------------------------------------------------
local function AllPlayersActed()
	for i = 1, #g_players do
		if not g_players[i].acted then return false end
	end
	
	return true
end

-------------------------------------------------------------------------------
-- Start a betting round
--
-- @param reset_pos Reset the turn to the person left of the dealer.
--
local function StartBettingRound( reset_pos )
	g_round_complete = false
	
	if reset_pos then
		local t = FindNextPlayer( g_dealer )
		SetTurn(t)
	end
	
	ContinueBettingRound()
end

-------------------------------------------------------------------------------
local function ContinueBettingRound()

	if ActivePlayers() == 1 then
		-- everyone else folded.
		EndHand()
		return
	end
	
	CheckPots()
	
	-- find next turn
	while( not AllPlayersActed() )
		local p = CurrentPlayer()
		if p.acted then
			NextTurn()
		else
			break
		end
	end
	
	if AllPlayersActed() then
		g_round_complete = true
	end
end

-------------------------------------------------------------------------------
local function NextRound() 
	if not g_round_complete then
		print( "The current round is not complete." )
		return
	end
end

-------------------------------------------------------------------------------
local function EndHand()
	assert( not g_hand_complete )
	
	g_hand_complete = true
	
	CheckPots()
	
	if ActivePlayers() == 1 then
		--
	end
end

-------------------------------------------------------------------------------
-- Distribute pots to winning players
--
local function CheckPots()
	
end

-------------------------------------------------------------------------------
local function SortWinners()
	
end

-------------------------------------------------------------------------------
-- Start a new hand.
--
local function DealHand()
	
	-- emote: deals a new hand. <a> and <b> place the blinds (1000g)

	g_hand_complete = false
	g_round  = ROUND_PREFLOP
	g_raises = 0
	g_bet    = g_ante + g_big_blind
	g_table  = {}
	
	NewDeck()
	
	for k,v in pairs( g_players ) do
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
	
	if ActivePlayers() < 2 then
		print( "Not enough players for a new hand." )
		return
	end
	
	PlayerAnteUp()
	
	SendChatMessage( "DEBUG: NEW HAND", "PARTY" )
	
	-- pass the button
	g_dealer = FindNextPlayer( g_dealer )
	
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
	
	StartBettingRound( false )
	
end

-- note that all computation functions should be made to handle 
-- if there are less, or more, than 7 cards to choose from.

-------------------------------------------------------------------------------
local function ComputeRoyalFlush( cards )

	local values = {{},{},{},{}}

	for _,v in ipairs( cards ) do
		local number, suit = CardValue( v )
		
		if number == 1 then
			values[suit][1] = true
		elseif number >= 10 then
			values[suit][2+number-10] = true
		end
	end
	
	for suit = 1,4 do
		if values[suit][1] and values[suit][2] and values[suit][3] 
		   and values[suit][4] and values[suit][5] then
		   
			return EncodeRank( RANKS.ROYAL_FLUSH )
		end
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function ComputeStraightFlush( cards )
	local sets = {{},{},{},{}}
	for _,v in ipairs( cards ) do
		local number, suit = CardValue( v )
		table.insert( sets[suit], number )
	end
	
	local highest = 0 -- highest value straight flush found.
	
	for _,v in ipairs( sets ) do
		if #v >= 5 then
			table.sort( v )
			if v[1] == 1 then table.insert( v, 14 ) end
			
			local found = 1
			for i = 2,#v do
				if v[i-1] == v[i]-1 then
					found = found + 1
					if found >= 5 then
						highest = math.max( v[i], highest )
					end
				else
					found = 1
				end
			end
			
			
		end
	end
	
	if highest ~= 0 then
		return EncodeRank( RANKS.STRAIGHT_FLUSH, highest )
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function ComputeFourKind( cards )
	local counts = {}
	
	local found = 0
	
	for _,v in ipairs( cards ) do
		local number, suit = CardValue( v, true )
		counts[number] = (counts[number] or 0) + 1
		if counts[number] == 4 then
			found = math.max( found, number )
		end
	end
	
	if found ~= 0 then
	
		local cards2 = {}
		for k,v in pairs( counts ) do
			-- the keys are the card numbers found in the hand, aces high
			if k ~= found then -- exclude the quad cards
				table.insert( cards2, k )
			end
		end
		
		local kicker = 0
		if #cards2 > 0 then
			table.sort( cards2 )
			kicker = cards2[#cards2]
		end
		
		return EncodeRank( RANKS.FOUR_KIND, found, kicker )
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function ComputeFullHouse( cards )
	local counts = {}
	
	local triples, doubles = {}
	
	for _,v in ipairs( cards ) do
		local number = CardValue( v, true )
		
		counts[number] = (counts[number] or 0) + 1
		if counts[number] == 2 then
			table.insert( doubles, number )
		elseif counts[number] == 3 then
			table.insert( triples, number )
		end
	end
	
	table.sort( triples, ReverseTableSort )
	table.sort( doubles, ReverseTableSort )
	
	for _,v in ipairs( triples ) do
		for _,v2 = ipairs( doubles ) do
			if v2 ~= v then
				-- both tables are sorted so this
				-- is the highest combo found
				return EncodeRank( RANKS.FULL_HOUSE, v, v2 )
			end
		end
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function ComputeFlush( cards )
	local counts = {} -- count of each suit
	local highest = {} -- highest of each suit
	
	for _,v in ipairs( cards ) do
		local number, suit = CardValue( v, true )
		
		counts[suit] = (counts[suit] or 0) + 1
		highest[suit] = math.max( highest[suit] or 0, number )
	end
	
	local value = 0
	
	for k,v in pairs( counts ) do
		if v >= 5 then
			-- flush was found, we want the flush with the
			-- highest card value
			value = math.max( value, highest[k] )
		end
	end
	
	if value ~= 0 then
		
		return EncodeRank( RANKS.FLUSH, value )
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function ComputeStraight( cards )
	local found = {}  -- filter object
	
	local cards2 = {} -- unique cards
	
	for _,v in ipairs( cards ) do 
		local number = CardValue( v )
		if not found[number] then
			found[number] = true
			table.insert( cards2, number )
			if number == 1 then
				table.insert( cards2, 14 )
			end
		end
	end
	
	table.sort( cards2 )
	
	found = 1
	local highest = 0
	for i = 2,#cards2 do
		if cards2[i]-1 = cards2[i-1] then
			found = found + 1
			if found >= 5 then
				highest = math.max( highest, cards2[i] )	
			end
		else
			found = 1
		end
	end
	
	if highest ~= 0 then
		return EncodeRank( RANKS.STRAIGHT, highest )
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function ComputeThreeKind( cards )
	
end

-------------------------------------------------------------------------------
local function ComputeRank( p )
	local cards = {}
	
	for _,v in ipairs( p.hand )
		table.insert( cards, v )
	end
	
	for _,v in ipairs( g_table )
		table.insert( cards, v )
	end
	
	local r = ComputeRoyalFlush(cards) or ComputeStraightFlush(cards) or 
			  ComputeFourKind(cards)   or ComputeFullHouse(cards) or 
			  ComputeFlush(cards)      or ComputeStraight(cards) or 
			  ComputeThreeKind(cards)  or ComputeTwoPair(cards) or
			  ComputeOnePair(cards)    or ComputeHighCard(cards)
			  
	p.rank = r
end
