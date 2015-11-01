local Main = RPPoker

-- hand ranking computer

-- note that all computation functions should be made to handle 
-- if there are less, or more, than 7 cards to choose from.
--
-- they -may- assume that a higher rank was already checked beforehand
--

local RankStrings = {
	[0] = "nothing";
	[1] = "a Pair";
	[2] = "two Pairs";
	[3] = "a Three of a Kind";
	[4] = "a Straight";
	[5] = "a Flush";
	[6] = "a Full House";
	[7] = "a Four of a Kind";
	[8] = "a Straight Flush";
	[9] = "a Royal Flush";
}

-------------------------------------------------------------------------------
local function EncodeRank( rank, v1, v2, v3, v4, v5 )  
	return rank * 1048576 + (v1 or 0) * 65536 + (v2 or 0) * 4096 
		   + (v3 or 0) * 256 + (v4 or 0) * 16 + (v5 or 0)
end

-------------------------------------------------------------------------------
local function ReverseTableSort( a, b )
	return a > b
end

-------------------------------------------------------------------------------
local function StraightFlush( cards )
	local sets = {{},{},{},{}}
	for _,v in ipairs( cards ) do
		local number, suit = Main.Game:CardValue( v )
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
		if highest == 14 then
			-- ace high is a royal flush.
			return EncodeRank( Main.RANKS.ROYAL_FLUSH )
		end
		return EncodeRank( Main.RANKS.STRAIGHT_FLUSH, highest )
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function FourKind( cards )
	local counts = {}
	
	local found = 0
	
	for _,v in ipairs( cards ) do
		local number, suit = Main.Game:CardValue( v, true )
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
		
		return EncodeRank( Main.RANKS.FOUR_KIND, found, kicker )
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function FullHouse( cards )
	local counts = {}
	
	local triples, doubles = {}, {}
	
	for _,v in ipairs( cards ) do
		local number = Main.Game:CardValue( v, true )
		
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
		for _,v2 in ipairs( doubles ) do
			if v2 ~= v then
				-- both tables are sorted so this
				-- is the highest combo found
				return EncodeRank( Main.RANKS.FULL_HOUSE, v, v2 )
			end
		end
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function Flush( cards )
	local counts = {} -- count of each suit
	local highest = {} -- highest of each suit
	
	for _,v in ipairs( cards ) do
		local number, suit = Main.Game:CardValue( v, true )
		
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
		
		return EncodeRank( Main.RANKS.FLUSH, value )
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function Straight( cards )
	local found = {}  -- filter object
	
	local cards2 = {} -- unique cards
	
	for _,v in ipairs( cards ) do 
		local number = Main.Game:CardValue( v )
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
		if cards2[i]-1 == cards2[i-1] then
			found = found + 1
			if found >= 5 then
				highest = math.max( highest, cards2[i] )	
			end
		else
			found = 1
		end
	end
	
	if highest ~= 0 then
		return EncodeRank( Main.RANKS.STRAIGHT, highest )
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function ThreeKind( cards )

	local cards2 = {}
	
	for _,v in ipairs(cards) do
		local number = Main.Game:CardValue( v, true )
		table.insert( cards2, number )
	end
	table.sort( cards2, ReverseTableSort )
	
	local value = 0
	local kickers = {0,0}
	
	for i = 1, #cards2-2 do
		if cards2[i] == cards2[i+1] and cards2[i] == cards2[i+2] then
			value = cards2[i]
			table.remove( cards2, i )
			table.remove( cards2, i )
			table.remove( cards2, i )
			break
		end
	end
	
	if value ~= 0 then
		kickers[1] = cards2[1] or 0
		kickers[2] = cards2[2] or 0
		return EncodeRank( Main.RANKS.THREE_KIND, kickers[1], kickers[2] )
	end
end

