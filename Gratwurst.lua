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
	titleString:SetText("Gratwurst Configuration")

	Gratwurst = {};
	Gratwurst.ui = {};
	Gratwurst.ui.panel = luaFrame
	Gratwurst.ui.panel.name = "Gratwurst";

	-- Create the max delay  edit box
	local maxDelayEditBox = CreateFrame("EditBox", "Input_GratwurstRandomDelayMax", Gratwurst.ui.panel, "InputBoxTemplate")
	maxDelayEditBox:SetSize(25,30)
	maxDelayEditBox:SetMultiLine(false)
    -- maxDelayEditBox:ClearAllPoints()
	maxDelayEditBox:SetPoint("TOPLEFT", 10, -50)
	maxDelayEditBox:SetCursorPosition(0);
	maxDelayEditBox:ClearFocus();
    maxDelayEditBox:SetAutoFocus(false)
	maxDelayEditBox:Insert(GratwurstRandomDelayMax)
	maxDelayEditBox:SetScript("OnShow", function(self,event,arg1)
		self:SetNumber(GratwurstRandomDelayMax)
		self:SetCursorPosition(0);
		self:ClearFocus();
	end)
	maxDelayEditBox:SetScript("OnTextChanged", function(self,value)
		GratwurstRandomDelayMax = self:GetNumber()
	end)

	local maxDelayEditBoxLabel = maxDelayEditBox:CreateFontString("maxDelayEditBoxLabel")
	maxDelayEditBoxLabel:SetPoint("LEFT", maxDelayEditBox, "RIGHT", 5, 0)
	maxDelayEditBoxLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	-- maxDelayEditBoxLabel:SetWidth(250)
	maxDelayEditBoxLabel:SetHeight(20)
	maxDelayEditBoxLabel:SetTextColor(1, 0.8196079, 0)
	maxDelayEditBoxLabel:SetShadowOffset(1, -1)
	maxDelayEditBoxLabel:SetShadowColor(0, 0, 0)
	maxDelayEditBoxLabel:SetText("Max Delay (up to 9 seconds)")

	-- Create the varianceDropDown
	local varianceDropDown = CreateFrame("Frame", "VarianceDropDown",  Gratwurst.ui.panel, "UIDropDownMenuTemplate")
	varianceDropDown:SetPoint("BOTTOMLEFT", maxDelayEditBox, "BOTTOMLEFT", 0, -15)
	UIDropDownMenu_SetWidth(varianceDropDown, 125) -- Use in place of dropDown:SetWidth
	-- Bind an initializer function to the dropdown; see previous sections for initializer function examples.
	UIDropDownMenu_Initialize(varianceDropDown, VarianceDropdown_OnInit)
	UIDropDownMenu_SetText(varianceDropDown, GratwurstVariancePercentage)

	local varianceDropDownLabel = varianceDropDown:CreateFontString("varianceDropDownLabel")
	varianceDropDownLabel:SetPoint("TOPLEFT", varianceDropDown, "TOPLEFT", 0, 5)
	varianceDropDownLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	varianceDropDownLabel:SetWidth(250)
	varianceDropDownLabel:SetHeight(20)
	varianceDropDownLabel:SetTextColor(1, 0.8196079, 0)
	varianceDropDownLabel:SetShadowOffset(1, -1)
	varianceDropDownLabel:SetShadowColor(0, 0, 0)
	varianceDropDownLabel:SetText("Select how often we should gratz")

	-- Create the Max Delay slider
	local maxDelaySlider = CreateFrame("Slider", "MaxDelaySlider", Gratwurst.ui.panel, "OptionsSliderTemplate")
	maxDelaySlider:SetPoint("TOPLEFT", 34, -45)
	maxDelaySlider:SetWidth(132)
	maxDelaySlider:SetHeight(17)
	maxDelaySlider:SetOrientation("HORIZONTAL")
	maxDelaySlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	maxDelaySlider:SetMinMaxValues(0,100)
	maxDelaySlider:SetValue(50)
	-- maxDelaySlider:SetBackdrop({
	-- 	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	-- 	edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	-- 	tile = true, tileSize = 8, edgeSize = 8,
	-- 	insets = { left = 3, right = 3, top = 6, bottom = 6 }})
	maxDelaySlider:SetValueStep(25)

	local maxDelaySliderLabel = maxDelaySlider:CreateFontString("maxDelaySliderLabel")
	maxDelaySliderLabel:SetPoint("TOPLEFT", 34, -40)
	maxDelaySliderLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	maxDelaySliderLabel:SetWidth(250)
	maxDelaySliderLabel:SetHeight(20)
	maxDelaySliderLabel:SetTextColor(1, 0.8196079, 0)
	maxDelaySliderLabel:SetShadowOffset(1, -1)
	maxDelaySliderLabel:SetShadowColor(0, 0, 0)
	maxDelaySliderLabel:SetText("Max Delay (up to 9 seconds)")

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
			GuildAchievementMessageEventReceived();
		end
	elseif (event == "ADDON_LOADED" and msg == "Gratwurst") then
		InitializeSavedVariables();
		SetConfigurationWindow();
		self:UnregisterEvent("ADDON_LOADED");
	end
end

function GuildAchievementMessageEventReceived()
	local gratsStop = true
	local canGrats = false
	if GratwurstShouldVary then
		if math.random(1, 100) <= GratwurstVariancePercentage then
			canGrats = true
		end
	end
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
        if gratsStop and canGrats and GratwurstEnabled and GratwurstMessage ~= "" then
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

function VarianceDropdown_OnSelectionChanged(self, arg1, arg2, checked)
	GratwurstVariancePercentage = arg1
end

function VarianceDropdown_OnInit(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.func = VarianceDropdown_OnSelectionChanged
	info.text, info.checked = "100%", 100
	UIDropDownMenu_AddButton(info)
	info.text, info.checked = "75%", 75
	UIDropDownMenu_AddButton(info)
	info.text, info.checked = "50%", 50
	UIDropDownMenu_AddButton(info)
	info.text, info.checked = "25%", 25
	UIDropDownMenu_AddButton(info)
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