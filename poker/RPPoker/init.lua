
local VERSION = "1.0"

RPPoker = LibStub("AceAddon-3.0"):NewAddon( "RPPoker",
										    "AceEvent-3.0", "AceTimer-3.0" ) 
local Main = RPPoker

Main.version = VERSION
Main.cprefix = "RPPOKER"
 
-------------------------------------------------------------------------------
function Main:OnInitialize()
	self.Config:InitDB()
	
	Main.Game:ResetGame()
	
	if self.Config.db.char.state then
		--Main.Game:LoadState( self.Config.db.char.state )
	end
	
	Main.Game:AddPlayer( "Llanna", "John", 10000 )
	Main.Game:AddPlayer( "Llanna", "Cena", 10000 )
	Main.Game:AddPlayer( "Llanna", "Riches", 5050 )
	Main.Game:AddPlayer( "Llanna", "Larry", 10000 )
	
	ChatFrame_AddMessageEventFilter( "CHAT_MSG_WHISPER_INFORM", function( self, event, msg )
		if msg:sub( 1, 4 ) == "<EP>" then
			return true
		end
	end )
	
	self.UI:Init()
	self.Emote:Init()
end

-------------------------------------------------------------------------------
function Main:OnEnable()
	self.UI:Update()
end