-------------------------------------------------------------------------------
local function TwoPairs( cards )
	local found = {}
	local kicker = 0
	
	local cards2 = {}
	
	for _,v in ipairs(cards) do
		local number = Main.Game:CardValue( v, true )
		table.insert( cards2, number )
	end
	table.sort( cards2, ReverseTableSort )
	
	-- note that its assumed that there are no three cards in a row.
	
	local i = 1
	while i <= #cards2-1 do
		if cards2[i] == cards2[i+1] then
			found[#found+1] = cards2[i]
			table.remove( cards2, i )
			table.remove( cards2, i )
			
			if #found == 2 then break end
		else
			i = i + 1
		end
	end
	
	if #found == 2 then
		kicker = cards2[1] or 0
		return EncodeRank( Main.RANKS.TWO_PAIR, 
		                   found[1], found[2], cards2[1] or 0 )
	end
end

-------------------------------------------------------------------------------
local function OnePair( cards )
	local found = 0
	local cards2 = {}
	for _,v in ipairs( cards ) do
		local number = Main.Game:CardValue( v, true )
		table.insert( cards2, number )
	end
	table.sort( cards2, ReverseTableSort )
	
	for i = 1,#cards2-1 do
	
		if cards2[i] == cards2[i+1] then
			found = cards2[i]
			table.remove( cards2, i )
			table.remove( cards2, i )
			break
		end
	end
	
	if found ~= 0 then
		return EncodeRank( Main.RANKS.ONE_PAIR, found, 
		                   cards2[1] or 0, cards2[2] or 0, cards2[3] or 0 )
	end
end

-------------------------------------------------------------------------------
local function HighCard( cards )
	local cards2 = {}
	for _,v in ipairs( cards ) do
		local number = Main.Game:CardValue( v, true )
		table.insert( cards2, number )
	end
	table.sort( cards2, ReverseTableSort )
	
	return EncodeRank( Main.RANKS.HIGH_CARD, 
	                   cards2[1] or 0, cards2[2] or 0, 
	                   cards2[3] or 0, cards2[4] or 0,
					   cards2[5] or 0 )
end

-------------------------------------------------------------------------------
-- Compute a hand ranking value from a set of cards.
--
-- @param cards One or more cards to compute the rank from. It will pick
--              the five most-valued cards to produce the rank value.
--
function Main:ComputeHandRank( cards )
	
	return StraightFlush(cards)
		   or FourKind(cards)  or FullHouse(cards)
		   or Flush(cards)     or Straight(cards)
		   or ThreeKind(cards) or TwoPairs(cards)
		   or OnePair(cards)   or HighCard(cards)
end

-------------------------------------------------------------------------------
-- Update a player's hand ranking value from their cards.
--
-- @param player Reference to player in game players table.
--
function Main:UpdatePlayerRank( player )

	-- cards is table cards and player cards combined
	local cards = {}
	
	for _,v in ipairs( player.hand ) do
		table.insert( cards, v )
	end
	
	for _,v in ipairs( Main.Game.table ) do
		table.insert( cards, v )
	end
	
	player.rank = self:ComputeHandRank( cards )
end

-------------------------------------------------------------------------------
-- Returns a rank's name
--
function Main:FormatRank( rank )
	local r = math.floor(rank / 1048576)
	return RankStrings[r]
end

-------------------------------------------------------------------------------
function Main:RankIndex( rank )
	return math.floor(rank / 1048576)
end

--[[ UNIT TESTING!

local function GetTestCards( ... )
	local cards = {}
	for i = 1, select("#",...) do
		local v = select( i, ... )
		local n, s = string.match( v, "([0-9AJQK]+)([shdc])" )
		if n == 'A' then n = 1
		elseif n == 'J' then n = 11
		elseif n == 'Q' then n = 12
		elseif n == 'K' then n = 13
		else
			n = tonumber(n) 
			if n then
				if n < 2 or n > 10 then n = nil end
			end
		end
		
		if not n then error( "Invalid card: " .. v ) end
		n = n - 1
		
		if s == 'c' then s = 0
		elseif s == 'd' then s = 1 
		elseif s == 'h' then s = 2
		elseif s == 's' then s = 3 
		else 
			error( "Invalid card: " .. v ) 
		end
		
		table.insert( cards, n*4+s+1 )
		
	end
	
	return cards
end

local function TEST_EQ( rank, ... )
	cards = GetTestCards( ... )
	local r = Main:ComputeHandRank( cards )
	
	if Main:RankIndex( r ) ~= rank then
		print( "Test failed. Cards = ", cards[1], cards[2], cards[3], cards[4], cards[5], cards[6], cards[7] )
		error( "TEST FAILED r=".. Main:FormatRank(r) )
	end
end

local function TestHandRanks()

	local gr = function( ... ) return Main:ComputeHandRank( GetTestCards( ... )) end
	
	TEST_EQ( 0, "Ah", "Kh", "5d", "4d", "9s", "10s", "3h" )
	TEST_EQ( 1, "Ah", "As", "5d", "4d", "9s", "10s", "3h" )
	TEST_EQ( 2, "Kd", "Kh", "5d", "4d", "9s", "9d" , "3h" )
	TEST_EQ( 3, "Kd", "Kh", "Kc", "4d", "9s", "10s", "3h" )
	TEST_EQ( 4, "Ah", "2d", "5s", "4d", "9s", "10s", "3h" )
	TEST_EQ( 4, "Ah", "2d", "5s", "6s", "4s", "10s", "3h" )
	TEST_EQ( 4, "Ah", "Kd", "Qs", "Jh", "4s", "10s", "3h" )
	TEST_EQ( 5, "Ah", "Kh", "Qh", "Jh", "4s", "10s", "3h" )
	TEST_EQ( 6, "Ah", "Kd", "Qd", "As", "Ad", "10d", "10d" ) -- deliberate double card
	TEST_EQ( 7, "Ah", "Kd", "Ks", "As", "Ad", "Kc" , "Ac" ) 
	TEST_EQ( 8, "9h", "10h", "Jh", "Qh", "Kh", "As", "Ac" ) 
	TEST_EQ( 9, "9h", "10h", "Jh", "Qh", "Kh", "Ah", "Ac" ) 
	TEST_EQ( 4, "9h", "10h", "Jh", "Qh", "Ks", "As", "Ac" )
	
	assert( gr( "9h", "10h", "Jh", "Qh", "Kh", "As", "Ac" ) == gr( "9h", "10h", "Jh", "Qh", "Kh", "9s", "Ac" ) )
	assert( gr( "9h", "10h", "Jh", "Qh", "Kh", "As", "Ac" ) == gr( "9h", "10h", "Jh", "Qh", "Kh", "9s", "9c" ) )
	assert( gr( "9h", "10h", "Jh", "Qh", "Kh", "As", "Ac" ) == gr( "9h", "10h", "Jh", "Qh", "Kh", "9s", "2c" ) )
	
	assert( gr( "9h", "10h", "Jh", "Qh", "Kh", "8h", "Ac" ) > gr( "9h", "10h", "Jh", "Qh", "Ah", "8h", "2c" ) )
	assert( gr( "9h", "10h", "Jh", "Qh", "Kh", "10h", "Ac" ) > gr( "9h", "10h", "Jh", "Qh", "Ks", "9s", "2c" ) )
	assert( gr( "9h", "9s",  "9d", "9c", "Kh", "10h", "Ac" ) > gr( "9h", "10h", "Jh", "Qh", "Ks", "9s", "2c" ) )
	
	
	print( "|cff00ff00EMOTEPOKER HANDRANK TESTS PASSED!" )
end

TestHandRanks()

--]]
