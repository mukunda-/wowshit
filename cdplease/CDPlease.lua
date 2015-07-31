-------------------------------------------------------------------------------
-- CDPlease
-- (C) 2015 Mukunda Johnson (mukunda@mukunda.com)
-------------------------------------------------------------------------------
-- version 1.0 beta
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

-- indicator colors:
-- 0 blue       : querying cds				- initialize sound
-- 1 yellow     : asking for cd				
-- 2 green+fade : cd received				- pleasing sound
-- 3 red+fade   : target died or timed out	- fail sound
---
-- requests:
-- 0 purple+flash : cd request				- obnoxious sound
-- 1 green+fade   : given					
-- 2 red+fade     : timed out! bad raider!  - fail sound

local Masque = LibStub("Masque", true);
local MasqueGroup
if Masque then
	MasqueGroup = Masque:Group( "CDPlease", "Button" )
end


CDPlease = LibStub("AceAddon-3.0"):NewAddon( "CDPlease", 
			  "AceComm-3.0", "AceEvent-3.0" ) 

local g_frame = CreateFrame( "Button", "CDPleaseFrame" ) 
g_frame:SetMovable( true )
g_frame:SetResizable( true )
g_frame:SetMinResize( 16, 16 )
g_frame:EnableMouse( false )

--g_frame:SetPoint( "CENTER", 0, 0 )
g_frame:Hide()

g_frame.text = g_frame:CreateFontString()
g_frame.text:SetFont( "Fonts\\FRIZQT__.TTF", 16, "OUTLINE" )
g_frame.text:SetText( "Right click to lock." )
g_frame.text:SetPoint( "CENTER", g_frame, 0, 0 )
g_frame.text:Hide()

if MasqueGroup then
--	MasqueGroup:AddButton(g_frame)
end

local icon = g_frame:CreateTexture(nil, "BACKGROUND");
icon:SetAllPoints(g_frame)
g_frame.icon = icon
icon:SetTexture("Interface\\Icons\\spell_holy_painsupression");

if MasqueGroup then
	MasqueGroup:ReSkin()
end

-- asking for a cd
local g_query_active        = false	-- if we are currently asking for a cd 
local g_query_time          = 0     -- time that we changed states
local g_query_start_time    = 0     -- time that we started the query
local g_query_requested     = false -- if a cd is being requested
local g_query_list          = {}    -- list of userids that have cds available
local g_query_unit          = nil   -- unitid of person we want a cd from 
 
-- being asked for a cd
local g_help_active         = false
local g_help_unit           = nil
local g_help_time           = 0
local g_help_pulse          = 0

local g_ani_state           = "NONE"
local g_ani_time            = 0
local g_ani_finished        = true

local COMM_PREFIX  = "CDPLEASE"

local QUERY_WAIT_TIME = 0.25   -- time to wait for cd responses
local QUERY_TIMEOUT   = 1.8    -- time to give up query
local CD_WAIT_TIMEOUT = 7.0    -- time to allow user to give us a cd
local HARD_QUERY_TIMEOUT = 5.0 -- time for the query to stop even
                               -- when there are options left!


local g_drag_stuff
local g_unlocked = false

SLASH_CDPLEASE1 = "/cdplease"

local CD_SPELLS = { 
	102342; -- ironbark
	114030; -- vigilance
	122844; -- painsup
	6940;   -- sac
--	116841; -- tigers lust (debug)
}

local CD_MAP = {
	[102342] = "Ironbark";
	[114030] = "Vigilance";
	[122844] = "Pain Suppression";
	[6940]   = "Hand of Sacrifice";
--	[116841] = "Tiger's Lust"; -- (debug)
}
 
