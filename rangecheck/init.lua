-- item ids provided by LibRangeCheck-2.0
aura_env.checklist = {

	-- id,    spell, text
	
	{ "Jab",       true,  "|cff00ff00Melee" }, -- jab
	{ 37727,       false, "|cff00ff00Melee" }, -- ruby acorn
	{ 32321,       false, "< 10"            }, -- sparrowhawk net
	{ 111603,      false, "< 15"            }, -- bandage (help)
	{ 33069,       false, "< 15"            }, -- sturdy rope (harm)
	{ 21519,       false, "< 20"            }, -- mistleaf (help)
	{ "Paralysis", true,  "< 20"            }, -- paralysis (harm)
	{ 1180,        false, "< 30"            }, -- scroll of stam (help)
	{ 7734,        false, "< 30"            }, -- six demon bag (harm)
	{ "Provoke",   true,  "< 40"            }, -- provoke (change for 6.2!)
}

function aura_env.Text()
	if not UnitExists("target") then return "" end

	local y, x = UnitPosition("target")

	if y ~= nil then
		-- exact range.
		py,px = UnitPosition( "player" )
		y,x = y - py, x - px

		return string.format( "%.1f", math.sqrt(x^2+y^2) )
	end

	local a
	
	for k,v in pairs( aura_env.checklist ) do
		if v[2] == true then
			a = (IsSpellInRange( v[1], "target" ) == 1)
		else
			a = (IsItemInRange( v[1], "target" ) == true)
		end
		
		if a then return v[3] end
	end
 
	-- > 40 yards (red)
	return "|cffff0000> 40" 
end