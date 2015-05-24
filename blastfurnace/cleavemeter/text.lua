function()
	local data = wa_bf_cleavemeter
	local vf,burn = data.GetStats()
	
	local icon_vf   = "|TInterface\\Icons\\Spell_Fire_LavaSpawn:0|t"
	local icon_burn = "|TInterface\\Icons\\Ability_Mage_FireStarter:0|t"
	
	return string.format( "%s  %d/%d  %s\n\n%s  %d/%d  %s", 
		icon_vf, data.fire_hits, data.fire_casts, vf,
		icon_burn, data.burn_hits, data.burn_casts, burn )
	
end
