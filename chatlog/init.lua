aura_env.data = aura_env.data or {}

-------------------------------------------------------------------------------
function aura_env.Text()
    
    local name,realm = UnitName("target")
    local sex = UnitSex("target")
    if name == nil then 
        name,realm = UnitName("mouseover") 
        sex = UnitSex("mouseover")
    end
    
    if not name then return "" end
    if realm then name = name .. '-' .. realm end
    local data = aura_env.data[name]
    if not data then return "" end
    
    local text = ""
    
    local region = WeakAuras.regions[aura_env.id].region.text
    region:SetWidth( 400 )
    
	aura_env.BuildText( data, sex ) 
    return aura_env.text
    
end

-------------------------------------------------------------------------------
function aura_env.BuildText( data, sex )
	
	local text = ""
	
	if sex == 2 then sex = "He"
	elseif sex == 3 then sex = "She"
	else sex = "They" end
	
	for k,v in ipairs(data) do
	
		local msg = v.msg
	
		if v.type == 1 then
			msg = "|cffef5d0d".. msg 
		elseif v.type == 2 then
			msg = '|cfff18d0a'.. sex .. ' ' .. msg 
		elseif v.type == 3 then
			msg = '|cffffffff'.. msg
		elseif v.type == 4 then
			msg = '|cffff0000'.. msg
		elseif v.type == 5 then
			msg = '|cfff170d7'.. msg
		end
		
		local old = GetTime() - v.time
		
		local timecolor
		if old >= 600 then
			timecolor = "|cff222222"
		elseif old >= 300 then
			timecolor = "|cff444444"
		elseif old >= 60 then
			timecolor = "|cff666666"
		else
			timecolor = "|cff9999ff"
		end
		
		msg = timecolor .. v.stamp .. " " .. msg
		
		text = text .. msg .. "\n"
    end
    
	aura_env.text = text
end

-------------------------------------------------------------------------------
function aura_env.Log( event, message, sender )
	
	if message == nil then return end
	
	sender = Ambiguate( sender, "all" )
	aura_env.data[sender] = aura_env.data[sender] or {}
	
	local data = aura_env.data[sender]
	
	local time = date("*t")
	
	local type = 0
	
	if event == "CHAT_MSG_TEXT_EMOTE" then
		type = 1 
	elseif event == "CHAT_MSG_EMOTE" then
		type = 2 
	elseif event == "CHAT_MSG_SAY" then
		type = 3 
	elseif event == "CHAT_MSG_YELL" then
		type = 4 
	elseif event == "CHAT_MSG_WHISPER" then
		type = 5  
	end
	 
	if #data > 10 then
		table.remove( data, 1 ) 
	end
	
	table.insert( data, 
		{ type  = type,
		  msg   = message, 
		  stamp = string.format( "[%02d:%02d]", time.hour, time.min ), 
		  time  = GetTime() 
		})
		
end
