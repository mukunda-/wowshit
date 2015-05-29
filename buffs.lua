aura_env.next = 1
aura_env.on = false
aura_env.lastfound = 0

-------------------------------------------------------------------------------
aura_env.buffs = {

    stats = { 
	  "Mark of the Wild", "Legacy of the Emporer", 
	  "Legacy of the White Tiger", "Blessing of Kings", 
	  "Lone Wolf: Power of the Primates",
	  "Bark of the Wild", "Blessing of Kongs",
	  "Embrace of the Shale Spider", "Strength of the Earth" 
	},
	
	crit = { 
	  "Leader of the Pack", "Arcane Brilliance", "Dalaran Brilliance",
	  "Legacy of the White Tiger", "Lone Wolf: Ferocity of the Raptor",
	  "Terrifying Roar", "Fearless Roar", "Strength of the Pack",
	  "Embrace of the Shale Spider", "Still Water", "Furious Howl" 
	},
	  
	sp = { 
	  "Arcane Brilliance", "Dalaran Brilliance", "Dark Intent",
	  "Lone Wolf: Wisdom of the Serpent", "Serpent's Cunning",
	  "Qiraji Fortitude", "Still Water"
	},
	
	ap = {
	  "Horn of Winter", "Trueshot Aura", "Battle Shout"
	},
	
	stam = {
	  "Power Word: Fortitude", "Blood Pact", "Commanding Shout",
	  "Lone Wolf: Fortitude of the Bear", "Invigorating Roar", "Sturdiness",
	  "Savage Vigor", "Qiraji Fortitude"
	},
	
	mastery = {
	  "Power of the Grave", "Moonkin Aura", "Blessing of Might", 
	  "Grace of Air", "Lone Wolf: Grace of the Cat", "Roar of Courage",
	  "Keen Senses", "Spirit Beast Blessing", "Plainswalking"
	},
	
	haste = {
	  "Unholy Aura", "Mind Quickening", "Swiftblade's Cunning", 
	  "Grace of Air", "Lone Wolf: Haste of the Hyena", "Cackling Howl",
	  "Savage Vigor", "Energizing Spores", "Speed of the Swarm"
	},
	
	multistrike = {
	  "Windflurry", "Mind Quickening", "Swiftblade's Cunning", "Dark Intent",
	  "Lone Wolf: Quickness of the Dragonhawk", "Sonic Focus",
	  "Wild Strength", "Double Bite", "Spry Attacks", "Breath of the Winds"
	},
	
	versatility = {
	  "Unholy Aura", "Mark of the Wild", "Sanctity Aura", 
	  "Inspiring Presence", "Lone Wolf: Versatility of the Ravager",
	  "Tenacity", "Indomitable", "Wild Strength", "Defensive Quills",
	  "Chitinous Armor", "Grace", "Strength of the Earth"
	}
}

aura_env.spell = nil
aura_env.icon = ""

-------------------------------------------------------------------------------
aura_env.spell_list = {

	--- Monk ---
	[116781] = { "stats", "crit" },        -- Legacy of the White Tiger
	[115921] = { "stats" },                -- Legacy of the Emperpr
	
	--- Mage ---
	[61316]  = { "sp", "crit" },           -- Dalaran Brilliance
	[1459]   = { "sp", "crit" },           -- Arcane Brilliance
	 
	--- Paladin ---
	[20217]  = { "stats" },                -- Blessing of Kings
	[19740]  = { "mastery" },              -- Blessing of Might
	
	--- Priest ---
	[21562]  = { "stam" },                 -- Power Word: Fortitude
	
	--- Warrior ---
	[469]    = { "stam" },                 -- Commanding Shout
	[6673]   = { "ap" },                   -- Battle Shout
	
	--- Druid ---
	[1126]   = { "stats", "versatility" }, -- Mark of the Wild
	
	--- Death Knight ---
	[57330]  = { "ap" },                   -- Horn of Winter
	
	--- Warlock ---
	[109773] = { "sp", "multistrike" },    -- Dark Intent
	
	--- hunters are dum ---
}

-------------------------------------------------------------------------------
function aura_env.UpdateIcon()
	aura_env.icon = aura_env.spell and select( 3, GetSpellInfo( aura_env.spell )) or ""
end

-------------------------------------------------------------------------------
function aura_env.SetDefaultSpell()
	local _,player_class = UnitClass( "player" )
	
	aura_env.spell = nil
	
	if player_class == "MONK" then
		aura_env.spell = IsSpellKnown(116781) and 116781 or 115921
	elseif player_class == "MAGE" then
		aura_env.spell = IsSpellKnown(61316) and 61316 or 115921
	elseif player_class == "PALADIN" then
		aura_env.spell = 19740
	elseif player_class == "PRIEST" then
		aura_env.spell = 21562
	elseif player_class == "WARRIOR" then
		aura_env.spell = 6673
	elseif player_class == "DRUID" then
		aura_env.spell = 1126
	elseif player_class == "DEATHKNIGHT" then
		aura_env.spell = 57330
	elseif player_class == "WARLOCK" then
		aura_env.spell = 109773
	end
	
	aura_env.UpdateIcon()
end

-------------------------------------------------------------------------------
function aura_env.Check( unit )

	if (not UnitExists( unit )) or UnitIsDeadOrGhost( unit )
       or (not UnitIsConnected( unit )) then return end 
	   
	local hp = UnitHealth( unit )
	local hpm = UnitHealthMax( unit )
	if hp/ hpm < 0.5 then 
		-- only check healthy units, dying ones may lose buffs
		-- before they are actually dead
		return 
	end 

	local y,  x  = UnitPosition( unit )
	local py, px = UnitPosition( "player" )
	if y == nil then return end
	
	x, y = x - px, y - py
	local d = x^2 + y^2
	if d > 40*40 then return end -- out of range.
	
	for _,index in pairs( aura_env.spell_list[aura_env.spell] ) do
		local satisfied = false
		for _,buff in pairs( aura_env.buffs[index] ) do
			if UnitBuff( unit, buff ) then
				satisfied = true
				break
			end
		end
		if not satisfied then
			aura_env.on = true
			aura_env.lastfound = GetTime()
			return
		end
	end
end

-------------------------------------------------------------------------------
function aura_env.Update()
    local d = aura_env
		
	if aura_env.spell == nil then return false end
	if not IsSpellKnown( aura_env.spell ) then return false end
    
	-- scan one unitid per frame
	
    if d.next >= 1 and d.next <= 40 then
		-- raid1 thru raid40
        d.Check( "raid" .. d.next ) 
    elseif d.next >= 41 and d.next <= 45 then
		-- party1 thru party5
        d.Check( "party" .. (d.next-40) )
    else
		-- the player
        d.Check( "player" )
    end
    
    d.next = d.next + 1
    if d.next >= 47 then d.next = 1 end
	
	if d.on then
		-- timeout/someone else buffed.
		if (GetTime() - d.lastfound) > 3.0 then
			d.on = false
		end
	end
    
    return d.on
end

-------------------------------------------------------------------------------
function aura_env.Spellcast( spell )
	local d = aura_env
	
	if d.spell_list[spell] then
		d.spell = spell
		d.UpdateIcon()
		d.on = false
	end 
end

-------------------------------------------------------------------------------
aura_env.SetDefaultSpell()
