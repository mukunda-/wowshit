wa_bellows_roar = {
    
    -- cd of deafening roar
    cd = 6.0,
    
    -- show the weakaura
    show = false,
    
    -- list of operators, indexed by guid
    list = {}
}

wa_bellows_roar.GetRoarTime = function( guid )
    local data = wa_bellows_roar
    if data.list[guid] == nil then return nil end
    
    local t = data.list[guid].roar - GetTime()
    t = math.max(t,0)
    return t
    
end

