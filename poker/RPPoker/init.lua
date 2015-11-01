
local VERSION = "1.0"

RPPoker = LibStub("AceAddon-3.0"):NewAddon( "RPPoker",
										    "AceEvent-3.0", "AceTimer-3.0",
											"AceComm-3.0", "AceSerializer-3.0" ) 
local Main = RPPoker

Main.version = VERSION
Main.cprefix = "RPPOKER"
 
-------------------------------------------------------------------------------
function Main:OnInitialize()
	self.Config:InitDB()
	
	Main.Game:ResetGame()
	
	if self.Config.db.char.state then
		Main.Game:LoadState( self.Config.db.char.state )
	end
	
	--[[
	Main.Game:AddPlayer( "Llanna", "John", 10000 )
	Main.Game:AddPlayer( "aaaba", "Cena", 10000 )
	Main.Game:AddPlayer( "aaabb", "Riches", 5050 )
	Main.Game:AddPlayer( "aaabc", "Larry", 10000 )
	Main.Game:AddPlayer( "aaabd", "Five", 6000 )
	Main.Game:AddPlayer( "aaabe", "Six", 6000 )
	--]]
	
	ChatFrame_AddMessageEventFilter( "CHAT_MSG_WHISPER_INFORM", function( self, event, msg )
		if msg:sub( 1, 4 ) == "<EP>" then
			return true
		end
	end )
	
	self.UI:Init()
	self.Emote:Init()
	
	SLASH_EMOTEPOKER1 = "/epk"
	SLASH_DRAWCARD1 = "/drawcard"
end

-------------------------------------------------------------------------------
function Main:OnEnable()
	self.UI:Update()
end
