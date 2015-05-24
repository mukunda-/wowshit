function( e, ... )
    local data = wa_bellows_roar
    
    if e == "ENCOUNTER_START" then
        
        data.list = {}
        data.show = false
        
        return false
    end
    
    local guid = UnitGUID( "target" )
    if data.list[guid] ~= nil then
        -- targeting an active bellows operator
        data.show = true
        data.target = guid
        
    else
        data.show = false 
    end
    
    return false
end

