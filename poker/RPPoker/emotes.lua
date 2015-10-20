local Main = RPPoker

local EMOTES = {

	FLOP = {
		{ text = "burns a card and deals the flop: {1}, {2}, and {3}." };
	};
	TURN = {
		{ text = "burns a card and deals the turn: {4}. The cards on the table now being: {1}, {2}, {3}, and {4}." };
	};
	RIVER = {
		{ text = "burns a card and deals the river: {5}. The cards on the table now being: {1}, {2}, {3}, {4}, and {5}." };
	};
}

function Main:Emote( template, ... )

	template = EMOTES[template]
	template = template[ math.random( 1, #template ) ]
	local str = template.text
	
	for i = 1, select( "#", ... ) do
		local text = select( i, ... )
		str = string.gsub( str, "{" .. i .. "}", text )
	end
	
	Main:SendChatMessage( str, "EMOTE" )
end
