function()
	
	local data = wa_bf_heatregs
	
	if data.left == nil and UnitName( "boss3" ) == "Heat Regulator" 
	                    and UnitName( "boss4" ) == "Heat Regulator" then
						
		data.left  = UnitGUID( "boss3" )
		data.right = UnitGUID( "boss4" )
		
	end
	
	local left, right
	left  = 0
	right = 0
	
	if UnitGUID( "boss3" ) == data.left then
		left = UnitHealth( "boss3" )
	elseif UnitGUID( "boss4" ) == data.left then
		left = UnitHealth( "boss4" )
	end
	
	if UnitGUID( "boss3" ) == data.right then
		right = UnitHealth( "boss3" )
	elseif UnitGUID( "boss4" ) == data.right then
		right = UnitHealth( "boss4" )
	end
	
	local a = math.ceil(left / 100000)
	local b = math.ceil(right / 100000)
	
	return "Left: " .. a .. " | Right: " .. b
	
end
