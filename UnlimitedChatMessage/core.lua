-- GLOBAL --
UCM = select(2, ...); 
-- MODULE --
local _G = getfenv(0);
setmetatable(UCM, {__index = _G});
setfenv(1, UCM);
-- LOCAL --
title		= "UnlimitedChatMessage"
folder		= title;
version		= GetAddOnMetadata(folder, "X-Curse-Packaged-Version") or "";
titleFull	= title.." "..version

coreFrame = CreateFrame("Frame");
core	= LibStub("AceAddon-3.0"):NewAddon(coreFrame, title, "AceConsole-3.0", "AceHook-3.0", "AceTimer-3.0", "AceEvent-3.0") -- 
local L = LibStub("AceLocale-3.0"):GetLocale(title, true)
local P; --db.profile

-- Don't touch these.
defaultMaxLetters = 255;--blizzard's default limit.
defaultMaxBytes = 256;
queuedOutgoingMsgs = {};
warnTooManyMsgs = 10; --ChatThrottleLib pauses every 10 messages for 10 seconds to prevent disconnect.
tabSpaces = "    ";
tempMultiLine = false;

--Default Settings
db				= {};
defaultSettings	= {profile = {}}
defaultSettings.profile.confirmLongMsgs = true
--~ defaultSettings.profile.multiLines = false
defaultSettings.profile.slashMultiLine = true

--Globals
local table_getn 		= _G.table.getn;
local table_insert 		= _G.table.insert;
local tostring_ 		= _G.tostring;
local tonumber_ 		= _G.tonumber;
local StaticPopup_Show_	= _G.StaticPopup_Show;
local strsplit_ 		= _G.strsplit;


--	/script print(DEFAULT_CHAT_FRAME.editBoxGetFrameStrata())

-- Ace3 Functions
function core:OnInitialize()
	if _G.AddonLoader then
		if _G.AddonLoader.RemoveInterfaceOptions then
			_G.AddonLoader:RemoveInterfaceOptions("UCM")
		end
		
		_G["SLASH_UCM1"] = nil 
		_G.SlashCmdList["UCM"] = nil
		_G.hash_SlashCmdList["/ucm"] = nil
	end

	db = LibStub("AceDB-3.0"):New("UCM_DB", defaultSettings, true)
	CoreOptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)--save option profile or load another chars opts.
	db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	db.RegisterCallback(self, "OnProfileDeleted", "OnProfileChanged")
	core:RegisterChatCommand("ucm", "MySlashProcessorFunc")
	
	core:RegisterEvent( "CHAT_MSG_SAY", "OnChatMsgSay" )
	core:RegisterEvent( "CHAT_MSG_EMOTE", "OnChatMsgEmote" )
	core:RegisterEvent( "CHAT_MSG_SYSTEM", "OnChatMsgSystem" )

	self:BuildAboutMenu()
	
	local config = LibStub("AceConfig-3.0");
	local dialog = LibStub("AceConfigDialog-3.0");
	config:RegisterOptionsTable(title, CoreOptionsTable)
	coreOpts = dialog:AddToBlizOptions(title, "UCM "..version)
end


----------------------------------------------
function core:MySlashProcessorFunc(input)	--
-- /da function brings up the UI options.	--
----------------------------------------------
	InterfaceOptionsFrame_OpenToCategory(coreOpts)
end

function core:OnEnable()
	P = db.profile;
	
	self:RawHook("SendChatMessage", true)

--~ 	self:HookScript(editBox, "OnHide", "OnHide")
	self:Hook("ChatEdit_OnTextChanged", true)
	local editBox			= _G.DEFAULT_CHAT_FRAME.editBox
	
	defaultMaxLetters = editBox:GetMaxLetters()
	defaultMaxBytes = editBox:GetMaxBytes()
	
--~ 	editBox:SetMaxLetters(0)--0=unlimited
--~ 	editBox:SetMaxBytes(0)--0=unlimited
	
	self:CallHandler("SetMaxLetters", 0)
	self:CallHandler("SetMaxBytes", 0)
	

	
	self:HookSetAttribute()
	self:HookOnHide()
end

function core:HookSetAttribute()
	local editBox
	for i=1, NUM_CHAT_WINDOWS do 
		editBox = _G["ChatFrame"..i.."EditBox"]
		self:SecureHook(editBox, "SetAttribute")
	end
