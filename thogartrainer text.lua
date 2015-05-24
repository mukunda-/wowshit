function() 
    
    local data = wa_bt_thogar_trainer
    
    if not data.active then return "(not active)" end
    
    local time = (GetTime() - data.start_time)
    
    if data.cg[data.current+1] ~= nil then
        if time >= data.cg[data.current+1].time then
            data.current = data.current + 1
        end
    end
	local progress = round(time / data.end_time * 100)
	if progress > 100 then progress = 100 end
    
    local header = string.format( "%d:%02d  ", floor(time/60), time%60 ) .. progress .. "%%\n\n"
    
    if data.current == data.cache.current then
        return header .. data.cache.text
    end
    
    local text = ""
    local shades = { 0.5, 1.0, 0.5, 0.3 }
    
    for i = -1,2 do
        
        if data.current + i >= 1 then
            local entry = data.cg[data.current+i]
            if entry ~= nil then
                
                local shade = shades[ i + 2 ]
                local entry_text = entry.text
                
                local minutes, seconds = floor(entry.time / 60), entry.time % 60
                entry_text = string.format( "%d:%02d  ", minutes, seconds ) 
                .. entry_text
                
                entry_text = data.FormatColors( entry_text, shade )
                
                text = text .. entry_text .. "\n"
            else
                text = text .. "\n"
            end
        else
            text = text .. "\n"
        end
        
    end
    
    data.cache.current = data.current
    data.cache.text = text
    
    return header.. text
end