-------------------------------------------------------------------------------
function CDPlease:OnAddonLoaded( event, arg1 )
	
	if arg1 == "cdplease" then
		
		if not CDPleaseSaved then
			CDPleaseSaved = {}
		end
		
		local data = CDPleaseSaved
		data.size = data.size or 48
		
		g_frame:SetSize( data.size, data.size )
		g_frame:SetPoint( "CENTER", 0, 0 )
		
		if not CDPleaseSaved.init then
			CDPleaseSaved.init = true
			-- stuff...
		end
		
		if not CDPleaseSaved.locked then
			CDPlease:Unlock() 
		end
	end
end
 
-------------------------------------------------------------------------------
function CDPlease:OnCombatLogEvent( event, ... ) 
	local timestamp,evt,_,sourceGUID,_,_,_,destGUID,_,_,_,spellID = ...
	
	if evt == "SPELL_AURA_APPLIED" or evt == "SPELL_AURA_REFRESH" then
		
		if CD_MAP[spellID] then
			-- a cooldown was cast.
			
			if g_query_active and sourceGUID == UnitGUID( g_query_unit ) then
				if destGUID == UnitGUID( "player" ) then
					-- cd was cast on us!
					
					self:SetAnimation( "QUERY", "SUCCESS" )
					g_query_active = false
					
					self:PlaySound( "GOOD" )
					
				else
					-- cd was cast on someone else! find another one!
					g_query_requested = false
				end
			end
			
 
			if g_help_active and sourceGUID == UnitGUID("player") then
		 
				if destGUID == UnitGUID( g_help_unit ) then
					
					self:PlaySound( "GOOD" )
					
					-- good sound
					self:SetAnimation( "HELP", "SUCCESS" )
					g_help_active = false
				else
					self:PlaySound( "FAIL" )
					
					-- bad sound!
					self:SetAnimation( "HELP", "FAILURE" )
					g_help_active = false
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
function CDPlease:Unlock()
	if g_unlocked then return end
	
	if UnitAffectingCombat( "player" ) then
		print( "Cannot unlock in combat!" )
		return
	end
	
	if g_query_active or g_help_active then return end
	 
	if not g_drag_stuff then
		g_drag_stuff = {}
		
		local green = g_frame:CreateTexture()
		green:SetAllPoints()
		green:SetTexture( 0,0.5,0,0.4 )
		
		 
		g_frame:SetScript("OnMouseDown", function(self,button)
			if button == "LeftButton" then
				self:StartMoving()
			else
				CDPlease:Lock()
			end
		end)
		
		g_frame:SetScript("OnMouseUp", function(self)
			self:StopMovingOrSizing()
		end)
 
		g_drag_stuff.green = green 
	else
		g_drag_stuff.green:Show()
		
	end
	g_frame:EnableMouse( true )
	g_frame:Show()
	
	self:ShowText( "Right click to lock." )
	g_frame.text:SetTextColor( 1, 1, 1, 1 )
	
	g_unlocked = true
	CDPleaseSaved.locked = false
end

-------------------------------------------------------------------------------
function CDPlease:Lock()
	if not g_unlocked then return end
	if not g_drag_stuff then return end
	
	g_unlocked = false
	CDPleaseSaved.locked = true
	
	g_drag_stuff.green:Hide()
	self:HideText()
	g_frame:EnableMouse( false )
	g_frame:Hide()
end

-------------------------------------------------------------------------------
function CDPlease:ShowText( caption )
	g_frame.text:SetText( caption )
	g_frame.text:Show()
end

-------------------------------------------------------------------------------
function CDPlease:HideText( caption )
	g_frame.text:Hide()
end

-------------------------------------------------------------------------------
function CDPlease:Scale( size )
	
	size = tonumber( size )
	if size == nil then return end
	
	g_frame.text:SetFont( "Fonts\\FRIZQT__.TTF", math.floor(16 * size/48), "OUTLINE" )
	size = math.max( size, 16 )
	size = math.min( size, 256 )
	
	CDPleaseSaved.size = size
	g_frame:SetSize( size, size )

	if MasqueGroup then
		MasqueGroup:ReSkin()
	end
end

