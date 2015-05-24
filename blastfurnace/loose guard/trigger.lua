function( e, ... )
	local _,evt,_,sourceGUID,sourceName,_,_,destGUID,destName = ...
	
	-- requires engibomb aura
	local engib = wa_bf_engibomb_data
	if engib == nil then return false end
	
	if evt == "SWING_DAMAGE" and sourceName == "Security Guard" then
		
		local unit = engib.RaidFromGUID( destGUID )
		if unit == nil then return false end
		
		local role = UnitGroupRolesAssigned( unit )
		if role == "DAMAGER" or role == "HEALER" then
			
			local myside = engib.UnitSide( "player" )
			local side = engib.UnitSide( unit )
			if myside == side then 
				return true
			end
		end
	end
	
	return false
end
