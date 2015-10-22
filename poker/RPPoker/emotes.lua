local Main = RPPoker
local AceGUI = LibStub("AceGUI-3.0") 

-------------------------------------------------------------------------------
local EMOTES = {

	FLOP = {
		--{ function( card1, card2, card3 ) return string.format( "burns a card and deals the flop: %s, %s, and %s", card1, card2, card3 ) end };
		{ text = "burns a card and deals the flop: {1}, {2}, and {3}." };
	};
	TURN = {
		{ text = "burns a card and deals the turn: {4}. The cards on the table now being: {1}, {2}, {3}, and {4}." };
	};
	RIVER = {
		{ text = "burns a card and deals the river: {5}. The cards on the table now being: {1}, {2}, {3}, {4}, and {5}." };
	};
}

-------------------------------------------------------------------------------
Main.Emotes = {
	panel = nil;
	text  = "";
}

-------------------------------------------------------------------------------
function Main.Emotes:Init()
	local f = AceGUI:Create( "Frame" )
	f:Hide()
	self.panel = f
	local e
	e = AceGUI:Create( "EditBox" )
	self.editbox = e
	f:AddChild(e)
	
end

-------------------------------------------------------------------------------
function Main.Emotes:Start( template, ... )

	template = EMOTES[template]
	template = template[ math.random( 1, #template ) ]
	local str = template.text
	
	for i = 1, select( "#", ... ) do
		local text = select( i, ... )
		str = string.gsub( str, "{" .. i .. "}", text )
	end
	
	Main:SendChatMessage( str, "EMOTE" )
end

-------------------------------------------------------------------------------
function Main.Emotes:ShowPanel()
	self.panel:Show()
end

-------------------------------------------------------------------------------
function Main.Emotes:Reset()
	self.text = ""
	
end

-------------------------------------------------------------------------------
function Main.Emotes:Queue( text )
	if self.text ~= "" then
		self.text = self.text .. " "
	end
	self.text = self.text .. text
	self.editbox:SetText( self.text )
end
