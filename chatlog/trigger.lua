function( event, message, sender, ... )
    
    if event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" then return true end
    
    aura_env.Log( event, message, sender )
    
    return true
end

