wa_improved_stagger_data = aura_env

aura_env.stagger  = 0 -- current stagger value
aura_env.stagger1 = 0 -- current stagger value / health
aura_env.smooth   = 0 -- smooth amount
aura_env.smooth1  = 0 -- smooth amount / health (and clipped)
aura_env.stage    = 1
aura_env.purified = 0
aura_env.chi      = 0
aura_env.chi2     = 0
aura_env.stime    = 0

-------------------------------------------------------------------------------
function aura_env.OnCombat( ... ) 
	local _,evt,_,_,_,_,_,destGUID,_,_,_,thing,_,_,spell1,spell2,spell3,spell4,spell5,spell6 = ...
	
	local guid = UnitGUID( "player" ) 
	if destGUID ~= guid then return end
	
	if evt == "SPELL_ABSORBED" then
	
		local shielder, spellid, amount
		
		if thing == guid then
			-- swing damage.
			shielder,_,_,_,spellid,_,_,amount = select( 12, ... )
			
		else
			-- spell damage or something else
			shielder,_,_,_,spellid,_,_,amount = select( 15, ... )
		end
		
		if shielder == guid and spellid == 115069 then
			-- stagger.
			aura_env.stagger = aura_env.stagger + amount
			aura_env.purified = 0
			aura_env.stime    = GetTime()
		end
	elseif evt == "SPELL_PERIODIC_DAMAGE" then
		if thing == 124255 then
			spell1 = spell1 + (spell4 or 0) + (spell6 or 0)
			aura_env.stagger = aura_env.stagger - spell1
			
		end
	elseif evt == "SPELL_PERIODIC_MISSED" then
		if thing == 124255 then
			aura_env.stagger = aura_env.stagger - (spell4 or 0)
			
		end
	end
end

-------------------------------------------------------------------------------
function aura_env.Purified()
	aura_env.stagger = 0
	aura_env.purified = GetTime()
end

-------------------------------------------------------------------------------
function aura_env.OnSpellcast( spellid )
	if spellid == 119582 then
		aura_env.Purified()
		
	elseif spellid == 157676 then
		if aura_env.chi2 >= 3 then
			aura_env.Purified()
		end
	end
end
-------------------------------------------------------------------------------
function aura_env.OnPower( type )
	if type == "CHI" then
		aura_env.chi2 = aura_env.chi
		aura_env.chi = UnitPower( "player", SPELL_POWER_CHI )
	end
end

-------------------------------------------------------------------------------
function aura_env.OnAbsorbChanged()
	 
end

-------------------------------------------------------------------------------
function aura_env.OnPlayerDead()
	aura_env.stagger = 0
end	

-------------------------------------------------------------------------------
function aura_env.Refresh()
	if GetTime() >= aura_env.stime + 5 and UnitStagger( "player" ) == 0 then
		aura_env.stagger = 0
	end
	
	if aura_env.stagger < aura_env.smooth then
		aura_env.smooth = aura_env.smooth * 0.9 + aura_env.stagger * 0.1
	else
		aura_env.smooth = aura_env.stagger
	end 
	
	if aura_env.smooth < 100 then aura_env.smooth = 0 end
	
	aura_env.stagger1 = aura_env.stagger / UnitHealthMax( "player" )
	aura_env.smooth1  = aura_env.smooth  / UnitHealthMax( "player" )
	
	aura_env.smooth1 = math.max( aura_env.smooth1, 0 )
	aura_env.smooth1 = math.min( aura_env.smooth1, 1 )
	
	if aura_env.stagger1 >= 0.7 then
		aura_env.stage = 3
	elseif aura_env.stagger1 >= 0.3 then
		aura_env.stage = 2
	else
		aura_env.stage = 1
	end
	
	return UnitAffectingCombat("player") or aura_env.stagger > 5000
end

-------------------------------------------------------------------------------
function aura_env.BaseColor()
	if aura_env.stage == 3 then
		return 1,0,0
	elseif aura_env.stage == 2 then
		return 1.0, 152/255, 26/255
	elseif aura_env.stage == 1 then
		return 0.67, 1.0, 0.66
	end
end

-------------------------------------------------------------------------------
function aura_env.Color()
	local r,g,b = aura_env.BaseColor()
	--local t = GetTime() - aura_env.purified
	
	if aura_env.purified > 0 then
		return 0,0.7,1
	end
	
		--[[
	if t >= 0 and t < 0.25 then
		t = 1-(t / 0.25)
		r,g,b = r + (0-r) * t,
		        g + (0-g) * t,
		        b + (1-b) * t
	end	
	]]
	return r,g,b
end
