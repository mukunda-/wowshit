aura_env.slots   = 10  -- sliding window size
aura_env.rate    = 1   -- tickrate
aura_env.smooth  = 0.1 -- smooth factor

aura_env.saved_from = {}
aura_env.saved_to   = {}
 
-------------------------------------------------------------------------------
aura_env.Reset = function()

	for i = 1,aura_env.slots do
		aura_env.saved_from[i]   = {} -- previous damage buffers (slots)
		aura_env.saved_to[i]     = {}
	end
	
	aura_env.buffer_from  = {} -- current damage buffer
	aura_env.buffer_to    = {}
	
	aura_env.result_from  = {}
	aura_env.result_to    = {}
	
	aura_env.time         = GetTime()
	aura_env.slot         = 1
end

-------------------------------------------------------------------------------
aura_env.OnDamage = function( source, dest, damage )
	aura_env.buffer_to[dest] = (aura_env.buffer_to[dest] or 0) + damage
	
	if source ~= dest then
		aura_env.buffer_from[source] = (aura_env.buffer_from[source] or 0) + damage
	end
end

-------------------------------------------------------------------------------
aura_env.OnFrame = function()
	local t = GetTime()
	if t >= aura_env.time + aura_env.rate then
		aura_env.RecordTick()
	end
end

-------------------------------------------------------------------------------
aura_env.GetResults = function( table, w )

	local added = {}
	  
	local sm = aura_env.smooth
	for slot = 1,aura_env.slots do
		for k,v in pairs( table[slot] ) do
			added[k] = (added[k] or 0) + v
		end
	end
	
	local divider = aura_env.slots * aura_env.rate
	
	for k,v in pairs( added ) do
		added[k] = v / divider
	end
	
	if w then
		aura_env.result_to   = added
	else
		aura_env.result_from = added
	end
end
 
-------------------------------------------------------------------------------
aura_env.RecordTick = function()
	aura_env.time = GetTime()
	aura_env.slot = aura_env.slot + 1
	if aura_env.slot > aura_env.slots then
		aura_env.slot = 1
	end
	
	aura_env.saved_from[aura_env.slot] = aura_env.buffer_from;
	aura_env.saved_to[aura_env.slot]   = aura_env.buffer_to;
	
	aura_env.buffer_from = {}
	aura_env.buffer_to   = {}
	
	aura_env.GetResults( aura_env.saved_from, false )
	aura_env.GetResults( aura_env.saved_to,   true  )
	 
	WeakAuras.ScanEvents( "WA_DPS_COMPUTER_FRAME" )
end

-------------------------------------------------------------------------------
aura_env.DPS = function( unit )
	local guid = UnitGUID( unit )
	if guid == nil then return 0 end
	
	return wa_dps_computer_data.result_from[guid] or 0
end

-------------------------------------------------------------------------------
aura_env.DTPS = function( unit )
	local guid = UnitGUID( unit )
	if guid == nil then return 0 end
	return wa_dps_computer_data.result_to[guid] or 0
end

-------------------------------------------------------------------------------
aura_env.Reset()

wa_dps_computer_data = aura_env
