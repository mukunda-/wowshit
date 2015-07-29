

--
-- psuedo protocol:
--
-- /cdplease:
--   send query to raid
--   gather responses within threshold (250ms)
--   request 
--

local MyAddon = LibStub("AceAddon-3.0"):NewAddon("CDPlease")



local cd_call_time = 0

SLASH_CDPLEASE = "/cdplease"

function SLASHCMDLIST.CDPLEASE()
	CallCD()
end

local function CallCD()
	if GetTime() - cd_call_time < 1 then

		return -- ignore button spam
	end
	
	cd_call_time = GetTime()
	
	SendAddonMessage( "CDPLEASE", "ASK", "RAID" )
	
	
end

