-------------------------------------------------------------------------------

aura_env.time     = 0		-- time of next mortar
aura_env.active   = false	-- show the aura
aura_env.duration = 0		-- current bar progress 0-1
aura_env.speeds   = { 30, 20, 10, 6, 3, 1.5 } -- energy fill rate for each overdrive setting
aura_env.move     = false

-------------------------------------------------------------------------------
function aura_env.Refresh() 
	aura_env.time   = GetTime() + aura_env.speeds[1]
	aura_env.active = false
	
	for i = 2,5 do 
		aura_env.Scan( "boss" .. i ) 
	end
	
	if aura_env.active then
		-- compute duration
		local t = aura_env.time - GetTime()
		t = math.min( t, 30 )
		t = math.max( t, 0 )
		local d
		
		if t < 10 then
			-- move away
			
			aura_env.move = true
			d = t / 10
		else
			-- attack
			t = t - 10
			 
			t = math.max( t, 0 )
			t = math.min( t, 10 )
			
			aura_env.move = false
			d = t / 10
		end
		
		if math.abs( aura_env.duration - d ) > 0.4 then
			-- the time jumped
			aura_env.duration = d
		else
			-- smooth out glitches in timing inaccuracy
			aura_env.duration = aura_env.duration * 0.9 + d * 0.1
		end
	end
	
	
	return aura_env.active
end

-------------------------------------------------------------------------------
function aura_env.Scan( unit )

	local name = UnitName( unit )
	if name == nil then return end
	if not string.find( name, "Siegemaker" ) then return end
	if UnitHealth( unit ) == 0 then return end -- its dead
	
	-- found a siegemaker.
	
	local _,_,_,count = UnitBuff( unit, "Overdrive" )
	
	-- speed 2 is 1 stack
	count = (count or 0) + 1
	
	if count < 1 then count = 1 end
	if count > 6 then count = 6 end
	
	local seconds = aura_env.speeds[count]
	-- number of seconds needed to gain 100 energy
	
	local energy = 100 - UnitPower( unit )
	-- remaining energy to fill
	
	local time = GetTime() + energy / 100 * seconds
	
	aura_env.time = math.min( aura_env.time, time )
	aura_env.active = true
    
end

