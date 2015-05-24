function()
	
	local my_x, my_y = UnitPosition( "player" )
	local data = wa_bf_volatile_fire
	data.active = false
	data.expires = 99999999
	data.name = "Unknown"
	
	local playerGUID = UnitGUID( "player" )
	
	for i = 1,20 do
		
		local unit = "raid" .. i
		
		local name,_,_,_,_,duration,expires = UnitDebuff( unit, "Volatile Fire" )
		if name ~= nil then
			if UnitGUID( unit ) ~= playerGUID then
				local x,y = UnitPosition( unit )
				
				local d = (my_x-x)^2 + (my_y-y)^2
				
				if d < 8*8 then
					data.active = true
					data.duration = duration
					data.expires = math.min( data.expires, expires )
					data.name = UnitName( unit )
				end
			end
		end
	end
	
	return data.active
end