-------------------------------------------------------------------------------
-- Black Ox Health Tracker by mukunda (www.mukunda.com)
-------------------------------------------------------------------------------

function( e, ... )
	local _,evt,_,sourceGUID,_,_,_,destGUID,_,_,_,spellId,spellName,_,damage = ...
	local data = wa_blox_hp
	
	if spellId == 115315 and evt == "SPELL_SUMMON" 
			and sourceGUID == UnitGUID( "player" ) then
			
		-- player summoned black ox
		data.guid       = destGUID
		data.active     = true
		data.hp         = UnitHealthMax( "player" ) / 2
		data.hp_max     = data.hp 
		data.hp_display = 100
		data.last_hit   = 0
		
		return false
	end
	
	if destGUID == data.guid and string.find( evt, "_DAM" ) then
	
		-- SWING has damage at 12th param (spellId)
		if evt == "SWING_DAMAGE" then damage = spellId end
		-- ENVIRONMENTAL has damage at 13th param (spellName)
		if evt == "ENVIRONMENTAL_DAMAGE" then damage = spellName end
		
		data.hp       = math.max( data.hp - damage, 0 )
		data.last_hit = GetTime() 
	end
	
	return false
end
