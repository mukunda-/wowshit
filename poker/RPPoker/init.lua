
local VERSION = "1.0"

RPPoker = LibStub("AceAddon-3.0"):NewAddon( "RPPoker",
										    "AceEvent-3.0", "AceTimer-3.0" ) 
local Main = RPPoker

Main.version = VERSION
Main.cprefix = "RPPOKER"

-------------------------------------------------------------------------------
function Main:OnInitialize()
	self.Config:InitDB()
	if self.Config.db.char.state then
		--Main.Game:LoadState( self.Config.db.char.state )
	end
	
	Main.Game:AddPlayer( "Tammya", "Tammy", 5000 )
	Main.Game:AddPlayer( "Llanna", "Llanna", 5000 )
	
	self.UI:Init()
	self.Emote:Init()
end

-------------------------------------------------------------------------------
function Main:OnEnable()
	self.UI:Update()
end
