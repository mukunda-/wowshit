-------------------------------------------------------------------------------
-- CDPlease
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-------------------------------------------------------------------------------
--
-- protocol:
--
-- /cdplease:
--   send "ASK" to raid
--   raid responds with cds available with "READY" message
--   if a cd is within range with 10 extra yards, request that cd immediately
--   timeout after threshold 250ms and select a cd that is 
--  the least out of range
--   give up after 1000ms if no cds are received
--   send "CD" to desired target
--   target either provides CD or they respond "NO" if it is unavailable or
--  reserved already by another cd request

-- CROSS REALM IS NOT SUPPORTED (yet?)

CDPlease = LibStub("AceAddon-3.0"):NewAddon( "CDPlease", 
			  "AceComm-3.0", "AceTimer-3.0", "AceEvent-3.0" ) 
					
local MyAddon = CDPlease

local g_update_frame = CreateFrame( "FRAME" )

local g_query_active        = false	-- if we are currently asking for a cd
local g_query_timer         = nil			-- 
local g_query_requested     = false -- if a cd is being requested
local g_query_time          = 0
local g_query_list          = {}

local cd_reserved     = false
local cd_time         = 0

local COMM_PREFIX  = "CDPLEASE"

local SHORT_TIMEOUT = 0.25 -- time to wait for cd responses
local LONG_TIMEOUT  = 2.0  -- time to give up

SLASH_CDPLEASE = "/cdplease"

local CD_SPELLS = { 
	102342; -- ironbark
	114030; -- vigilance
	122844; -- painsup
	6940;   -- sac
}

-------------------------------------------------------------------------------
local function UnitIDFromName( name )
	-- TODO check what format name is in!
	
	for i = 1,40 do
		local n,r = UnitName( "raid" .. i )
		if n ~= nil then
			n = n .. '-' .. r
			if n == name then return "raid" .. i end
		end
	end
	
	for i = 1,5 do
		local n,r = UnitName( "party" .. i )
		if n ~= nil then
			n = n .. '-' .. r
			if n == name then return "party" .. i end
		end
	end
	
	return nil
end

-------------------------------------------------------------------------------
-- Returns the squared range to a friendly unit.
--
-- Note that the casting range is slightly longer, since this is the
-- range to their center, and casting extends to their hitboxes
--
-- @param unit unitID of friendly unit.
-- @returns distance squared.
--
local function UnitDistance( unit )
	local y,x = UnitPosition( unit )
	local my,mx = UnitPosition( "player" )
	y,x = y - my, x - mx
	local d = x*x + y*y
	return d
end

-------------------------------------------------------------------------------
local function UnitShortRange( unit )
	return UnitDistance( unit ) < 35 * 35 and IsItemInRange( 34471, unit )
end

-------------------------------------------------------------------------------
local function UnitLongRange( unit )
	return UnitDistance( unit ) < 45 * 45 and IsItemInRange( 32698, unit )
end

-------------------------------------------------------------------------------
local function UnitRangeValue( unit )
	local a = UnitDistance( unit )
	
	if UnitShortRange( unit ) then
		return a
	elseif UnitLongRange( unit ) then
		return a + 100000
	else
		return a + 1000000
	end
end

-------------------------------------------------------------------------------
local function HasCDReady()
	if cd_reserved then return false end
	
	for k,v in ipairs( CD_SPELLS ) do
		if IsSpellKnown( v ) then
			local charges = GetSpellCharges( v ) 
			if charges ~= nil and charges >= 1 then return true end
			
			local start, duration, enable = GetSpellCooldown( v )
			if start == 0 then return true end
			if duration - (GetTime() - start) < 1 then return true end
		end
	end
end

-------------------------------------------------------------------------------
function MyAddon:OnInitialize()
	self:RegisterComm( "CDPLEASE" )
end

-------------------------------------------------------------------------------
function MyAddon:OnCommReceived( prefix, message, dist, sender )
	if prefix ~= COMM_PREFIX then return end -- discard unwanted messages
	
	-- messages:
	-- ASK
	-- READY
	-- NO
	-- CD
	
	if message == "ASK" then
		-- player is asking for a CD
		
		if sender == UnitName( "player" ) then
			-- ignore ASK sent to self
			return
		end
		
		if HasCDReady() then
			self:RespondReady()
		end
		
	elseif message == "READY" then
		local unit = UnitIDFromName( sender )
		if unit ~= nil then
			table.insert( cd_list, unit )
			
			if not query_requested and UnitShortRange( unit ) then
				self:RequestCD()
			end
		end
		
	elseif message == "CD" then
		if not HasCDReady() then
			DeclineCD( sender )
		end
		
		-- show cd window
		self:ShowCDRequest( sender )
		
	elseif message == "NO" then
		
	end
end

-------------------------------------------------------------------------------
-- 
function MyAddon:OnShortTimeout()
	query_short_timeout = true
	
	self:RequestCD( true )
	
	query_timer = self:ScheduleTimer( "OnLongTimeout", 
	                                  LONG_TIMEOUT - SHORT_TIMEOUT )
end

-------------------------------------------------------------------------------
-- 
function MyAddon:OnLongTimeout()
	query_long_timeout = true
	
	if not query_requested then
		self:GiveUpQuery()
	end
end

-------------------------------------------------------------------------------
-- Pop the top of the cd list and make a request.
--
-- @param sort Sort the list before popping it.
--
function MyAddon:RequestCD( sort )

	if query_requested then return end -- request already in progress

	if sort then
		table.sort( cd_list, 
			function( a, b )
				-- can't get much less efficient than this!
				return UnitRangeValue(a) < UnitRangeValue(b)
			end
		) 
	end
	
	local unit = cd_list[ #cd_list ]
	table.remove( cd_list )
	
	query_requested = true
	self:SendCommMessage( COMM_PREFIX, "CD", "WHISPER", UnitName( unit ))
	
	-- show cd window
end

-------------------------------------------------------------------------------
-- Decline giving a CD, sending a "NO" response
--
-- @param caller Name of caller
--
function MyAddon:DeclineCD( caller )
	self:SendCommMessage( COMM_PREFIX, "NO", "WHISPER", caller )
end

-------------------------------------------------------------------------------
-- Request a CD from the raid.
--
function MyAddon:CallCD()
	if query_active then 
		-- query is in progress already
		return
	end
	
	query_time          = GetTime()
	query_active        = true
	query_requested     = false
	query_short_expired = false
	
	cd_call_time = GetTime()
	
	cd_list = {}
	self:SendCommMessage( COMM_PREFIX, "ASK", "RAID" )
	
	DoEmote( "helpme" )
	
	query_timer = self:ScheduleTimer( "OnShortTimeout", SHORT_TIMEOUT )
end

-------------------------------------------------------------------------------
function MyAddon:NoCDAvailable()

end

-------------------------------------------------------------------------------
function MyAddon:ShowCDRequest( sender )
	cd_reserved = true
	
	-- show window
	-- set text to sender
end

-------------------------------------------------------------------------------
-- Slash command for macro binding.
--
function SLASHCMDLIST.CDPLEASE()
	MyAddon:CallCD()
end
