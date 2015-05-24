
wa_bt_thogar_trainer = {
    active = false,
    start_time = 0,
    version = "3",
    
    cg1 = {
        [000] = "Encounter started",
        [005] = "Move to {green}; adds incoming",
        [028] = "Pass through fire; stay on {purple} (or {silver})",
        [044] = "Move to center and avoid trains (1)",
        [101] = "Move to center and avoid trains (2)",
        [119] = "Cannons incoming; stay on {green}",
        [142] = "Move to {purple}",
        [155] = "Move to {orange} when the train leaves",
        [227] = "Kill adds (spread for grenades) and move to center",
        [251] = "Kill adds; prep for flamewall",
        [304] = "Jump through fire; wait for train; move to {silver}; pass through next fire",
        [326] = "Move to center and avoid trains (1)",
        [344] = "Move to center and avoid trains (2)",
        [402] = "Cannons and adds incoming, everyone stay on {green} to drop fire.",
        [416] = "Move to {orange} track when train leaves",
        [428] = "Wait for trains to pass and move around deforester on {orange}",
        [446] = "Wait for trains to pass and move to {silver} (or split)",
        [503] = "Kill adds (spread for grenades)",
        [517] = "Move to center and more adds will be knocked over",
        [525] = "Move back to {silver}",
        [535] = "Move to center and avoid trains (1)",
        [553] = "Move to center and avoid trains (2)",
        [606] = "Move to center; cannon and adds incoming",
        [621] = "Move to right edge of {purple}, ranged stay in corner to drop pulses!",
        [642] = "Move behind the deforester on {green}, ranged stay in corner to drop pulses!",
        [707] = "Pick up adds, move through fire, and get behind deforester",
        [730] = "Pass through next fire and move to {purple}",
        [742] = "[[red]]Kill Thogar; ignore adds."
    },
    
    replace = {
        { "{green}",  "[[green]]green[[def]]"   },
        { "{purple}", "[[purple]]purple[[def]]" },
        { "{orange}", "[[orange]]orange[[def]]" },
        { "{silver}", "[[silver]]silver[[def]]" }
    },
    
    colors = {
        green  = { 0,   255,   0 },
        purple = { 166,  55, 208 },
        orange = { 255, 127,  30 },
        silver = { 233, 233, 255 },
        red    = { 255,  10,   3 },
        def    = { 244, 244, 244 }
    },
    
    preview_text = "(not active)\n\n00:00 ----------------------- Example Line 1 -----------------------\n00:30 ----------------------- Example Line 2 -----------------------\n00:45 ----------------------- Example Line 3 -----------------------\n01:07 ----------------------- Example Line 4 -----------------------"
}

local data = wa_bt_thogar_trainer
data.end_time = 0

data.cg = {}

for key,val in pairs(data.cg1) do
    local seconds = floor(key / 100) * 60 + key % 100
    
    table.insert( data.cg, {time = seconds, text = val} )
    data.end_time = max( data.end_time, seconds )
end

table.sort( data.cg, 
    function(a,b) 
        return a.time < b.time 
    end 
) 

for key,val in pairs(data.cg) do
    
    for rkey,rval in pairs(data.replace) do
        val.text = string.gsub( val.text, rval[1], rval[2] )
    end
end

-------------------------------------------------------------------------------
data.Start = function()
    
    if not data.active then 
        
        -- started mythic thogar
        data.active = true
        data.start_time = GetTime()
        data.current = 1
        data.cache = { text = nil, current = -1 }
    end
end

-------------------------------------------------------------------------------
data.Stop = function()
    
    if data.active then
        data.active = false
    end
    
end

-------------------------------------------------------------------------------
data.ColorCode = function( color, shade ) 
    return string.format( "|cFF%2x%2x%2x", 
        floor(color[1] * shade), 
        floor(color[2] * shade), 
        floor(color[3] * shade) )
end

-------------------------------------------------------------------------------
data.FormatColors = function( text, shade ) 
    
    local t = "[[def]]" .. text
    
    for key,color in pairs( data.colors ) do
        t = string.gsub( t, "%[%["..key.."%]%]", data.ColorCode( color, shade ))
        
        
    end
    return t
end

