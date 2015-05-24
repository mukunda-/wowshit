function()

	local data = wa_bellows_roar
	if not data.show then return 0,0,false end
	
	local operator = data.list[data.target]
	if operator == nil then return 0,0,false end
	
	local roar = operator.roar
	
	return GetTime() - roar, 6.0, true
end