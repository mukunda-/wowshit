wa_bf_cleavemeter = {}

wa_bf_cleavemeter.Reset = function()
    local data = wa_bf_cleavemeter
    
    data.burn_casts = 0
    data.burn_hits  = 0
    data.fire_casts = 0
    data.fire_hits  = 0
end

wa_bf_cleavemeter.Reset()


wa_bf_cleavemeter.GetStats = function()
    local data = wa_bf_cleavemeter
    local vf,burn,vf2,burn2 
    local score
    
    if data.fire_casts > 0 then
        vf = string.format( "%.2f", (data.fire_hits / data.fire_casts) - 1 )
        vf2 = (data.fire_hits / data.fire_casts) - 1
    else
        vf = "---"
        vf2 = 0
    end
    
    if data.burn_casts > 0 then
        burn = string.format( "%.2f", (data.burn_hits / data.burn_casts) - 1 )
        burn2 = (data.burn_hits / data.burn_casts) - 1
    else
        burn = "---"
        burn2 = 0
    end
    
    score = 9999 / (1 + vf + burn * 0.3)
    
    return vf, burn, score
end

