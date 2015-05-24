function( e, ... ) 
	local data = wa_bf_cleavemeter
	
	if e == "ENCOUNTER_START" then
	
		data.Reset()
		
	elseif e == "ENCOUNTER_END" then
	
		local id,name,diff,raidsize,endstatus = ...
		
		if not (id == 1690 and diff == 16 and endstatus == 0) then
			return false
		end
		
		local vf, burn, score = data.GetStats()
		 
		if vf == "---" and burn == "---" then 
			return false 
		end 
		
		SendChatMessage( 
		    "[CleaveMeter] VF: " .. vf .. ", Burn: " .. burn .. ", Score: " .. score, "RAID" )
	
	end
	
	return false
end
