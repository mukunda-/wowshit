
local VERSION = "1.0"

RPPoker = LibStub("AceAddon-3.0"):NewAddon( "RPPoker", 
	             		  "AceEvent-3.0", "AceTimer-3.0" ) 


RPPoker.version = VERSION

-------------------------------------------------------------------------------
function RPPoker:OnInitialize()
	print( "DEBUG initialized" )
	self.UI:Init()
end