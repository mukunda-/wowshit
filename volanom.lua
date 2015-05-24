-- ****************************************************************************
-- Llanna's Volatile Anomaly Tracker
-- ****************************************************************************

function(event, ... )

    if WA_Volanom == nil then WA_Volanom = 0 end
    
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        
        local unitID,spell,rank,lineID,spellID = select( 1, ... )
        
		-- spellids for margok teleporting to summon adds (borrowed from dbm)
        if spellID == 164751 or spellID == 164810 then
            WA_Volanom = 18
        end
		
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        
        local evt,_,_,_,_,_,_,destName = select( 2, ... )
        
        if evt == "UNIT_DIED" and destName == "Volatile Anomaly" then
            
            if WA_Volanom > 0 then
                WA_Volanom = WA_Volanom - 1
            end
        end
		
	elseif event == "PLAYER_REGEN_DISABLED" then
		-- reset at start
		WA_Volanom = 0 
    end
    
    return false
end

