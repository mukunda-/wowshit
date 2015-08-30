function( event, message, sender, channelString, target, flags, unkn, channelNumber, channelName )
    
    if event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" then return true end
    
    if message ~= nil then
        
        
        sender = Ambiguate( sender, "all" )
        aura_env.data[sender] = aura_env.data[sender] or {}
        
        local data = aura_env.data[sender]
        
        local time = date("*t")
        
        if event == "CHAT_MSG_TEXT_EMOTE" then
            message = "|cffef5d0d".. message 
        elseif event == "CHAT_MSG_EMOTE" then
            message = '|cfff18d0a'.. sender .. ' ' .. message 
        elseif event == "CHAT_MSG_SAY" then
            message = '|cffffffff'.. message
        elseif event == "CHAT_MSG_YELL" then
            message = '|cffff0000'.. message
        elseif event == "CHAT_MSG_WHISPER" then
            message = '|cfff170d7'.. message
            
        end
        
        message = "|cff999999" .. string.format("[%02d:%02d] ",time.hour, time.min ) .. message
        
        
        if #data > 10 then
            table.remove( data, 1 ) 
        end
        
        table.insert( data, message )
    end
    
    return true
end
