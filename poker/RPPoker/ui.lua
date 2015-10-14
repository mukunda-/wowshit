local AceGUI = LibStub("AceGUI-3.0") 
local Main = RPPoker

Main.UI = {}

-------------------------------------------------------------------------------
function Main.UI:Init() 

	self:CreateAddPlayerFrame()
	
	local f = AceGUI:Create( "Frame" )
	f:SetTitle( "RPPoker" )
	f:SetStatusText( "Status Bar" )
	f:SetLayout( "Flow" )
	print( "DEBUG ui created" )
	
	local button = AceGUI:Create( "Button" )
	button:SetText( "Add Player" )
	button:SetCallback( "OnClick", self.AddPlayerClicked )
	f:AddChild( button )
	
	local button = AceGUI:Create( "Button" )
	button:SetText( "Remove Player" )
	f:AddChild( button )
	
	local players = AceGUI:Create( "Label" )
	players:SetText( "|Tnothing:0|tawfasfa skdal kasdf|n asfkas;lfkjdf|nfwoiwe" )
	players:SetFullWidth( true )
	f:AddChild( players )
	self.player_status = players
	
	local btn = AceGUI:Create( "Button" )
	f:AddChild( btn )
	
	self.frame = f
end

function Main:CreateConfirmFrame()
	local f = AceGUI:Create( "Frame" )
	f:SetTitle( "Confirmation" )
	
end

function Main:CreateAddPlayerFrame()

end

-------------------------------------------------------------------------------
function Main.UI:UpdatePlayerStatus()
	local text = "PLAYER STATUS:"
	for _,player in ipairs( Main.Game.players ) do 
		text = text .. "|n"
		text = text .. player.name
	end
	
	self.player_status:SetText( text )
end

-------------------------------------------------------------------------------
function Main.UI:AddPlayerClicked()
	local self = Main.UI
	
	local name = UnitName( "target" )
	
	if not name or not UnitInParty( "target" ) then 
		Main:Print( "Must be targeting a party member." )
		return 
	end
	
	Main.Game:AddPlayer( name, 0 )
	
	self:UpdatePlayerStatus()
end