function()

	local data = wa_flask_monitor
	
	data.throttle = data.throttle + 1
	if data.throttle ~= 5 then return data.missing ~= 0 end
	data.throttle = 0
	
	data.index = data.index + 1
	if data.index == 40 then data.index = 1 end
	
	local unit = "raid" .. data.index
	
	if UnitExists( unit ) then
	
		local n =  UnitBuff( unit, "Greater Draenic Stamina Flask"   ) 
		        or UnitBuff( unit, "Greater Draenic Intellect Flask" )
				or UnitBuff( unit, "Greater Draenic Agility Flask"   )
				or UnitBuff( unit, "Greater Draenic Strength Flask"  )
		
		if n == nil then
			data.players[data.index] = 1 -- missing flask
		else
			data.players[data.index] = nil
		end 
	else
		data.players[data.index] = nil
	end
	
	local missing = 0
	
	for i = 1,40 do
		if data.players[i] ~= nil then
			missing = missing + 1
		end
	end
	
	data.missing = missing
	
	return data.missing ~= 0
end