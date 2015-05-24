function( e, ... )
  
	if ... == nil then return false end
	
	local total = 0
	local used  = 0
	 
	for i = 1,40 do
		local unit = "raid" .. i
		if UnitExists( unit ) then
		   
			total = total + 1
			
			local n =  UnitBuff( unit, "Hyper Augmentation" )
			        or UnitBuff( unit, "Focus Augmentation" )
				    or UnitBuff( unit, "Stout Augmentation" )
			
			if n ~= nil then
				used = used + 1 
			end
		end
	end
	 
	wa_augrunes_data = {
		total = total,
		used = used
	}
	
	return true
end