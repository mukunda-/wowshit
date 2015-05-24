function( e, ... ) 
    
    if e == "ENCOUNTER_START" then
        -- started an encounter
        
        local id,_,diff = ...
        if id == nil then return false end
        
        
        print( "debug:  encounter id = " .. id )
        
        if id == 1691 then
            
            -- started gruul
            wa_bt_gruul = {
                tanks = {nil,nil,nil},
                order = {6,6,3,4,4},
                next_slice = 0, -- which mark for next slice 
                slice_time = 0, -- the time when the last slice happened
                last_blows = 0, -- time of last overwhelming blows (to filter multiples)
                last_slice = 0  -- time of last inferno slice
            }
            
            if diff ~= 16 then
                -- non mythic order:
                wa_bt_gruul.order = {6,4}
            end
            
        else
            wa_bt_gruul = nil
        end
        
        return false
    end
    
    if wa_bt_gruul == nil then 
        -- gruul encounter is not active.
        
        return false 
    end
    
    local data = wa_bt_gruul 
    
    if e == "ENCOUNTER_END" then
        local id,_,diff = ...
        if id == nil then return false end
        if id == 1691 then 
            wa_bt_gruul = nil  
            print( "debug: encounter ended.")
            if wa_bt_gruul == nil then print("shit") end
            
        end
        
        
    elseif e == "COMBAT_LOG_EVENT_UNFILTERED" then
        
        local bossGUID = UnitGUID( "boss1" )
        if bossGUID == nil then return false end
        
        local _,clevent,_,sourceGUID,_,_,_,targetGUID,_,_,_,spellid = ...
        if sourceGUID ~= bossGUID then return false end
        
        if clevent == "SPELL_AURA_APPLIED" or clevent == "SPELL_AURA_APPLIED_DOSE" then
            
            if spellid == 155539 then
                -- destructive rampage
                
                print( "debug: rampage")
                -- destructive rampage, rotate the tanks.
                
                local a = data.tanks[1]
                data.tanks[1] = data.tanks[2]
                data.tanks[2] = data.tanks[3]
                data.tanks[3] = a
                
                -- reset the slice order
                data.next_slice = 0
            end
            
        elseif clevent == "SPELL_DAMAGE" or clevent == "SPELL_ABSORB" or clevent == "SPELL_MISSED" then
            
            if spellid == 155078 then
                -- overwhelming blows
                
                if UnitPower( "boss1" ) >= 80 then
                    -- ignore blows at high energy, assuming something fucked up.
                    return false
                end
                
                if GetTime() < data.last_blows + 1 then
                    return false
                end
                
                data.last_blows = GetTime()
                
                local raidid = UnitInRaid( "boss1target" )
                if raidid == nil or raidid == 0 then return false end
                raidid = "raid" .. raidid
                
                if UnitGroupRolesAssigned(raidid) ~= "TANK" then
                    -- not a tank, ignore
                end
                
                if data.tanks[1] == raidid then return false end
                
                print( "Debug overwhelming blows!")
                
                if data.tanks[1] == nil then
                    -- initialize tanks
                    data.tanks[1] = raidid
                    data.tanks[2] = nil
                    data.tanks[3] = nil
                else
                    -- rotate the tanks.
                    
                    local a = data.tanks[1]
                    data.tanks[1] = raidid
                    
                    if data.tanks[2] == raidid then
                        -- they rotated properly
                        data.tanks[2] = data.tanks[3]
                        data.tanks[3] = a
                    else
                        -- something messed up
                        if data.tanks[3] == raidid then
                            data.tanks[3] = nil
                        end
                        -- try to recover...
                        
                    end 
                end
            end
            
        elseif clevent == "SPELL_CAST_SUCCESS" then
            
            if spellid == 155080 then
                
                if GetTime() < data.last_slice + 1 then
                    return false
                end
                
                data.last_slice = GetTime()
                
                local raidid = UnitInRaid( "boss1target" )
                if raidid == nil or raidid == 0 then return false end
                raidid = "raid" .. raidid
                
                print( "debug: inferno slice!")
                -- inferno slice casted
                data.slice_time = GetTime()
                data.next_slice = ((data.next_slice+1) % table.getn( data.order ))
                
                if data.tanks[1] == raidid then return false end -- something went wrong.
                
                if UnitGroupRolesAssigned(raidid) ~= "TANK" then
                    -- not a tank, ignore
                end
                
                if data.tanks[2] == nil then 
                    -- initialize the slice tank
                    
                    data.tanks[2] = raidid 
                else
                    -- we only use the first slice to initialize, the rest
                    -- are determined by the rotation
                    if data.tanks[2] ~= raidid then
                        data.tanks[2] = raidid
                        data.tanks[3] = nil
                    end
                    
                end
                
            end
        end 
    end
    
    return false
end

