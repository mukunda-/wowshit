-------------------------------------------------------------------------------
-- Black Ox Health Tracker by mukunda (www.mukunda.com)
-------------------------------------------------------------------------------

function()

	local data = wa_blox_hp
	
	if not data.active then return false end
    
	if( not GetTotemInfo(1) ) then
		-- statue died/cancelled
		data.active = false
		return false
	end
	
	-- slide display hp towards real hp
	local percent = data.hp / data.hp_max * 100
	data.hp_display = data.hp_display * 0.9 + percent * 0.1
	
	return true
end