end


function core:HookOnHide()
	local editBox
	for i=1, NUM_CHAT_WINDOWS do 
		editBox = _G["ChatFrame"..i.."EditBox"]
		self:HookScript(editBox, "OnHide", "OnHide")
	end
end


function core:CallHandler(handler, ...)
	local editBox
	for i=1, NUM_CHAT_WINDOWS do 
		editBox = _G["ChatFrame"..i.."EditBox"]
		editBox[handler](editBox, ...)
	end
end

function core:SetAttribute(frame, attribute, value)
	if attribute == "chatType" then
		if value:find("BN_") then --BN_CONVERSATION, BN_WHISPER
			frame:SetMaxLetters(defaultMaxLetters)
			frame:SetMaxBytes(defaultMaxBytes)
--~ 			print("SetAttribute A", attribute, value, "|| Setting default limits")
		else
			frame:SetMaxLetters(0)--0=unlimited
			frame:SetMaxBytes(0)--0=unlimited
--~ 			print("SetAttribute B", attribute, value, "|| Setting to unlimited")
		end
	end
end

function core:ChatEdit_OnTextChanged(...)
	local this, userInput = ...;
	local text = this:GetText();

	
	if userInput then
		if P.slashMultiLine == true then
			if text:len() > 0 and text:lower() == "/ml " then
				print(L["Editbox temporarily set to multiline."]);
				tempMultiLine = true;
				this:SetMultiLine(true)
				this:SetText("");
				return;
			end
		end
	else
--~ 		print("ChatEdit_OnTextChanged", userInput, this:IsMultiLine(), tempMultiLine)
		if this:IsMultiLine() and tempMultiLine == false then
			this:SetMultiLine(false)
		end
	end
end

function core:OnHide(this)
	tempMultiLine = false;
end

--[[
0
	1
		2
			3
				4
					5
					
#####
#   #
# # #
#   #
#####
]]

----------------------------------------------------------------------
function core:OnProfileChanged(...)									--
-- User has reset proflie, so we reset our spell exists options.	--
----------------------------------------------------------------------
	-- Shut down anything left from previous settings
	self:Disable()
	-- Enable again with the new settings
	self:Enable()
end

function core:OnDisable()
	--return chatbox maxs to defaults.
--~ 	editBox:SetMaxLetters(defaultMaxLetters)
--~ 	editBox:SetMaxBytes(defaultMaxBytes)
	
	self:CallHandler("SetMaxLetters", defaultMaxLetters)
	self:CallHandler("SetMaxBytes", defaultMaxBytes)
	
	--reset editbox to be single line.
--~ 	editBox:SetMultiLine(false)
	self:CallHandler("SetMultiLine", false)
end

------------------------------------------------------------------
function core:SendChatMessage(...)								--
-- Our hook to SendChatMessage. If msg is too long we split it.	--
------------------------------------------------------------------
	local msg, chatType, language, channel = ...
	
	-- we put a special flag in the chat type to determine if this message
	-- should be sent normally
	if chatType:sub( 1, 2 ) == "__" then 
		core.hooks.SendChatMessage( msg, chatType:sub(3), language, channel )
		return
	end
	
	local chunks = {}
		
	if msg:find("\n") then --P.multiLines == true and 
		local tSplit = { strsplit_("\n", msg) }
		local tmpChunks = {}
		for i= 1, table_getn(tSplit) do 
			tmpChunks = SplitIntoChunks(tSplit[i])
			for o=1, table_getn(tmpChunks) do 
				table_insert(chunks, tmpChunks[o])
			end
		end 
	elseif msg:len() > defaultMaxLetters then
		chunks = SplitIntoChunks(msg)
 
	else
		chunks = {msg}
	end
	
	for i = 1, #chunks do 
		self:SendChat( chunks[i], chatType, language, channel )
	end
end


function paddString(str, paddingChar, minLength, paddRight)
    str = tostring_(str or "");
    paddingChar = tostring_(paddingChar or " ");
    minLength = tonumber_(minLength or 0);
    while(str:len() < minLength) do
        if(paddRight) then
            str = str..paddingChar;
        else
            str = paddingChar..str;
        end
    end
    return str;
end




