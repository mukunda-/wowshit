function()

	if not (UnitName( "boss3" ) == "Heat Regulator" or UnitName( "boss4" ) == "Heat Regulator") then
		return false -- not on that phase.
	end
	
	local data = wa_bf_engibomb_data
	
	local side = data.UnitSide( "player" )
	
	-- not on a side.
	if side == nil then
		data.show = false
		return false
	end
	
	local bombs = 0
	local time = GetTime()
	local expires = time + 60
	
	
	for k,v in pairs( data.sacks ) do
		if v.side == side and v.bombs > 0 then
		
			if time < v.expires then
				bombs = bombs + v.bombs
				expires = min( expires, v.expires )
			end
			
		end
	end
	
	if bombs > 0 then
		data.bombs = bombs
		data.show = true
		data.expires = expires
	end
		
	return data.show
end