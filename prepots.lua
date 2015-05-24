function( e, ... )
  
	if ... == nil then return false end
	
	local total = 0
	local used  = 0
	
	local names = ""
	
	for i = 1,40 do
		local unit = "raid" .. i
		if UnitExists( unit )
		   and UnitGroupRolesAssigned( unit ) ~= "HEALER" then
		   
		   total = total + 1
			
			local n =  UnitBuff( unit, "Draenic Armor Potion"     )
			        or UnitBuff( unit, "Draenic Agility Potion"   )
				    or UnitBuff( unit, "Draenic Strength Potion"  )
				    or UnitBuff( unit, "Draenic Intellect Potion" )
			
			if n ~= nil then
				used = used + 1
			else
				names = names .. UnitName( unit ) .. ", "
			end
		end
	end
	
	if names ~= "" then
		names = string.sub( names, 1, string.len( names ) - 2 )
		print( "Prepots missing: " .. names )
	end
	
	wa_prepot_data = {
		total = total,
		used = used
	}
	
	return true
end