function SplitIntoChunks(longMsg)
	local splitMessageLinks = {};
	
	--Replace links with long strings of zeroes.
	longMsg, results = longMsg:gsub( "(|H[^|]+|h[^|]+|h)", function(theLink)
			table_insert(splitMessageLinks, theLink);
			return "\001\002"..paddString(#splitMessageLinks, "0", theLink:len()-4).."\003\004";
	end);
	
	--WoW replaces tabs with 4 spaces, lets replace 4 spaces with '$tab' so that our splitting of words doesn't remove the tab spaces.
	if longMsg:find(tabSpaces) then
		while longMsg:find(tabSpaces) do
			longMsg = longMsg:gsub(tabSpaces, "$tab");
		end
	end
	
	local words = {}
	for v in longMsg:gmatch("[^ ]+") do
		--Check if 'word' is longer then 254 characters. (wtf?) anyway split long string at the 254 char mark.
		if v:len() > defaultMaxLetters then
			local shortPart, remainingPart = nil, v;
			local i=1;
			while remainingPart and remainingPart:len() > 0 do
				shortPart, remainingPart = GetShorterString(remainingPart);
				if shortPart and shortPart ~= "" then
					table_insert(words, shortPart)
				end
				
				if i>10 then break; end
				i=i+1;
			end
		else
			table_insert(words, v)
		end
	end

	local temp = "";
	local chunks = {}
	for i=1, table_getn(words) do 
		if temp:len() + words[i]:len() <= (defaultMaxLetters - 1) then
			if temp:len() > 0 then
				temp = temp.." "..words[i];
			else
				temp = words[i];
			end
			
		else
			temp = temp:gsub("\001\002%d+\003\004", function(link)
				local index = tonumber_(link:match("(%d+)"));
				return splitMessageLinks[index] or link;
			end);
			
			if temp:find("$tab") then
				while temp:find("$tab") do
					temp = temp:gsub("$tab", tabSpaces);
				end
			end
			
			table_insert(chunks, temp);
			temp = words[i];
		end
	end

	if temp:len() > 0 then
		temp = temp:gsub("\001\002%d+\003\004", function(link)
			local index = tonumber_(link:match("(%d+)"));
			return splitMessageLinks[index] or link;
		end);
		
		if temp:find("$tab") then
			while temp:find("$tab") do
				temp = temp:gsub("$tab", tabSpaces);
			end
		end
			
		table_insert(chunks, temp);
	end

	return chunks;
end

-- UTF-8 Reference:
-- 0xxxxxxx - 1 byte UTF-8 codepoint (ASCII character)
-- 110yyyxx - First byte of a 2 byte UTF-8 codepoint
-- 1110yyyy - First byte of a 3 byte UTF-8 codepoint
-- 11110zzz - First byte of a 4 byte UTF-8 codepoint
-- 10xxxxxx - Inner byte of a multi-byte UTF-8 codepoint
 
local function chsize(char)
    if not char then
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    else
        return 1
    end
end
 
-- This function can return a substring of a UTF-8 string, properly handling
-- UTF-8 codepoints.  Rather than taking a start index and optionally an end
-- index, it takes the string, the starting character, and the number of
-- characters to select from the string.
 
local function utf8sub(str, startByte, numBytes)
  local currentIndex = startByte
  local returnedBytes = 0;
 
  while numBytes > 0 and currentIndex <= #str do
    local char = string.byte(str, currentIndex)
    currentIndex = currentIndex + chsize(char)
    numBytes = numBytes - chsize(char)
	returnedBytes = returnedBytes + chsize(char)
  end
  return str:sub(startByte, currentIndex - 1), returnedBytes
end
------------------------------------------------------------------------------------------
function GetShorterString(longMsg)
	local shortText, sizeBytes = utf8sub(longMsg, 1, defaultMaxLetters - 1)
	local remainingPart = longMsg:sub(sizeBytes + 1, longMsg:len())
	return shortText, remainingPart;
end

_G.StaticPopupDialogs["UCM_CONFIRMMSG"] = {
	text = "Send long msg?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(this)
		for i=1, table_getn(queuedOutgoingMsgs) do 
			--_G.ChatThrottleLib:SendChatMessage("BULK", "UCM", queuedOutgoingMsgs[i].msg, queuedOutgoingMsgs[i].chatType, queuedOutgoingMsgs[i].language, queuedOutgoingMsgs[i].channel);
			
			core:SendChat( queuedOutgoingMsgs[i].msg, queuedOutgoingMsgs[i].chatType, queuedOutgoingMsgs[i].language, queuedOutgoingMsgs[i].channel )
		end
	end,
	
	OnHide = function(this)
		queuedOutgoingMsgs = {};
	end,
	OnShow = function(this)
		this.text:SetText(L["Your message will be split into %d parts.\nTo prevent flood disconnection, your outgoing messages may pause every 10 lines.\nContinue?"]:format(table_getn(queuedOutgoingMsgs)))
	end,
	timeout = 0,
	hideOnEscape = 1,
};

function histoyTest()--	/script UCM.histoyTest()
	print("GetHistoryLines", editBox:GetHistoryLines())
	print("GetAltArrowKeyMode", editBox:GetAltArrowKeyMode())
	print("IsKeyboardEnabled", editBox:IsKeyboardEnabled())
	--/script print(DEFAULT_CHAT_FRAME.editBox:IsKeyboardEnabled())
end

----------------
--     UI     --
----------------
CoreOptionsTable = {
	name = titleFull,
	type = "group",
	childGroups = "tab",

	args = {
		core={
			name = L["Core"],
			type = "group",
			order = 1,
			args={}
		},
	},
}

CoreOptionsTable.args.core.args.enable = {
	type = "toggle",	order	= 1,
	name	= L["Enable"],
	desc	= L["Enables / Disables the addon"],
	set = function(info,val) 
		if val == true then
			core:Enable();
		else
			core:Disable();
		end
	end,
	get = function(info) return core:IsEnabled() end
}

CoreOptionsTable.args.core.args.confirmLongMsgs = {
	type = "toggle",	order	= 2,
	name = L["Confirm Long Messages"],	
	desc = L["Show a confirm window when splitting message into %d+ lines."]:format(warnTooManyMsgs),
	set = function(info,val) 
		P.confirmLongMsgs = val;
	end,
	get = function(info) return P.confirmLongMsgs end
}

--[[
CoreOptionsTable.args.core.args.multiLines = {
	type = "toggle",	order	= 3,
	name = L["Multi-line support"],	
	desc = L["Permanently set chatbox to be multi-line, then send each new line as it's own message.\nNote this breaks chat history (alt+up)."],
	set = function(info,val) 
		P.multiLines = val;
		core:CallHandler("SetMultiLine", val)
		if val == true then
			print(L["Please note, enabing 'multi-line support' breaks the chatbox's previous message history (alt+up)."])
		end
	end,
	get = function(info) return P.multiLines end
}]]

CoreOptionsTable.args.core.args.slashMultiLine = {
	type = "toggle",	order	= 4,
	name = L["/ml temp multi-line"],	
	desc = L["Typing /ml temporarily sets chatbox to multi-line."],
	set = function(info,val) 
		P.slashMultiLine = val;
	end,
	get = function(info) return P.slashMultiLine end
}

do
	local tostring = tostring
	local GetAddOnMetadata = GetAddOnMetadata
	local pairs = pairs
	local fields = {"Author", "X-Category", "X-License", "X-Email", "Email", "eMail", "X-Website", "X-Credits", "X-Localizations", "X-Donate", "X-Bitcoin"}
	local haseditbox = {["X-Website"] = true, ["X-Email"] = true, ["X-Donate"] = true, ["Email"] = true, ["eMail"] = true, ["X-Bitcoin"] = true}
	local fNames = {
		["Author"] = L.author,
		["X-License"] = L.license,
		["X-Website"] = L.website,
		["X-Donate"] = L.donate,
		["X-Email"] = L.email,
		["X-Bitcoin"] = L.bitcoinAddress,
	}
	local yellow = "|cffffd100%s|r"
	
	local val
	local options
	function core:BuildAboutMenu()
		options = self.options
		
		CoreOptionsTable.args.about = {
			type = "group",
			name = L.about,
			order = 99,
			args = {
			}
		}

		
		CoreOptionsTable.args.about.args.title = {
			type = "description",
			name = yellow:format(L.title..": ")..title,
			order = 1,
		}
		CoreOptionsTable.args.about.args.version = {
			type = "description",
			name = yellow:format(L.version..": ")..version,
			order = 2,
		}
		CoreOptionsTable.args.about.args.notes = {
			type = "description",
			name = yellow:format(L.notes..": ")..tostring(GetAddOnMetadata(folder, "Notes")),
			order = 3,
		}
	
		for i,field in pairs(fields) do
			val = GetAddOnMetadata(folder, field)
			if val then
				
				if haseditbox[field] then
					CoreOptionsTable.args.about.args[field] = {
						type = "input",
						name = fNames[field] or field,
						order = i+10,
						desc = L.clickCopy,
						width = "full",
						get = function(info)
							local key = info[#info]
							return GetAddOnMetadata(folder, key)
						end,	
					}
				else
					CoreOptionsTable.args.about.args[field] = {
						type = "description",
						name = yellow:format((fNames[field] or field)..": ")..val,
						width = "full",
						order = i+10,
					}
				end
		
			end
		end
	
		LibStub("AceConfig-3.0"):RegisterOptionsTable(title, CoreOptionsTable ) --
--~ 		LibStub("AceConfigDialog-3.0"):SetDefaultSize(title, 600, 500) --680
	end
end

-------------------------------------------------------------------------------
local g_chat_queue = {}
local g_chat_timer = nil
local g_chat_busy  = false

-------------------------------------------------------------------------------
function core:SendChat( msg, type, lang, channel )
	
	if type == "SAY" or type == "EMOTE" then
		-- say and emote have problematic throttling
		table.insert( g_chat_queue, { msg=msg, type=type, lang=lang } )
		self:StartChat()
	else
		
		_G.ChatThrottleLib:SendChatMessage( "ALERT", "UCM", msg, "__" .. type, lang, channel );
	end
end

-------------------------------------------------------------------------------
function core:StartChat()
	if g_chat_busy then return end
	if #g_chat_queue == 0 then return end
	g_chat_busy = true
	
	self:ChatQueue()
end

-------------------------------------------------------------------------------
function core:ChatQueue()
	 
	if #g_chat_queue == 0 then 
		g_chat_busy = false
		return 
	end
	
	local c = g_chat_queue[1]
	
	_G.ChatThrottleLib:SendChatMessage( "ALERT", "UCM", c.msg, "__" .. c.type, c.lang );
	g_chat_timer = self:ScheduleTimer( "ChatTimeout", 10 )
end

-------------------------------------------------------------------------------
function core:ChatTimeout()
	g_chat_timer = nil
	g_chat_queue = {}
	g_chat_busy = false
	print( "|cffff0000<Chat Timed Out!>|r" )
end

-------------------------------------------------------------------------------
function core:ChatConfirmed()
	self:CancelTimer( g_chat_timer )
	g_chat_timer = nil
	table.remove( g_chat_queue, 1 )
	
	self:ChatQueue()
end

-------------------------------------------------------------------------------
function core:ChatFailed()
	self:CancelTimer( g_chat_timer )
	print( "|cffff0000<chat failed..waiting>" )
	g_chat_timer = self:ScheduleTimer( "ChatFailedRetry", 3 )
end

-------------------------------------------------------------------------------
function core:ChatFailedRetry()
	print( "|cffff00ff<resending>" )
	g_chat_timer = nil
	self:ChatQueue()
end

-------------------------------------------------------------------------------
function core:OnChatMsgSay( event, message, sender, language, channelString, target, flags, _, channelNumber, channelName, _, counter )

	if #g_chat_queue == 0 then return end
	local cq = g_chat_queue[1]
	if cq.type ~= "SAY" then return end
 
	if target == UnitName( "player" ) then
	--	if cq.msg == message then
			self:ChatConfirmed()
	--	end
	end
end

-------------------------------------------------------------------------------
function core:OnChatMsgEmote( event, message, sender, language, channelString, target, flags, _, channelNumber, channelName, _, counter )

	if #g_chat_queue == 0 then return end
	local cq = g_chat_queue[1]
	if cq.type ~= "EMOTE" then return end
	
	if target == UnitName( "player" ) then
	--	if cq.msg == message then
			self:ChatConfirmed()
	--	end
	end
end

-------------------------------------------------------------------------------
function core:OnChatMsgSystem( event, message, sender, language, channelString, target, flags, _, channelNumber, channelName, _, counter )

	if #g_chat_queue == 0 then return end
	
	if message == "The number of messages that can be sent is limited, please wait to send another message." and sender == "" then
		self:ChatFailed()
	end
end