-- combat log event logic
function( e, ... ) 
    
    local _,evt,_,sourceGUID,_,_,_,destGUID,_,_,_,spellId = ...
    local data = wa_bellows_roar
    
    if spellId == 155181 and evt == "SPELL_AURA_REMOVED" then
	
        -- an operator stopped loading.
        data.list[sourceGUID] = { roar = GetTime() + data.cd }
        
        
    elseif spellId == 178114 and evt == "SPELL_CAST_SUCCESS" then
	
        -- an operator just roared
        data.list[sourceGUID] = { roar = GetTime() + data.cd + 2 }
	elseif evt == "UNIT_DIED" then
	
		if data.list[sourceGUID] ~= nil then
			data.list[sourceGUID] = nil
		end
    end
    
    return false
end

