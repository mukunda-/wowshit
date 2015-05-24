function( e, ... ) 
    
    local _,evt,_,sourceGUID,_,_,_,destGUID,_,_,_,spellId,_,_,amount,_,_,_,_,_,_,absorb = ...
    
    if evt == "SWING_DAMAGE" then
        aura_env.OnDamage( sourceGUID, destGUID, spellId )
    elseif evt == "SPELL_DAMAGE" or evt == "SPELL_PERIODIC_DAMAGE" then
        
        aura_env.OnDamage( sourceGUID, destGUID, amount ) 
    end
    
end

