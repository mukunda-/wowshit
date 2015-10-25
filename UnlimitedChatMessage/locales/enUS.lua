local L = LibStub("AceLocale-3.0"):NewLocale("UnlimitedChatMessage", "enUS", true)

L["Core"] = true;
L["Enable"] = true;
L["Enables / Disables the addon"] = true;

L["Confirm Long Messages"] = true;
L["Show a confirm window when splitting message into %d+ lines."] = true;

L["Your message will be split into %d parts.\nTo prevent flood disconnection, your outgoing messages may pause every 10 lines.\nContinue?"] = true;


L["Multi-line support"] = true;
L["Permanently set chatbox to be multi-line, then send each new line as it's own message.\nNote this breaks chat history (alt+up)."] = true;

L["Please note, enabing 'multi-line support' breaks the chatbox's previous message history (alt+up)."] = true;

L["/ml temp multi-line"] = true;
L["Typing /ml temporarily sets chatbox to multi-line."] = true

L["Editbox temporarily set to multiline."] = true;

L.about = "About"
L.clickCopy = "Click and press Ctrl-C to copy"
L.title = "Title"
L.notes = "Notes"
L.author = "Author"
L.license = "License"
L.email = "Email"
L.website = "Website"
L.donate = "Donate"
L.version = "Version"
L.enableDesc = "Activate/deactivate the addon."
L.openOptionsFrameName = "Open options frame"
L.openOptionsFrameDesc = "Click to bring up the options frame."
L.bitcoinAddress = "Bitcoin address"