-------------------------------------------------------------------------------
local function UnitIDFromName( name )
	-- TODO check what format name is in!

	for i = 1,40 do
		local n  = UnitName( "raid" .. i )
		if n ~= nil then
			if n == name then return "raid" .. i end
		end
	end
	
	for i = 1,5 do
		local n  = UnitName( "party" .. i )
		if n ~= nil then
			if n == name then return "party" .. i end
		end
	end
	
	return nil
end

-------------------------------------------------------------------------------
local function ColorLerp( r1,g1,b1,r2,g2,b2,a )
	a = math.min( a, 1 )
	a = math.max( a, 0 )
	return r1 + (r2-r1) * a, g1 + (g2-g1) * a, b1 + (b2-b1) * a
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
-- Returns a range weight used for sorting the cd responses.
--
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
--local function CDOffCooldown()
--	local _,cl = UnitClass( "player" )
--	
--	local spell 
--	if 
--end

-------------------------------------------------------------------------------
-- Returns true if we have a cd ready to give to someone, and it isn't
-- already being asked for.
--
local function HasCDReady( ignore_reserve )
	if (g_help_active or g_unlocked) and not ignore_reserve then 
		-- someone is already asking us!
		return false
	end
	
	if UnitIsDeadOrGhost( "player" ) then return false end
	
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
function CDPlease:OnInitialize()
	self:RegisterComm( "CDPLEASE" )
end

-------------------------------------------------------------------------------
function CDPlease:OnCommReceived( prefix, message, dist, sender )
	if prefix ~= COMM_PREFIX then return end -- discard unwanted messages
	
	-- messages:
	-- ASK
	-- READY
	-- NO
	-- CD
	
	if message == "ASK" then
		-- player is asking for a CD
		
		if sender == UnitName( "player" ) then
			-- ignore ASK mirrored to self
			return
		end
		
		if HasCDReady() then
			self:RespondReady( sender )
		end
		
	elseif message == "READY" then
	
		if not g_query_active then return end
		
		local unit = UnitIDFromName( sender )
		if unit ~= nil and UnitLongRange( unit ) then
			table.insert( g_query_list, unit )
			
			if not g_query_requested and UnitShortRange( unit ) then
				self:RequestCD()
			end
		else
			-- out of range or cant find unit id
		end
		
	elseif message == "CD" then
		if not HasCDReady() then
		
			self:DeclineCD( sender )
			return
			
		end
		 
		-- start cd request
		
		self:ShowHelpRequest( sender )
		
	elseif message == "NO" then
		if sender == UnitName(g_query_unit) then
			g_query_requested = false
		end
	end
end

-------------------------------------------------------------------------------
function CDPlease:RespondReady( sender )
	self:SendCommMessage( COMM_PREFIX, "READY", "WHISPER", sender ) 
end
 
