function( e, ... ) 
	
	local data = wa_bf_engibomb_data
	
	local _,evt,_,sourceGUID,sourceName,_,_,destGUID,destName,_,_,spellId = ...
	
	if not (UnitName( "boss3" ) == "Heat Regulator" or UnitName( "boss4" ) == "Heat Regulator") then
		return false -- not on that phase.
	end
	
	if string.find( evt, "SWING" ) then
		if sourceName == "Furnace Engineer" then
			-- engineer meleed someone
			data.RecordPosition( sourceGUID, destGUID )
			
		elseif destName == "Furnace Engineer" then
			-- someone meleed engineer
			data.RecordPosition( destGUID, sourceGUID )
			
		end
		
	elseif evt == "SPELL_DAMAGE" then
		if sourceName == "Furnace Engineer" then
			-- engineer attacked someone
			data.RecordPosition( sourceGUID, destGUID )
			
		--elseif destName == "Furnace Engineer" then
		--	-- someone attacked engineer
		--	data.RecordPosition( destGUID, sourceGUID )
		--	
		end
		
	elseif evt == "SPELL_SUMMON" then
		if sourceName == "Furnace Engineer" and destName == "Cluster of Lit Bombs" then
			data.BombsDropped( sourceGUID, destGUID )
		end
	elseif evt == "SPELL_AURA_APPLIED" then
		if sourceName == "Cluster of Lit Bombs" and spellId == 174716 then
			data.BombTaken( sourceGUID )
		end
	
	elseif evt == "UNIT_DIED" then
		if destName == "Cluster of Lit Bombs" then
			data.SackDied( destGUID )
		
		end
		-----------debug----------- 
--	elseif evt == "SPELL_CAST_SUCCESS" and spellId == 116781 then
--	
--		debug1 = debug1 or 1
--	
--		data.RecordPosition( "dummy_engi" .. debug1, sourceGUID )
--		data.BombsDropped( "dummy_engi" .. debug1, "dummy_bombs" .. debug1 )
--		
--		debug1 = debug1 + 1
--	
		-----------debug-----------
	end
	
	return false
end
