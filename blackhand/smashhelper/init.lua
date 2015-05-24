wa_bh_smashhelper_data = wa_bh_smashhelper_data or {}
local data = wa_bh_smashhelper_data

-------------------------------------------------------------------------------
-- CONFIGURATION
-------------------------------------------------------------------------------

data.name  = "Blackhand - Smash Helper" -- must match aura name.

-- order of people being sent up.
data.order = {
	
	[2] = {{"Kota",         "far" }},
	[3] = {{"Kairipta",     "near"}},
	[4] = {{"Scheherazade", "far" }, 
	       {"Pride",        "far" }},
	[5] = {{"Kota",         "near"}},
	[6] = {{"Kairipta",     "far" }},
	[7] = {{"Scheherazade", "near"},
	       {"Pride",        "near"}},
	[8] = {{"Kota",         "far" }},
	[9] = {{"Kairipta",     "near"}}
}

data.target_locations = {

	near = { 530.2,   3448.0 },
	far  = { 533.9,   3538.2 }
}

data.scale = 0.1

-------------------------------------------------------------------------------

data.tank = nil
data.show = false

--data.show = true -- debug
--data.target = data.target_locations["far"] -- debug

-------------------------------------------------------------------------------

local function Setup()

	local region = WeakAuras.regions[data.name].region

	-- setup frames

	local width  = region:GetWidth()
	local height = region:GetHeight()

	for i = 1,2 do
		 
		if data.cross == nil then data.cross = { nil, nil } end
		if data.cross[i] == nil then
			data.cross[i] = region:CreateTexture()
			
		end
		
		if data.dot == nil then data.dot = { nil, nil } end
		if data.dot[i] == nil then
			data.dot[i] = region:CreateTexture()
		end
		
		if data.text == nil then
			data.text = region:CreateFontString()
		end
	end

	for i = 1,2 do
		data.cross[i]:SetTexture( 0.2,0.2,0.2,1.0 )
		data.dot[i]:SetTexture(   0.5,0.5,0.5,1.0 )
		data.cross[i]:SetBlendMode( "ADD" )
		data.dot[i]:SetBlendMode( "ADD" )
		
	--	data.cross[i]:SetVertexColor( 0.1, 0.1, 0.1, 1.0 )
	--	data.dot[i]:SetVertexColor( 0.7, 0.7, 0.7, 1.0 )
		
	end

	data.cross[1]:SetSize( width-2, 1  )
	data.cross[2]:SetSize( 1, height-2 )

	data.cross[1]:SetPoint( "CENTER", region, 0, 0 )	
	data.cross[2]:SetPoint( "CENTER", region, 0, 0 )

	data.dot[1]:SetSize( width/10, 2  )
	data.dot[2]:SetSize( 2, height/10 )

	data.dot[1]:SetPoint( "CENTER", region, 0, 0 )	
	data.dot[2]:SetPoint( "CENTER", data.dot[1], 0, 0 )
	
	data.text:SetFont( "Fonts\\FRIZQT__.TTF", 16 )
	data.text:SetSize( width, 16 )
	data.text:SetPoint( "CENTER", region, 0, -height/4 )
	data.text:SetText( "PerfectSmash™" )
end

Setup()

-------------------------------------------------------------------------------
function data.OnSmashSoon( phase, count  )
	if phase == 2 then
		
		if data.order[count] ~= nil then
			local name = UnitName( "player" )
			
			for _,v in pairs( data.order[count] ) do
				if v[1] == name then
					data.show = true
					data.target = data.target_locations[v[2]]
					break
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
function data.OnSmash( phase, count )
	data.show = false
end

-------------------------------------------------------------------------------
function data.Refresh()
	if not data.show then return false end
	
	if UnitExists( "boss1target" ) then
		if UnitGroupRolesAssigned( "boss1target" ) == "TANK" then
			data.tank = "raid" .. UnitInRaid( "boss1target" )
		end
	end
	
	if data.tank == nil then return false end
	local tank_y, tank_x = UnitPosition( data.tank )
	
	--tank_y, tank_x = wa_spiritpos_data.y, wa_spiritpos_data.x -- debug
	
	local vec_y, vec_x = data.target[1] - tank_y, data.target[2] - tank_x
	
	local d = math.sqrt( vec_x^2 + vec_y^2 )
	if d < 1 then return false end -- they are UNDER the target...
	
	vec_x, vec_y = tank_x + (vec_x / d) * 1.9, tank_y + (vec_y / d) * 1.9
	
	-- vec is where they should stand, 1.9 yards away from the tank
	-- in the angle towards their target.
	
	local f = GetPlayerFacing("player") 
	
    local py, px = UnitPosition( "player" )
    local xt, yt = px - vec_x, py - vec_y
	
	local distance = math.sqrt(xt^2 + yt^2)

	data.text:SetText( string.format( "%.1f", distance ))
	
	if distance < 0.5 then
		data.text:SetTextColor( 0,1,0,1 )
	else
		data.text:SetTextColor( 1,1,1,1 )
	end
	
    local x, y = xt * math.cos(f) - yt * math.sin(f), 
	             xt * math.sin(f) + yt * math.cos(f)
	
    y = -y
    
	local region = WeakAuras.regions[data.name].region
	local width  = region:GetWidth()
	local height = region:GetHeight()
	
	x, y = x * data.scale, y * data.scale
	
	-- clamp to edge
	local d = math.sqrt((x*x)+(y*y))
    if d > 1 then
        x, y = x / d, y / d
    end
	
	x, y = x * width/2, y * height/2
	
	data.dot[1]:SetPoint( "CENTER", region, x, y )
	
	return true
end
