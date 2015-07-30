

--
-- psuedo protocol:
--
-- /cdplease:
--   send "ASK" to raid
--   raid responds with cds available
--   if a cd is within range with 10 extra yards, request that cd immediately
--   timeout after threshold 250ms and select a cd that is the least out of range
--   give up after 1000ms if no cds are received

local MyAddon      = LibStub("AceAddon-3.0"):NewAddon("CDPlease") 
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

