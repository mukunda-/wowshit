
local Main = RPPoker
local VERSION = 1

-------------------------------------------------------------------------------
local DB_DEFAULTS = {

	char = {
		state = nil;
	};

	profile = {
		button_icon = 2; -- circle
		turn_icon   = 4; -- triangle
		
		ante        = 0;
		small_blind = 500;
		big_blind   = 1000;
		multiplier  = 1.0;
		
		max_raises  = 3;
	};
}

Main.Config = {}

-------------------------------------------------------------------------------
function Main.Config:InitDB() 

	self.db = LibStub( "AceDB-3.0" ):New( 
					"RPPokerSaved", DB_DEFAULTS, true )
	
	--self.db.RegisterCallback( self, "OnProfileChanged", "Apply" )
	--self.db.RegisterCallback( self, "OnProfileCopied",  "Apply" )
	--self.db.RegisterCallback( self, "OnProfileReset",   "Apply" )
	 
	self.db.global.version = VERSION
end
