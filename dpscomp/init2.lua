aura_env.slots   = 10  -- sliding window size
aura_env.rate    = 0.5 -- tickrate
aura_env.smooth  = 0.1 -- smooth factor
 
-------------------------------------------------------------------------------
aura_env.Reset = function()
	aura_env.saved_from   = {} -- x slot buffers
	aura_env.saved_to     = {}
	aura_env.buffer_from  = {} -- single buffer
	aura_env.buffer_to    = {}
	
	aura_env.amount_from  = {} -- processed results
	aura_env.amount_to    = {}
	
	aura_env.time         = GetTime()
	aura_env.slot         = 1
end

-------------------------------------------------------------------------------
aura_env.OnDamage = function( source, dest, damage )
	aura_env.buffer_to[dest] = (aura_env.buffer_to[dest] or 0) + damage
	aura_env.buffer_from[source] = (aura_env.buffer_from[source] or 0) + damage
end

-------------------------------------------------------------------------------
aura_env.OnFrame = function()
	local t = GetTime()
	if t >= aura_env.time + aura_env.refresh then
		aura_env.RecordTick()
	end
end

-------------------------------------------------------------------------------
aura_env.SmoothTable = function( table )
	local s = aura_env.smooth
	for k,v in pairs(table) do
		v = v * (1 - s)
		if v < 1 then
			table[k] = nil;
		else
			table[k] = v
		end
	end
end

-------------------------------------------------------------------------------
aura_env.ApplyBuffer = function( table, buffer )
	local s = aura_env.smooth
	for k,v in pairs(buffer) do
		table[k] = (table[k] or 0) + v * s
	end
end

-------------------------------------------------------------------------------
aura_env.RecordTick = function()
	aura_env.time = GetTime()
	aura_env.slot = aura_env.slot + 1
	if aura_env.slot > aura_env.slots then
		aura_env.slot = 1
	end
	
	-- process/smooth
	aura_env.SmoothTable( aura_env.current_from )
	aura_env.SmoothTable( aura_env.current_to   )
	
	-- apply buffers
	aura_env.ApplyBuffer( aura_env.current_from, aura_env.buffer_from )
	aura_env.ApplyBuffer( aura_env.current_to,   aura_env.buffer_to   )
	
	-- reset buffers
	aura_env.buffer_from = {}
	aura_env.buffer_to   = {}
	
	WeakAuras.ScanEvents( "WA_DPS_COMPUTER_FRAME" )
end

-------------------------------------------------------------------------------
aura_env.Reset()

wa_dps_computer_data = aura_env