-------------------------------------------------------------------------------
-- Pop the top of the cd list and make a request.
--
-- @param sort Sort the list before popping it.
--
function CDPlease:RequestCD( sort )

	if g_query_requested then return false end -- request already in progress
	
	if #g_query_list == 0 then
		return false
	end

	if sort then
		table.sort( g_query_list, 
			function( a, b )
				-- can't get much less efficient than this!
				return UnitRangeValue(a) < UnitRangeValue(b)
			end
		) 
	end
	
	local unit = g_query_list[ #g_query_list ]
	table.remove( g_query_list )
	
	g_query_unit = unit
	g_query_requested = true
	g_query_time = GetTime()
	
	self:SendCommMessage( COMM_PREFIX, "CD", "WHISPER", UnitName( unit ))
	
	self:SetAnimation( "QUERY", "ASKING" )
	self:PlaySound( "ASK" )
	
	if not g_help_active then
		self:ShowText( UnitName( g_query_unit ))
	end
	 
	return true
	
end

-------------------------------------------------------------------------------
-- Decline giving a CD, sending a "NO" response
--
-- @param caller Name of caller
--
function CDPlease:DeclineCD( caller )
	self:SendCommMessage( COMM_PREFIX, "NO", "WHISPER", caller )
end

-------------------------------------------------------------------------------
-- Request a CD from the raid.
--
function CDPlease:CallCD()
	if g_query_active then 
		-- query is in progress already
		return
	end
	
	CDPlease:Lock()
	
	g_query_active        = true
	g_query_time          = GetTime()
	g_query_start_time    = g_query_time
	g_query_requested     = false 
	g_query_list          = {} 
	
	g_frame:Show()
	self:SetAnimation( "QUERY", "POLLING" )
	
	if not g_help_active then
		self:HideText()
	end
	
	self:SendCommMessage( COMM_PREFIX, "ASK", "RAID" )
	
	DoEmote( "helpme" )
	
	self:EnableFrameUpdates()
end

-------------------------------------------------------------------------------
function CDPlease:OnQueryUpdate()
	local t = GetTime() - g_query_time
	local t2 = GetTime() - g_query_start_time
	 
		
	if not g_query_requested then
	
		if t2 >= HARD_QUERY_TIMEOUT then
			
			self:PlaySound( "FAIL" )
			self:SetAnimation( "QUERY", "FAILURE" )
			g_query_active = false
			return
		end
	
		if t2 >= QUERY_WAIT_TIME then
			if not self:RequestCD() then
				if t2 >= QUERY_TIMEOUT then
				
					self:PlaySound( "FAIL" )
					self:SetAnimation( "QUERY", "FAILURE" )
					g_query_active = false
					return
				end
			end
		end
		
	else 
		if t >= CD_WAIT_TIMEOUT then
			self:PlaySound( "FAIL" )
			self:SetAnimation( "QUERY", "FAILURE" )
			g_query_active = false
		end
	end 
end

-------------------------------------------------------------------------------
function CDPlease:OnHelpUpdate()
	
	local t = GetTime() - g_help_time
	
	if GetTime() >= g_help_pulse then
		g_help_pulse = g_help_pulse + 1
		self:SetAnimation( "HELP", "HELP" )
		
		self:PlaySound( "HELP" )
	end
	--
--	if not HasCDReady( true ) then
--		g_help_active = false
--		self:SetAnimation( "HELP", "FAILURE" )
--		g_help_active = false
--		return
--	end
	
	if t >= CD_WAIT_TIMEOUT then
		self:PlaySound( "FAIL" )
		self:SetAnimation( "HELP", "FAILURE" )
		g_help_active = false
		return
	end
	
end

-------------------------------------------------------------------------------
-- Frame update handler.
--
function CDPlease:OnFrame()
	if g_query_active then
		self:OnQueryUpdate()
	end
	
	if g_help_active then
		self:OnHelpUpdate()
	end

	self:UpdateAnimation()
	
	if not g_query_active and not g_help_active and g_ani_finished then
		self:DisableFrameUpdates()
		g_frame:Hide()
	end
end

-------------------------------------------------------------------------------
-- Enable the OnFrame callback.
--
function CDPlease:EnableFrameUpdates()
	
	g_frame:SetScript( "OnUpdate", function() CDPlease:OnFrame() end )
	CDPlease:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent" )
end

-------------------------------------------------------------------------------
-- Disable the OnFrame callback.
--
function CDPlease:DisableFrameUpdates()
	g_frame:SetScript( "OnUpdate", nil )
	CDPlease:UnregisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent" )
end

-------------------------------------------------------------------------------
function CDPlease:NoCDAvailable()
	
end

-------------------------------------------------------------------------------
local SOUND_LIST = {
	["FAIL"] = "Interface\\Addons\\cdplease\\sounds\\fail.ogg";
	["ASK"]  = "Interface\\Addons\\cdplease\\sounds\\ask.ogg";
	["HELP"] = "Interface\\Addons\\cdplease\\sounds\\help.ogg";
	["GOOD"] = "Interface\\Addons\\cdplease\\sounds\\good.ogg";
}

function CDPlease:PlaySound( sound )
	local s = SOUND_LIST[sound]
	if s == nil then return end
	PlaySoundFile( s, "Master" )
end

-------------------------------------------------------------------------------
function CDPlease:ShowHelpRequest( sender )
	g_help_active = true
	g_help_unit   = UnitIDFromName( sender )
	g_help_time   = GetTime()
	g_help_pulse  = GetTime() + 1
	self:PlaySound( "HELP" )
	
	self:ShowText( UnitName( g_help_unit ))
	self:SetAnimation( "HELP", "HELP" )
	g_frame:Show()
	 
	
	self:EnableFrameUpdates()
end

-------------------------------------------------------------------------------
function CDPlease:SetAnimation( source, state )

	if source == "QUERY" and g_help_active then 
		-- do not interfere with help interface
		return
	end
	
	g_ani_state = state
	g_ani_time  = GetTime()
	g_ani_finished = false
end


-------------------------------------------------------------------------------
function CDPlease:UpdateAnimation()
	local t = GetTime() - g_ani_time
	
	if g_ani_state == "ASKING" then
		local r,g,b = ColorLerp( 1,1,1, 1,0.7,0.2, t / 0.25 )
		g_frame.icon:SetVertexColor( r, g, b, 1 )
		g_frame.text:SetTextColor( 1, 1, 1, 1 )
		if t >= 1.0 then g_ani_finished = true end
		
	elseif g_ani_state == "SUCCESS" then
		
		local a = 1.0 - math.min( t / 0.5, 1 )
		g_frame.icon:SetVertexColor( 0.3, 1, 0.3, a )
		g_frame.text:SetTextColor  ( 0.3, 1, 0.3, a )
		if t >= 0.5 then g_ani_finished = true end
		
	elseif g_ani_state == "FAILURE" then
	
		local a = 1.0 - math.min( t / 0.5, 1 )
		g_frame.icon:SetVertexColor( 1, 0.1, 0.2, a )
		g_frame.text:SetTextColor  ( 1, 0.1, 0.2, a )
		if t >= 0.5 then g_ani_finished = true end
		
	elseif g_ani_state == "POLLING" then
	
		local r,g,b = 0.25, 0.25, 0.6
		
		b = b + math.sin( GetTime() * 6.28 * 3 ) * 0.4
		
		r,g,b = ColorLerp( 1,1,1,r,g,b, t / 0.2 )
		g_frame.icon:SetVertexColor( r, g, b, 1 )
		g_frame.text:SetTextColor( 1,1,1,1 )
		if t >= 1.0 then g_ani_finished = true end
		
	elseif g_ani_state == "HELP" then
		local r,g,b = ColorLerp( 1,1,1, 0.5,0,0.5, t/0.25 )
		g_frame.icon:SetVertexColor( r, g, b, 1 )
		g_frame.text:SetTextColor( 1,1,1,1 )
		if t >= 1.0 then g_ani_finished = true end
	else
		g_frame.text:SetTextColor( 1,1,1,1 )
	end
end

-------------------------------------------------------------------------------
-- Slash command for macro binding.
--
function SlashCmdList.CDPLEASE( msg )
	local args = {}
	
	for i in string.gmatch( msg, "%S+" ) do
		table.insert( args, i )
	end
	
	if args[1] == "unlock" then
		CDPlease:Unlock()
	elseif args[1] == "call" then
		CDPlease:CallCD()
	elseif args[1] == "size" then
		CDPlease:Scale( args[2] )
		
	elseif args[1] == "fuck" then
		
		print( "My what a filthy mind you have!" )
		 
	else
		print( "/cdplease unlock - Unlock the frame." )
		print( "/cdplease size <pixels> - Scale the frame." )
		print( "/cdplease call - Call for a cd." )
	end
	 
	--CDPlease:CallCD()
end

CDPlease:RegisterEvent( "ADDON_LOADED", "OnAddonLoaded" )
