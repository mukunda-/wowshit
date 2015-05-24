-- cleave meter

function( e, ... )
	local _,evt,_,sourceGUID,sourceName,_,_,destGUID,destName,_,_,spellId
	local data = wa_bf_cleavemeter
	
	if spellId == 155200 and evt == "SPELL_CAST_SUCCESS" then
	
		data.burn_casts = data.burn_casts + 1
		
	elseif spellId == 177744 and evt == "SPELL_DAMAGE" then
		
		data.burn_hits = data.burns_hits + 1
	
	elseif spellId == 176121 and evt == "SPELL_AURA_REMOVED" then
	
		data.fire_casts = data.fire_casts + 1
		
	elseif spellId == 176123 and evt == "SPELL_DAMAGE" then
	
		data.fire_hits = data.fire_hits + 1
		
	end 
	
	return false
end