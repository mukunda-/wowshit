local g_players = {}

-- player:
--   index = seat #
--   

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

local g_betting_round
-- 1 = preflop
-- 2 = postflop
-- 3 = postturn
-- 4 = postriver
-- 5 = showdown

local g_flopped -- has the flop been dealt
local g_turned  -- has the turn been dealt

-- game state
local g_state = STATE_SETUP

-------------------------------------------------------------------------------
-- Shuffles a new deck.
--
local function NewDeck()
	g_deck = {}
	
	for i = 1,52 do
		table.insert( g_deck, i )
	end
	
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
local function DrawCard()
	if g_deck[1] == nil then NewDeck() end
	
	local a = g_deck[1]
	table.remove( g_deck, 1 )
	return a
end

-------------------------------------------------------------------------------
local function CreatePlayer( name, credit )
	return {
		name   = name;
		credit = credit;
		hand   = {}; -- aka hole
	}
end

-------------------------------------------------------------------------------
local function AddPlayer( name, credit ) 
	for k,v in pairs(g_players) do
		if v.name == name then return end -- player already added
	end
	
	table.insert( g_players, CreatePlayer( name, credit ) );
end

-------------------------------------------------------------------------------
local function RemovePlayer( name )
	for k,v in pairs(g_players) do
		if v.name == name then 
			table.remove( g_players, k ) 
			return
		end
	end
end

-------------------------------------------------------------------------------
local function StartGame()
	g_dealer = 1
	NewDeck()
	
end

-------------------------------------------------------------------------------
-- Tell a player what cards they have
--
-- @param player Player data.
--
local function TellCards( player )
	
	local msg = string.format( "Your cards: %s, %s",
							   CardName( p.hand[1] ), 
							   CardName( p.hand[2] ))
	
	SendChatMessage( msg, "WHISPER", _, player.name )
end

-------------------------------------------------------------------------------
-- Start a new hand.
--
local function DealHand()
	
	-- emote: deals a new hand. <a> and <b> place the blinds (1000g)
	SendChatMessage( "deals a new hand.", "EMOTE" )
	
	for k,v in pairs( g_players ) do
		v.folded = false
		v.hand = {}
	end
	
	local x = g_dealer
	
	for i = 1, #g_players*2 do
		x = x + 1
		if x > #g_players then
			x = 1
		end
		
		table.insert( g_players[i].hand, DrawCard )
	end
	
	for k,v in pairs( g_players ) do
		TellCards( v )
	end
	
	
	
end
