local g_players = {}

-- player:
--   index = seat #
--   

local g_dealer -- player index of current dealer

local BUTTON_ICON = 2 -- dealer icon (circle)
local TURN_ICON   = 4 -- turn icon (triangle)

local g_ante = 250
local g_small_blind = 500
local g_big_blind = 1000

local g_deck = {}

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
		name = name
		credit = credit
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
local function DealHand()
	-- start a new hand.
	
	SendChatMessage( "deals a new hand.", "EMOTE" )
	
	
end
