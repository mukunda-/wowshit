function( e, ...)
    
    local data = aura_env
    
    if e == "ENCOUNTER_START" then
        
        data.OnStart()
        
    elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
        
        local unit,_,_,_,spellId = ...
        if spellId == 156425 and unit == "boss1" then
            
            data.OnDemo()
        end
    end
end

