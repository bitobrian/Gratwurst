---@diagnostic disable: param-type-mismatch, missing-parameter, undefined-field
function InitializeAddon(self)
	self:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("ADDON_LOADED")
end

function InitializeSavedVariables(self)
	GratwurstMessage = GratwurstMessage or ""
	GratwurstDelayInSeconds = GratwurstDelayInSeconds or 3
	GratwurstRandomDelayMax = GratwurstRandomDelayMax or GratwurstDelayInSeconds
	GratwurstEnabled = GratwurstEnabled or true
	GratwurstRandomDelayEnabled = true;
	GratwurstShouldVary = GratwurstShouldVary or false;
	GratwurstVariancePercentage = GratwurstVariancePercentage or 50;
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
	titleString:SetText("Gratwurst 1.9 Config")

	Gratwurst = {};
	Gratwurst.ui = {};
	Gratwurst.ui.panel = luaFrame
	Gratwurst.ui.panel.name = "Gratwurst";

	-- Create the max delay slide from 1 to 9
	local maxDelaySlider = CreateFrame("Slider", "MaxDelaySlider", Gratwurst.ui.panel, "OptionsSliderTemplate")
	maxDelaySlider:SetPoint("TOPLEFT", 34, -45)
	maxDelaySlider:SetWidth(132)
	maxDelaySlider:SetHeight(17)
	maxDelaySlider:SetOrientation("HORIZONTAL")
	maxDelaySlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	maxDelaySlider:SetMinMaxValues(1,9)
	maxDelaySlider:SetValue(GratwurstRandomDelayMax)
	maxDelaySlider:SetValueStep(1)
	maxDelaySlider:SetObeyStepOnDrag(true)
	maxDelaySlider:SetScript("OnValueChanged", function(self,event,arg1)
		GratwurstRandomDelayMax = self:GetValue()
	end)
	
	-- Max delay label
	local maxDelaySliderLabel = maxDelaySlider:CreateFontString("MaxDelaySliderLabel")
	maxDelaySliderLabel:SetPoint("BOTTOM", maxDelaySlider, "TOP", 0, 0)
	maxDelaySliderLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	maxDelaySliderLabel:SetWidth(250)
	maxDelaySliderLabel:SetHeight(20)
	maxDelaySliderLabel:SetTextColor(1, 0.8196079, 0)
	maxDelaySliderLabel:SetShadowOffset(1, -1)
	maxDelaySliderLabel:SetShadowColor(0, 0, 0)
	maxDelaySliderLabel:SetText("Maximum delay in gratzing")
	
	-- Create the Frequency slider
	local MaxFrequencySlider = CreateFrame("Slider", "MaxFrequencySlider", Gratwurst.ui.panel, "OptionsSliderTemplate")
	MaxFrequencySlider:SetPoint("TOPLEFT", 34, -100)
	MaxFrequencySlider:SetWidth(132)
	MaxFrequencySlider:SetHeight(17)
	MaxFrequencySlider:SetOrientation("HORIZONTAL")
	MaxFrequencySlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	MaxFrequencySlider:SetMinMaxValues(0,100)
	MaxFrequencySlider:SetValue(GratwurstVariancePercentage)
	MaxFrequencySlider:SetValueStep(1)
	MaxFrequencySlider:SetObeyStepOnDrag(true)
	MaxFrequencySlider:SetScript("OnValueChanged", function(self,event,arg1)
		GratwurstVariancePercentage = self:GetValue()
	end)

	-- Frequency label
	local MaxFrequencySliderLabel = MaxFrequencySlider:CreateFontString("MaxFrequencySliderLabel")
	MaxFrequencySliderLabel:SetPoint("BOTTOM", MaxFrequencySlider, "TOP", 0, 0)
	MaxFrequencySliderLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	MaxFrequencySliderLabel:SetWidth(250)
	MaxFrequencySliderLabel:SetHeight(20)
	MaxFrequencySliderLabel:SetTextColor(1, 0.8196079, 0)
	MaxFrequencySliderLabel:SetShadowOffset(1, -1)
	MaxFrequencySliderLabel:SetShadowColor(0, 0, 0)
	MaxFrequencySliderLabel:SetText("How often do we gratz?")

	-- Create the Gratz List control
	WIDTH_PANEL = 500
	HEIGHT_PANEL = 300

	-- Create the scroll frame backdrop
	local backdropFrame = CreateFrame("Frame", nil, Gratwurst.ui.panel, BackdropTemplateMixin and "BackdropTemplate")
	backdropFrame:SetPoint("BOTTOM")
	backdropFrame:SetSize(WIDTH_PANEL, HEIGHT_PANEL)
	backdropFrame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 8,
        insets = { left = 5, right = 3, top = 3, bottom = 3	},
	})

	-- Create the scroll frame 
	local scrollFrame = CreateFrame("ScrollFrame", nil, backdropFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetAlpha(0.8)
	scrollFrame:SetSize(WIDTH_PANEL - 35, HEIGHT_PANEL - 11)
	scrollFrame:SetPoint("TOPLEFT", 7, -7)

	-- Create the scroll frame edit box
	local editBox = CreateFrame("EditBox", "Input_GratwurstMessage", scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(ChatFontNormal)
	editBox:Insert(GratwurstMessage)
	editBox:SetScript("OnShow", function(self,event,arg1)
		self:SetText(GratwurstMessage)
	end)
	editBox:SetScript("OnTextChanged", function(self,value)
		GratwurstMessage = self:GetText()
	end)
	editBox:SetWidth(300)
	scrollFrame:SetScrollChild(editBox)

	-- Create the scroll frame label
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

function OnEventReceived(self, event, msg, author, ...)
	if (event == "PLAYER_LOGIN") then
		if (GratwurstUnitName == nil or strfind(GratwurstUnitName, " ")) then
			GratwurstUnitName = strjoin("-", UnitName("player"), GetNormalizedRealmName())
		end;
	elseif (event == "CHAT_MSG_GUILD_ACHIEVEMENT") then		
		if (author ~= GratwurstUnitName) then
			GuildAchievementMessageEventReceived(false, author);
		end
	elseif (event == "ADDON_LOADED" and msg == "Gratwurst") then
		InitializeSavedVariables();
		SetConfigurationWindow();
		self:UnregisterEvent("ADDON_LOADED");
	end
end

function GuildAchievementMessageEventReceived(isDebug, author)
	local gratsStop = true
	local canGrats = false
	if GratwurstShouldVary then
		local random = math.random(1, 100)
		if random <= GratwurstVariancePercentage then
			canGrats = true
		end
	end
	if GratwurstRandomDelayEnabled then
		if GratwurstRandomDelayMax < 1 then
			GratwurstRandomDelayMax = 1
		end
		if GratwurstRandomDelayMax > 9 then
			GratwurstRandomDelayMax = 9
		end
		GratwurstDelayInSeconds = math.random(1,GratwurstRandomDelayMax)
		if isDebug then
			print("GratwurstDelayInSeconds: " .. GratwurstDelayInSeconds)
		end
	end
    C_Timer.After(GratwurstDelayInSeconds,function()
        if gratsStop and canGrats and GratwurstEnabled and GratwurstMessage ~= "" then
			gratsStop=false
			if isDebug then
				print("GetRandomMessageFromList(author): " .. GetRandomMessageFromList(author))
			else
				SendChatMessage(GetRandomMessageFromList(author), "GUILD")
			end
        end
    end)
end

function GetRandomMessageFromList(author)
	local table = lines(GratwurstMessage)
	local index = GetTableSize(table)
	local value = math.random(1,index)
	local message = table[value]

	if author ~= nil then
		message = FindAndReplacePlayerNameToken(message, author)
	else
		-- we're debugging because author is nil since the event isn't fired
		message = FindAndReplacePlayerNameToken(message, "Taco-RealmOfNightmares")
	end

	return message
end

function FindAndReplacePlayerNameToken(message, author)
	print("author: " .. author)
	local result = message
	local token = "$player"
	local value = string.gsub(author, "%-.*", "")
	result = string.gsub(result, token, value)
	return result
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
	elseif (msg == "debug") then
		-- output saved variables to chat
		print("=======================")
		print("GratwurstDelayInSeconds: " .. GratwurstDelayInSeconds)
		print("GratwurstRandomDelayMax: " .. GratwurstRandomDelayMax)
		print("GratwurstEnabled: " .. tostring(GratwurstEnabled))
		print("GratwurstRandomDelayEnabled: " .. tostring(GratwurstRandomDelayEnabled))
		print("GratwurstShouldVary: " .. tostring(GratwurstShouldVary))
		print("GratwurstVariancePercentage: " .. GratwurstVariancePercentage)
		GuildAchievementMessageEventReceived(true);
	end
end

SlashCmdList["GRATWURST"] = slashcmd