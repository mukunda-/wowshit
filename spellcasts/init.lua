
wa_spellcasts_texes = wa_spellcasts_texes or {}
aura_env.texes      = wa_spellcasts_texes
aura_env.texcount   = 5 -- requires reload if changed.
aura_env.name       = "Spellcasts"
aura_env.spells     = {}

	
-------------------------------------------------------------------------------
local function Setup()
	
	local region = WeakAuras.regions["Spellcasts"].region
	aura_env.region = region
	

	for i = 1, aura_env.texcount do 
		if aura_env.texes[i] == nil then
			aura_env.texes[i] = region:CreateTexture()
			
		end
		
		aura_env.spells[i] = { time = -100 }
		
		aura_env.texes[i]:ClearAllPoints()
		aura_env.texes[i]:SetPoint( "TOPLEFT", region )
		aura_env.texes[i]:SetSize( region:GetSize() )
		aura_env.texes[i]:SetTexCoord( 0.1, 0.9, 0.1, 0.9 )
		 
		aura_env.texes[i]:SetDrawLayer( "ARTWORK", 1 + aura_env.texcount - i ) 
		
	end
	
end

Setup()

-------------------------------------------------------------------------------
function aura_env.PushSpell( id ) 
	for i = aura_env.texcount-1, 1, -1 do 
		aura_env.spells[i+1] = aura_env.spells[i]
		aura_env.spells[i+1].dirty = true
	end
	
	local _,_,tex = GetSpellInfo( id )
	
	aura_env.spells[1] = { id = id, time = GetTime(), tex = tex, dirty = true }
end

-------------------------------------------------------------------------------
function aura_env.UpdateTex( i )

	local duration = 1.5
	local slide    = -120
	
	local spell = aura_env.spells[i]
	local time = GetTime() - spell.time
	local interp = time / duration
	interp = math.min( interp, 1.0 )
	
	if time >= duration then
		-- expired.
		aura_env.texes[i]:SetVertexColor( 1,1,1,0 )
		return
	end
		
	aura_env.texes[i]:SetPoint( "TOPLEFT", aura_env.region, 0, slide * interp )
	
	local alpha = 1.0 - interp^2
	aura_env.texes[i]:SetVertexColor( 1,1,1, alpha )
	
	if spell.dirty then
		spell.dirty = false
		aura_env.texes[i]:SetTexture( spell.tex )
	end
	
end

-------------------------------------------------------------------------------
function aura_env.Refresh()
	for i = 1, aura_env.texcount do 
		aura_env.UpdateTex( i )
	end
end

-------------------------------------------------------------------------------
function aura_env.OnSpell( id )
	aura_env.PushSpell( id )
end