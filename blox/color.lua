function( progress, r1, g1, b1, a1, r2, g2, b2, a2 )
    
	local data = wa_blox_hp
	
    local t = (GetTime() - data.last_hit) / 0.25
	t = math.max( math.min( t, 1.0 ), 0.0 )
	
    t = 1.0 - t
    return r1 + ( t * (r2-r1) ), 
	       g1 + ( t * (g2-g1) ), 
		   b1 + ( t * (b2-b1) )
    
end
