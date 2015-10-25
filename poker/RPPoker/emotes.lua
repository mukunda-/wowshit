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
Main.Emote = {
	panel = nil;
	text  = "";
}

local Module = Main.Emote

-------------------------------------------------------------------------------
function Module:Init()
	local f = AceGUI:Create( "Frame" )
	f:SetHeight( 280 )
	f:SetWidth( 500 )
	f:SetLayout( "Flow" )
	f:SetTitle( "Emote" )
	f:Hide()
	self.panel = f
	
	local e
	e = AceGUI:Create( "MultiLineEditBox" )
	self.editbox = e
	e:DisableButton( true )
	e:SetLabel( "Emote:" )
	e:SetFullWidth( true )
	e:SetNumLines( 10 )
	f:AddChild( e )
	
	e = AceGUI:Create( "Button" )
	e:SetText( "Send" )
	e:SetCallback( "OnClick", function() Module:Send() end )
	e:SetWidth( 100 )
	f:AddChild( e )
	
	e = AceGUI:Create( "Button" )
	e:SetText( "Reset" )
	e:SetCallback( "OnClick", function() Module:ResetEditbox() end )
	e:SetWidth( 100 )
	f:AddChild( e )
end

-------------------------------------------------------------------------------
function Module:AddTemplate( template, ... )
	
	template = EMOTES[template]
	template = template[ math.random( 1, #template ) ]
	local str = template.text
	
	for i = 1, select( "#", ... ) do
		local text = select( i, ... )
		str = string.gsub( str, "{" .. i .. "}", text )
	end
	
	self:Add( str )
end

-------------------------------------------------------------------------------
function Module:ShowPanel()
	self.panel:Show()
end

-------------------------------------------------------------------------------
function Module:Reset()
	self.text = ""
end

-----------------------w--------------------------------------------------------
function Module:Add( text, ... )
	if select( "#", ... ) ~= 0 then
		text = string.format( text, ... )
	end
	if self.text ~= "" then
		self.text = self.text .. " "
	end
	self.text = self.text .. text
	self:ResetEditbox()
	self:ShowPanel()
end

-------------------------------------------------------------------------------
function Module:ResetEditbox()
	self.editbox:SetText( self.text )
end

-------------------------------------------------------------------------------
function Module:Send()
	self.text = self.editbox:GetText()
	Main:SendChatMessage( self.editbox:GetText(), "EMOTE" )
	print( self.text )
end
