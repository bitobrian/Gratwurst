function InitializeAddon(self)
	self:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
	self:RegisterEvent("PLAYER_LOGIN")
	
    if(GratwurstMessage == nil)then
		GratwurstMessage="";
	end
	
	if(GratwurstDelayInSeconds == nil)then
		GratwurstDelayInSeconds = 3;
	end

	if(GratwurstRandomDelayMax == nil)then
		-- Updating from old value to new one
		GratwurstRandomDelayMax = GratwurstDelayInSeconds;
	end

	if(GratwurstEnabled == nil) then
		GratwurstEnabled = true;
	end

	GratwurstRandomDelayEnabled = true;
	
	SetConfigurationWindow();
end 

function SetConfigurationWindow()
	local luaFrame = CreateFrame("Frame", "GratwurstPanel", InterfaceOptionsFramePanelContainer)
	
	local titleBorder = luaFrame:CreateTexture("UnneccessaryGlobalFrameNameTitleBorder")
	titleBorder:SetWidth(320)
	titleBorder:SetHeight(50)
	titleBorder:SetPoint("TOP", luaFrame, "TOP", 0, 5)
	titleBorder:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	titleBorder:SetTexCoord(.2, .8, 0, .6)
	
	local titleString = luaFrame:CreateFontString("UnneccessaryGlobalFrameNameTitleString")
	titleString:SetFont("Fonts\\FRIZQT__.TTF", 15)
	titleString:SetWidth(320)
	titleString:SetPoint("TOP", luaFrame, "TOP", 0, -13)
	titleString:SetTextColor(1, 0.8196079, 0)
	titleString:SetShadowOffset(1, -1)
	titleString:SetShadowColor(0, 0, 0)
	titleString:SetText("Gratwurst Configuration")

	Gratwurst = {};
	Gratwurst.ui = {};
	Gratwurst.ui.panel = luaFrame
	Gratwurst.ui.panel.name = "Gratwurst";

	-- Control - IsEnabled CheckBox
	-- local isEnabledCheckButton = CreateFrame("CheckButton", "IsEnabledCheckButton", Gratwurst.ui.panel, "ChatConfigCheckButtonTemplate");
	-- isEnabledCheckButton:SetPoint("TOPLEFT", 20, -50);
	-- isEnabledCheckButton:SetScript("OnShow",
	-- 	function(self, event, arg1)
	-- 		self:SetChecked(GratwurstEnabled);
	-- 	end);
	-- isEnabledCheckButton:SetScript("OnClick",
	-- 	function()
	-- 		if (GratwurstEnabled) then
	-- 			GratwurstEnabled = false;
	-- 		else
	-- 			GratwurstEnabled = true;
	-- 		end
	-- 	end);
		
	-- local isEnabledCheckButtonLabel = isEnabledCheckButton:CreateFontString("isEnabledCheckButtonLabel")
	-- isEnabledCheckButtonLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	-- isEnabledCheckButtonLabel:SetWidth(120)
	-- isEnabledCheckButtonLabel:SetHeight(20)
	-- isEnabledCheckButtonLabel:SetPoint("TOPLEFT", -31, 15)
	-- isEnabledCheckButtonLabel:SetTextColor(1, 0.8196079, 0)
	-- isEnabledCheckButtonLabel:SetShadowOffset(1, -1)
	-- isEnabledCheckButtonLabel:SetShadowColor(0, 0, 0)
	-- isEnabledCheckButtonLabel:SetText("Enabled")

	-- Control - Randomize Time To Talk CheckBox
	-- local isRandomTTTCheckButton = CreateFrame("CheckButton", "IsRandomTTTCheckButton", Gratwurst.ui.panel, "ChatConfigCheckButtonTemplate");
	-- isRandomTTTCheckButton:SetPoint("TOPLEFT", 20, -100);
	-- isRandomTTTCheckButton:SetScript("OnShow",
	-- 	function(self, event, arg1)
	-- 		self:SetChecked(GratwurstRandomDelayEnabled);
	-- 	end);
	-- isRandomTTTCheckButton:SetScript("OnClick",
	-- 	function()
	-- 		if (GratwurstRandomDelayEnabled) then
	-- 			GratwurstRandomDelayEnabled = false;
	-- 		else
	-- 			GratwurstRandomDelayEnabled = true;
	-- 		end
	-- 	end);
		
	-- local isRandomTTTCheckButtonLabel = isRandomTTTCheckButton:CreateFontString("isRandomTTTCheckButtonLabel")
	-- isRandomTTTCheckButtonLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	-- isRandomTTTCheckButtonLabel:SetWidth(120)
	-- isRandomTTTCheckButtonLabel:SetHeight(20)
	-- isRandomTTTCheckButtonLabel:SetPoint("TOPLEFT", -31, 15)
	-- isRandomTTTCheckButtonLabel:SetTextColor(1, 0.8196079, 0)
	-- isRandomTTTCheckButtonLabel:SetShadowOffset(1, -1)
	-- isRandomTTTCheckButtonLabel:SetShadowColor(0, 0, 0)
	-- isRandomTTTCheckButtonLabel:SetText("Random Delay")

	-- Slider - Gratwurst Max Delay Slider
	-- local MySlider = CreateFrame("Slider", "GratwurstMaxDelaySlider", Gratwurst.ui.panel, "OptionsSliderTemplate")
	-- MySlider:SetWidth(20)
	-- MySlider:SetHeight(100)
	-- MySlider:SetOrientation('HORIZONTAL')


	-- Control - GratwurstDelayInSeconds
	-- local delayEditBox = CreateFrame("EditBox", "Input_GratwurstDelayInSeconds", Gratwurst.ui.panel, "InputBoxTemplate")
	-- delayEditBox:SetSize(25,30)
	-- delayEditBox:SetMultiLine(false)
    -- delayEditBox:ClearAllPoints()
	-- delayEditBox:SetPoint("TOPLEFT", 25, -150)
	-- delayEditBox:SetCursorPosition(0);
	-- delayEditBox:ClearFocus();
    -- delayEditBox:SetAutoFocus(false)
	-- delayEditBox:SetScript("OnShow", function(self,event,arg1)
	-- 	self:SetNumber(GratwurstDelayInSeconds)
	-- 	self:SetCursorPosition(0);
	-- 	self:ClearFocus();
	-- end)
	-- delayEditBox:SetScript("OnTextChanged", function(self,value)
	-- 	GratwurstDelayInSeconds = self:GetNumber()
	-- end)

	local maxDelayEditBox = CreateFrame("EditBox", "Input_GratwurstRandomDelayMax", Gratwurst.ui.panel, "InputBoxTemplate")
	maxDelayEditBox:SetSize(25,30)
	maxDelayEditBox:SetMultiLine(false)
    maxDelayEditBox:ClearAllPoints()
	maxDelayEditBox:SetPoint("TOPLEFT", 34, -50)
	maxDelayEditBox:SetCursorPosition(0);
	maxDelayEditBox:ClearFocus();
    maxDelayEditBox:SetAutoFocus(false)
	maxDelayEditBox:SetScript("OnShow", function(self,event,arg1)
		self:SetNumber(GratwurstRandomDelayMax)
		self:SetCursorPosition(0);
		self:ClearFocus();
	end)
	maxDelayEditBox:SetScript("OnTextChanged", function(self,value)
		GratwurstRandomDelayMax = self:GetNumber()
	end)
	
	local maxDelayEditBoxLabel = maxDelayEditBox:CreateFontString("maxDelayEditBoxLabel")
	maxDelayEditBoxLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	maxDelayEditBoxLabel:SetWidth(250)
	maxDelayEditBoxLabel:SetHeight(20)
	maxDelayEditBoxLabel:SetPoint("TOPLEFT", -6, -6)
	maxDelayEditBoxLabel:SetTextColor(1, 0.8196079, 0)
	maxDelayEditBoxLabel:SetShadowOffset(1, -1)
	maxDelayEditBoxLabel:SetShadowColor(0, 0, 0)
	maxDelayEditBoxLabel:SetText("Max Delay (up to 9 seconds)")


	local backdropFrame = CreateFrame("Frame", nil, Gratwurst.ui.panel, BackdropTemplateMixin and "BackdropTemplate")
	backdropFrame:SetPoint("TOPLEFT", 25,-110)
	backdropFrame:SetSize(335, 215)
	backdropFrame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 8,
        insets = { left = 5, right = 3, top = 3, bottom = 3	},
	})

	local scrollFrame = CreateFrame("ScrollFrame", nil, backdropFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetAlpha(0.8)
	scrollFrame:SetSize(300,200)
	scrollFrame:SetPoint("TOPLEFT", 7, -7)

	local editBox = CreateFrame("EditBox", "Input_GratwurstMessage", scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetScript("OnShow", function(self,event,arg1)
		self:SetText(GratwurstMessage)
	end)
	editBox:SetScript("OnTextChanged", function(self,value)
		GratwurstMessage = self:GetText()
	end)
	editBox:SetWidth(300)
	scrollFrame:SetScrollChild(editBox)	

	local editBoxLabel = backdropFrame:CreateFontString("editBoxLabel")
	editBoxLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	editBoxLabel:SetWidth(250)
	editBoxLabel:SetHeight(20)
	editBoxLabel:SetPoint("TOPLEFT", -20 ,20)
	editBoxLabel:SetTextColor(1, 0.8196079, 0)
	editBoxLabel:SetShadowOffset(1, -1)
	editBoxLabel:SetShadowColor(0, 0, 0)
	editBoxLabel:SetText("Gratz List (one message per line)")

	InterfaceOptions_AddCategory(Gratwurst.ui.panel);	
end

function OnEventRecieved(self, event, msg, author, ...)
	if (event == "PLAYER_LOGIN") then
		if (GratwurstUnitName == nil or strfind(GratwurstUnitName, " ")) then
			GratwurstUnitName = strjoin("-", UnitName("player"), GetNormalizedRealmName())
		end;
	elseif (event == "CHAT_MSG_GUILD_ACHIEVEMENT") then 
		if (author ~= GratwurstUnitName) then
			GuildAchievementMessageEventRecieved();
		end
	end
end

function GuildAchievementMessageEventRecieved()
	gratsStop=true
	if GratwurstRandomDelayEnabled then
		-- TODO: Make a slider for this instead of checking
		if GratwurstRandomDelayMax < 1 then
			GratwurstRandomDelayMax = 1
		end
		if GratwurstRandomDelayMax > 9 then
			GratwurstRandomDelayMax = 9
		end
		GratwurstDelayInSeconds = math.random(1,GratwurstRandomDelayMax)
	end
    C_Timer.After(GratwurstDelayInSeconds,function()
        if gratsStop and GratwurstEnabled and GratwurstMessage ~= "" then
			gratsStop=false			
			SendChatMessage(GetRandomMessageFromList(),"GUILD")
        end
    end)
end

function GetRandomMessageFromList()
	local table = lines(GratwurstMessage)
	local index = GetTableSize(table)
	local value = math.random(1,index)
	local message = table[value]
	return message
end

function Log(message)
	if(message == nil)then message = "nil";
	end
	DEFAULT_CHAT_FRAME:AddMessage(message)
end

function lines(str)
	local result = {}
	for line in str:gmatch '[^\n]+' do
	  table.insert(result, line)
	end
	return result
end

function GetTableSize(t)
    local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end

----------
-- Slash
----------

SLASH_GRATWURST1, SLASH_GRATWURST2 = '/gw', '/gratwurst';

local function slashcmd(msg, editbox)
	if (msg =="") then
		if (GratwurstEnabled) then
			DEFAULT_CHAT_FRAME:AddMessage("|cffffedbaGratwurst:|r Status: Enabled\n")
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffffedbaGratwurst:|r Status: Disabled\n")
		end
		DEFAULT_CHAT_FRAME:AddMessage("|cffffedbaGratwurst:|r Slash commands:")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffedbaGratwurst:|r   /gw c   -> Open Configuration")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffedbaGratwurst:|r   /gw enable   -> Enable Gratwurst")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffedbaGratwurst:|r   /gw disable  -> Disable Gratwurst")
	elseif (msg == "c") then
		InterfaceOptionsFrame_OpenToCategory("Gratwurst")
	elseif (msg == "enable") then
		GratwurstEnabled = true;
		print("Gratwurst enabled.");
	elseif (msg == "disable") then
		GratwurstEnabled = false;
		print("Gratwurst disabled.");
	end
end

SlashCmdList["GRATWURST"] = slashcmd