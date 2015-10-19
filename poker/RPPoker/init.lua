
local VERSION = "1.0"

RPPoker = LibStub("AceAddon-3.0"):NewAddon( "RPPoker",
										    "AceEvent-3.0", "AceTimer-3.0" ) 
local Main = RPPoker

Main.version = VERSION

-------------------------------------------------------------------------------
function Main:OnInitialize()
	self.Config:InitDB()
	if self.Config.db.char.state then
	--	Main.Game:LoadState( self.Config.db.char.state )
	end
	
	self.UI:Init()
end

function Main:OnEnable()
	self.UI:Update()
end