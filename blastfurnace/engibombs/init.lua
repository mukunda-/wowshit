-------------------------------------------------------------------------------
wa_bf_engibomb_data = {
	engineers = {},
	sacks = {},
	
	sacktime = 7,
	
	-- display info
	show    = false,
	bombs   = 0,
	expires = 0
}

-------------------------------------------------------------------------------
wa_bf_engibomb_data.UnitSide = function( unit )
	local x,y = UnitPosition( unit )
	
	if x == nil then return nil end
	
	if x < 177 then
		return 1
	elseif x > 218 then
		return 2
	end
	
	return nil
end

-------------------------------------------------------------------------------
-- Reset encounter data.
--
wa_bf_engibomb_data.Reset = function()
	local data = wa_bf_engibomb_data
	
	data.engineers = {}
	data.sacks     = {}
	
	local diff = GetRaidDifficultyID()
	
	if diff == 16 then -- mythic
		data.sacktime = 7
	else -- not mythic
		data.sacktime = 10
	end
end

-------------------------------------------------------------------------------
-- Convert a guid into a raid member.
--
-- @param guid GUID to convert.
-- @returns Raid unit id or nil if not found.
--
wa_bf_engibomb_data.RaidFromGUID = function( guid ) 
	for i = 1,40 do
		if UnitGUID( "raid" .. i ) == guid then
			return "raid" .. i
		end 
	end
	return nil
end

-------------------------------------------------------------------------------
-- Called when an engineer is involved in combat action, to associate
-- their position with a player.
--
-- @param engi_guid The GUID of the engineer.
-- @param player_guid The GUID of a player.
--
wa_bf_engibomb_data.RecordPosition = function( engi_guid, player_guid )
	local data = wa_bf_engibomb_data
	
	local unit = data.RaidFromGUID( player_guid )
	if unit == nil then return end
	
	local side = data.UnitSide( unit )
	if side == nil then return end
	
	data.engineers[ engi_guid ] = { side = side }
	
	
end

-------------------------------------------------------------------------------
-- Called when an engineer summons a bomb sack (dies).
--
-- @param engi_guid GUID of engineer.
-- @param sack_guid GUID of summoned bomb cluster.
--
wa_bf_engibomb_data.BombsDropped = function( engi_guid, sack_guid )
	local data = wa_bf_engibomb_data

	local engi = data.engineers[engi_guid]
	if engi == nil then
		print( "Unknown engineer died!" )
		return
	end
	
	data.sacks[sack_guid] = { side = engi.side, 
							  bombs = 3, 
							  expires = GetTime() + data.sacktime }
	
	data.engineers[engi_guid] = nil
end

-------------------------------------------------------------------------------
-- Called when a player takes a bomb from a sack.
--
-- @param sack_guid GUID of the sack.
--
wa_bf_engibomb_data.BombTaken = function( sack_guid )
	local data = wa_bf_engibomb_data
	local sack = data.sacks[sack_guid]
	
	if sack == nil then
		print( "Bomb taken from unknown sack!" )
		return
	end
	
	sack.bombs = sack.bombs - 1
	if sack.bombs == 0 then
		data.sacks[sack_guid] = nil
	end
end

-------------------------------------------------------------------------------
wa_bf_engibomb_data.SackDied = function( sack_guid )
	
	local data = wa_bf_engibomb_data
	local sack = data.sacks[sack_guid]
	
	if sack == nil then 
		return
	end
	
	if sack.bombs >= 2 then
		
		local side = "left"
		if sack.side == 2 then side = "right" end
		print( "Sack on " .. side .. " expired with " .. sack.bombs .. " left!" );
	end
end
