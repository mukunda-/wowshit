local data = aura_env

-------------------------------------------------------------------------------
data.Reset = function()
    data.count    = 0
    data.time     = 0
    data.progress = 0
    data.color    = 0 -- WAIT
end

data.Reset()
 
-------------------------------------------------------------------------------
data.Inside = function()

	-- monks are always inside kiddo
	if UnitClass("player") == "Monk" then return true end
	
	local y,x = UnitPosition( "player" )
    local cy,cx = 568.7, 3494.8
    local d = (x-cx)^2 + (y-cy)^2
	 
	return d < 24^2
end
 
-------------------------------------------------------------------------------
data.OnDemo = function() 
	
    data.count = data.count + 1
    data.time  = GetTime()
	data.help  = false
end

-------------------------------------------------------------------------------
data.Refresh = function()
    
	
    local hp  = UnitHealth( "boss1" ) or 0
    local hpm = UnitHealthMax( "boss1" ) or 0 
    if hpm == 0 then return false end
	
    hp = hp / hpm
    
    if hp < 0.68 then return false end -- not on phase1
	
    local data = aura_env
	
    if data.count == 0 then return false end -- demos haven't started
    
    local t = GetTime() - data.time
    if t < 0 or t >= 12 then return false end -- demo ended
	
	local teleported = UnitDebuff( "player", "Demonic Gateway" )
     
	local next = 0
	local duration = 3
     
    if t <= 2.9 then
	
		next       = 2.9
		duration   = 2.9
		data.move  = 0
        data.label = "WAIT!"
        
    elseif t <= 5.9 then
        
		next       = 5.9
		duration   = 3.0
		data.move  = 1
		data.label = "MOVE TO RIGHT"
        
    elseif t <= 8.9 then
	
		next       = 8.9
		duration   = 3.0
        data.move  = 0
        data.label = "WAIT"
        
    elseif t <= 12 then
	
		next       = 12
		duration   = 3.1
        data.move  = 1
        
		if teleported or data.count ~= 3 then
			data.label = "MOVE TO LEFT"
		else
			data.label = "PORTAL TO LEFT"
		end
        
    end
	
	local marked,_,_,_,_,markdur,markexp = UnitDebuff( "player", "Marked for Death" )
	
	if marked then
		markexp = markexp - data.time
		local derptime = 0.7 -- time needed to click the portal
		if markexp < 8.9 then
			-- this shouldn't happen (ignore)
			
		elseif markexp < 8.9 + 1.0 + derptime then
			-- 1.0 seconds to teleport, plus time to click
			-- mark expires before there is enough time to teleport
			
			data.move  = 2 -- marked+wait color
			next       = markexp
			duration   = 5
			data.label = "WAIT AND PORTAL/BLINK"
			
			if teleported then
				data.move = 3 -- danger
				data.label = "WAIT AND SURVIVE/BLINK"
				
				data.HelpMe()
			end
		else
			-- mark expires with enough time to teleport 
			
			if teleported then
				data.move  = 3 -- danger
				next       = markexp
				duration   = 5
				
				if t <= 8.9 or (markexp < 8.9+2.0) then
					data.label = "WAIT AND SURVIVE"
				else
					data.label = "BLINK OR SURVIVE!"
				end
				
				data.HelpMe()
			else
				if t > 8.9 and data.move == 1 then
					data.label = "TELEPORT MARK!!"
				
				elseif data.move == 0 then
					data.label = "PREPARE TO TELEPORT"
				end
			end
		end
	
	end
	
	data.progress = (next - t) / duration
	data.progress = math.min( data.progress, 1 )
	data.progress = math.max( data.progress, 0 )
	
	if data.move == 0 or data.move == 2 or data.move == 3 then
		-- inversed
		data.progress = 1 - data.progress
	end
	
	-- and finally, everything gets overwritten if the person is outside.
	if t <= 9.0 then
		if not data.Inside() then
			data.move     = 4 -- too far
			data.label    = "TOO FAR OUT!"
			data.progress = 1.0
		end
	end
	
    return true
end

-------------------------------------------------------------------------------
data.HelpMe = function() 
	if not data.help then
	
		if UnitClass( "player" ) == "Hunter" then
			-- deterrence and ignore damage like the dum idiot hutner you are
			return
		end
		data.help = true
		SendChatMessage( "help.", "YELL" )
		DoEmote( "helpme" )
	end
end

-------------------------------------------------------------------------------
data.GetColor = function()

	local c = math.sin(GetTime()*10) * 0.1
		
	if data.move == 0 then     -- wait
		return 0.9,0.0,0.0,1.0
	elseif data.move == 1 then -- go
		return 0.0,1.0,0.0,1.0
	elseif data.move == 2 then -- marked
		return 0.0,0.5+c,1.0+c,1.0
	elseif data.move == 3 then -- danger
		return 1.0+c,0.5+c,0.0,1.0
	elseif data.move == 4 then -- 
		c = math.sin(GetTime()*20) * 0.1
		return 0.3+c,0.3+c,0.3+c,1.0
	end
end

-------------------------------------------------------------------------------
data.OnEvents = function( e, ... )

	if e == "ENCOUNTER_START" then
        
        data.Reset()
        
    elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
        
        local unit,_,_,_,spellId = ...
        if spellId == 156425 and unit == "boss1" then
            data.OnDemo()
			
        end
		
		--[[ testmode
		if spellId == 116781 and unit == "player" then
			data.OnDemo()
		end
		--]]
    end
end
 