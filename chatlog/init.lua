aura_env.data = aura_env.data or {}

function aura_env.Text()
    
    local name,realm = UnitName("target")
    local sex = UnitSex("target")
    if name == nil then 
        name,realm = UnitName("target")
        
        sex = UnitSex("mouseover")
    end
    
    if realm then name = name .. '-' .. realm end
    if not name then return "" end
    local data = aura_env.data[name]
    if not data then return "" end
    
    local text = ""
    
    local region = WeakAuras.regions[aura_env.id].region.text
    region:SetWidth( 400 )
    
    for k,v in ipairs(data) do
        text = text .. v .. "\n"
    end
    return text
    
end

function aura_env.Log( event, message, sender )
	
	if message == nil then return end
	
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
	 
	if #data > 10 then
		table.remove( data, 1 ) 
	end
	
	table.insert( data, 
		{ msg   = message, 
		  stamp = string.format( "[%02d:%02d]", time.hour, time.min ), 
		  time  = GetTime() 
		})
		
end

function( event, message, sender, channelString, target, flags, unkn, channelNumber, channelName )
    
    if event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" then return true end
    
    if message ~= nil then
        
        
        
    end
    
    return true
end

