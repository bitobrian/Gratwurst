---@diagnostic disable: param-type-mismatch, missing-parameter, undefined-field
-- create global variables
ConfigTitle = "Gratwurst 1.8 Config"
PaddingLeft = 20
local category

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
	GratwurstVariancePercentage = GratwurstVariancePercentage or 50
	GratwurstIsGratzing = GratwurstIsGratzing or false
	GratwurstShouldRandomize = GratwurstShouldRandomize or true
	
	-- Initialize new message array structure
	GratwurstMessages = GratwurstMessages or {}
	
	-- Migrate from old format if needed
	if GratwurstMessage and GratwurstMessage ~= "" and #GratwurstMessages == 0 then
		GratwurstMessages = lines(GratwurstMessage)
		GratwurstMessage = nil -- Clean up old format
	end
	
	-- Set default messages if no messages exist
	if #GratwurstMessages == 0 then
		GratwurstMessages = {
			"Gratz $player!",
			"Congratulations $player!",
			"Well done $player!",
			"Awesome achievement $player!",
			"Nice work $player!",
			"Gratz on the achievement $player!",
			"Congratulations on your success $player!",
			"Great job $player!",
			"Achievement unlocked! Well done $player!",
			"Gratz on the progress $player!"
		}
	end
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
	titleString:SetText(ConfigTitle)

	Gratwurst = {};
	Gratwurst.ui = {};
	Gratwurst.ui.panel = luaFrame
	Gratwurst.ui.panel.name = "Gratwurst";

	-- Make a checkbox to disable randomizing the message
	local checkbox = CreateFrame("CheckButton", "GratwurstCheckbox", Gratwurst.ui.panel, "ChatConfigCheckButtonTemplate")
	checkbox:SetPoint("TOPLEFT", PaddingLeft, -30)
	checkbox:SetChecked(GratwurstShouldRandomize)
	checkbox:SetScript("OnClick", function(self,event,arg1)
		GratwurstShouldRandomize = self:GetChecked()
	end)

	-- Make a label for the checkbox
	local checkboxLabel = checkbox:CreateFontString("GratwurstCheckboxLabel")
	checkboxLabel:SetPoint("BOTTOM", checkbox, "TOP", 0, 0)
	checkboxLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	checkboxLabel:SetWidth(250)
	checkboxLabel:SetHeight(20)
	checkboxLabel:SetTextColor(1, 0.8196079, 0)
	checkboxLabel:SetShadowOffset(1, -1)
	checkboxLabel:SetShadowColor(0, 0, 0)
	checkboxLabel:SetText("Randomize Message")

	-- Create the max delay slide from 1 to 9
	local maxDelaySlider = CreateFrame("Slider", "MaxDelaySlider", Gratwurst.ui.panel, "OptionsSliderTemplate")
	maxDelaySlider:SetPoint("TOPLEFT", PaddingLeft, -70)
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
	maxDelaySliderLabel:SetText("Max delay in gratzing")
	
	-- Create the Frequency slider
	local MaxFrequencySlider = CreateFrame("Slider", "MaxFrequencySlider", Gratwurst.ui.panel, "OptionsSliderTemplate")
	MaxFrequencySlider:SetPoint("TOPLEFT", PaddingLeft, -120)
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

	-- Create the backdrop for the message list
	local backdropFrame = CreateFrame("Frame", nil, Gratwurst.ui.panel, BackdropTemplateMixin and "BackdropTemplate")
	backdropFrame:SetPoint("TOPLEFT", PaddingLeft, -180)
	backdropFrame:SetSize(500, 400)
	backdropFrame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
		tile = true,
		tileSize = 12,
		edgeSize = 8,
		insets = { left = 5, right = 3, top = 3, bottom = 3	},
	})

	-- Create the Gratz List label
	local gratzListLabel = backdropFrame:CreateFontString("GratzListLabel")
	gratzListLabel:SetPoint("BOTTOM", backdropFrame, "TOP", 0, 5)
	gratzListLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	gratzListLabel:SetWidth(500)
	gratzListLabel:SetHeight(20)
	gratzListLabel:SetTextColor(1, 0.8196079, 0)
	gratzListLabel:SetShadowOffset(1, -1)
	gratzListLabel:SetShadowColor(0, 0, 0)
	gratzListLabel:SetText("Message List (use $player to insert player name)")

	-- Create ScrollFrame for message list
	local scrollFrame = CreateFrame("ScrollFrame", "GratwurstMessageScrollFrame", backdropFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", backdropFrame, "TOPLEFT", 10, -10)
	scrollFrame:SetPoint("BOTTOMRIGHT", backdropFrame, "BOTTOMRIGHT", -30, 10)
	
	-- Create the content frame for the scroll frame
	local contentFrame = CreateFrame("Frame", "GratwurstMessageContentFrame", scrollFrame)
	contentFrame:SetSize(450, 100) -- Will be adjusted dynamically
	scrollFrame:SetScrollChild(contentFrame)
	
	-- Store references for later use
	Gratwurst.ui.scrollFrame = scrollFrame
	Gratwurst.ui.contentFrame = contentFrame
	Gratwurst.ui.messageFrames = {}
	
	-- Create control buttons below the scroll frame
	local addButton = CreateFrame("Button", "GratwurstAddButton", backdropFrame, "UIPanelButtonTemplate")
	addButton:SetSize(80, 25)
	addButton:SetPoint("BOTTOMLEFT", backdropFrame, "BOTTOMLEFT", 10, 10)
	addButton:SetText("Add Message")
	addButton:SetScript("OnClick", function()
		ShowAddMessageDialog()
	end)
	
	local restoreButton = CreateFrame("Button", "GratwurstRestoreButton", backdropFrame, "UIPanelButtonTemplate")
	restoreButton:SetSize(100, 25)
	restoreButton:SetPoint("BOTTOMLEFT", addButton, "BOTTOMRIGHT", 10, 0)
	restoreButton:SetText("Restore Defaults")
	restoreButton:SetScript("OnClick", function()
		RestoreDefaultMessages()
	end)
	
	-- Message count label
	local messageCountLabel = backdropFrame:CreateFontString("MessageCountLabel")
	messageCountLabel:SetPoint("BOTTOMRIGHT", backdropFrame, "BOTTOMRIGHT", -10, 10)
	messageCountLabel:SetFont("Fonts\\FRIZQT__.TTF", 10)
	messageCountLabel:SetTextColor(0.8, 0.8, 0.8)
	messageCountLabel:SetText("Messages: 0")
	Gratwurst.ui.messageCountLabel = messageCountLabel

	category = Settings.RegisterCanvasLayoutCategory(Gratwurst.ui.panel, "Gratwurst")
	Settings.RegisterAddOnCategory(category)
	
	-- Initialize the message list
	RefreshMessageList()
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
	if GratwurstIsGratzing then
		return
	end

	GratwurstIsGratzing = true

	local canGrats = false
	local random = math.random(1, 100)
	if random <= GratwurstVariancePercentage then
		canGrats = true
	end
	GratwurstDelayInSeconds = math.random(1,GratwurstRandomDelayMax)
    C_Timer.After(GratwurstDelayInSeconds,function()
        if canGrats and GratwurstEnabled and GratwurstMessage ~= "" then
			if GratwurstShouldRandomize then
				if isDebug then
					print("GetTopMessageFromList(author): " .. GetTopMessageFromList(author))
				else
					SendChatMessage(GetTopMessageFromList(author), "GUILD")
				end
			else
				if isDebug then
					print("GetRandomMessageFromList(author): " .. GetRandomMessageFromList(author))
				else
					SendChatMessage(GetRandomMessageFromList(author), "GUILD")
				end
			end
		end
		GratwurstIsGratzing = false
    end)
end

function GetTopMessageFromList(author)
	local message = GratwurstMessages[1] or "Gratz $player!"

	if author ~= nil then
		message = FindAndReplacePlayerNameToken(message, author)
	else
		-- we're debugging because author is nil since the event isn't fired
		message = FindAndReplacePlayerNameToken(message, "Taco-RealmOfNightmares")
	end

	return message
end

function GetRandomMessageFromList(author)
	local index = #GratwurstMessages
	if index == 0 then
		return "Gratz $player!"
	end
	
	local value = math.random(1, index)
	local message = GratwurstMessages[value]

	if author ~= nil then
		message = FindAndReplacePlayerNameToken(message, author)
	else
		-- we're debugging because author is nil since the event isn't fired
		message = FindAndReplacePlayerNameToken(message, "Taco-RealmOfNightmares")
	end

	return message
end

function FindAndReplacePlayerNameToken(message, author)
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

-- Message management functions
function AddNewMessage(message)
	if message and message ~= "" then
		table.insert(GratwurstMessages, message)
		SaveMessagesToVariables()
		RefreshMessageList()
	end
end

function DeleteMessage(index)
	if index and index > 0 and index <= #GratwurstMessages then
		table.remove(GratwurstMessages, index)
		SaveMessagesToVariables()
		RefreshMessageList()
	end
end

function MoveMessageUp(index)
	if index and index > 1 and index <= #GratwurstMessages then
		GratwurstMessages[index], GratwurstMessages[index - 1] = GratwurstMessages[index - 1], GratwurstMessages[index]
		SaveMessagesToVariables()
		RefreshMessageList()
	end
end

function MoveMessageDown(index)
	if index and index >= 1 and index < #GratwurstMessages then
		GratwurstMessages[index], GratwurstMessages[index + 1] = GratwurstMessages[index + 1], GratwurstMessages[index]
		SaveMessagesToVariables()
		RefreshMessageList()
	end
end

function EditMessage(index, newText)
	if index and index > 0 and index <= #GratwurstMessages and newText and newText ~= "" then
		GratwurstMessages[index] = newText
		SaveMessagesToVariables()
		RefreshMessageList()
	end
end

function RestoreDefaultMessages()
	GratwurstMessages = {
		"Gratz $player!",
		"Congratulations $player!",
		"Well done $player!",
		"Awesome achievement $player!",
		"Nice work $player!",
		"Gratz on the achievement $player!",
		"Congratulations on your success $player!",
		"Great job $player!",
		"Achievement unlocked! Well done $player!",
		"Gratz on the progress $player!"
	}
	SaveMessagesToVariables()
	RefreshMessageList()
end

function SaveMessagesToVariables()
	-- This function will be called whenever messages are modified
	-- The GratwurstMessages table is automatically saved by WoW
end

function LoadMessagesFromVariables()
	-- This function will be called to refresh the UI
	RefreshMessageList()
end

function RefreshMessageList()
	-- This function will be implemented when we create the UI
	-- It will update the visual list to match the GratwurstMessages array
	if not Gratwurst.ui or not Gratwurst.ui.contentFrame then
		return
	end
	
	-- Clear existing message frames
	for _, frame in pairs(Gratwurst.ui.messageFrames) do
		frame:Hide()
		frame:SetParent(nil)
	end
	Gratwurst.ui.messageFrames = {}
	
	local contentFrame = Gratwurst.ui.contentFrame
	local frameHeight = 30
	local spacing = 5
	local totalHeight = 0
	
	-- Create message frames
	for i, message in ipairs(GratwurstMessages) do
		local messageFrame = CreateFrame("Frame", "GratwurstMessageFrame" .. i, contentFrame)
		messageFrame:SetSize(430, frameHeight)
		messageFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -totalHeight)
		
		-- Message text
		local messageText = messageFrame:CreateFontString("GratwurstMessageText" .. i)
		messageText:SetPoint("LEFT", messageFrame, "LEFT", 5, 0)
		messageText:SetFont("Fonts\\FRIZQT__.TTF", 11)
		messageText:SetWidth(300)
		messageText:SetJustifyH("LEFT")
		messageText:SetText(message)
		messageText:SetTextColor(1, 1, 1)
		
		-- Edit button
		local editButton = CreateFrame("Button", "GratwurstEditButton" .. i, messageFrame, "UIPanelButtonTemplate")
		editButton:SetSize(50, 20)
		editButton:SetPoint("RIGHT", messageFrame, "RIGHT", -5, 0)
		editButton:SetText("Edit")
		editButton:SetScript("OnClick", function()
			ShowEditMessageDialog(i, message)
		end)
		
		-- Delete button
		local deleteButton = CreateFrame("Button", "GratwurstDeleteButton" .. i, messageFrame, "UIPanelButtonTemplate")
		deleteButton:SetSize(50, 20)
		deleteButton:SetPoint("RIGHT", editButton, "LEFT", -5, 0)
		deleteButton:SetText("Del")
		deleteButton:SetScript("OnClick", function()
			DeleteMessage(i)
		end)
		
		-- Move up button
		local upButton = CreateFrame("Button", "GratwurstUpButton" .. i, messageFrame, "UIPanelButtonTemplate")
		upButton:SetSize(30, 20)
		upButton:SetPoint("RIGHT", deleteButton, "LEFT", -5, 0)
		upButton:SetText("↑")
		upButton:SetScript("OnClick", function()
			MoveMessageUp(i)
		end)
		if i == 1 then
			upButton:Disable()
		end
		
		-- Move down button
		local downButton = CreateFrame("Button", "GratwurstDownButton" .. i, messageFrame, "UIPanelButtonTemplate")
		downButton:SetSize(30, 20)
		downButton:SetPoint("RIGHT", upButton, "LEFT", -5, 0)
		downButton:SetText("↓")
		downButton:SetScript("OnClick", function()
			MoveMessageDown(i)
		end)
		if i == #GratwurstMessages then
			downButton:Disable()
		end
		
		-- Background highlight
		local background = messageFrame:CreateTexture("GratwurstMessageBackground" .. i)
		background:SetAllPoints()
		background:SetColorTexture(0.2, 0.2, 0.2, 0.5)
		
		table.insert(Gratwurst.ui.messageFrames, messageFrame)
		totalHeight = totalHeight + frameHeight + spacing
	end
	
	-- Update content frame height
	contentFrame:SetHeight(math.max(totalHeight, 100))
	
	-- Update message count
	if Gratwurst.ui.messageCountLabel then
		Gratwurst.ui.messageCountLabel:SetText("Messages: " .. #GratwurstMessages)
	end
end

function ShowAddMessageDialog()
	local dialog = CreateFrame("Frame", "GratwurstAddDialog", UIParent, "BackdropTemplate")
	dialog:SetSize(400, 200)
	dialog:SetPoint("CENTER")
	dialog:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	dialog:SetMovable(true)
	dialog:EnableMouse(true)
	dialog:RegisterForDrag("LeftButton")
	dialog:SetScript("OnDragStart", dialog.StartMoving)
	dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
	
	-- Title
	local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", dialog, "TOP", 0, -10)
	title:SetText("Add New Message")
	
	-- Input box
	local inputBox = CreateFrame("EditBox", "GratwurstAddInput", dialog, "InputBoxTemplate")
	inputBox:SetSize(350, 20)
	inputBox:SetPoint("TOP", dialog, "TOP", 0, -40)
	inputBox:SetAutoFocus(true)
	inputBox:SetScript("OnEnterPressed", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			AddNewMessage(text)
			dialog:Hide()
		end
	end)
	
	-- Label
	local label = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("BOTTOM", inputBox, "TOP", 0, 5)
	label:SetText("Enter your message (use $player for player name):")
	
	-- Buttons
	local addButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	addButton:SetSize(80, 25)
	addButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 20, 20)
	addButton:SetText("Add")
	addButton:SetScript("OnClick", function()
		local text = inputBox:GetText()
		if text and text ~= "" then
			AddNewMessage(text)
			dialog:Hide()
		end
	end)
	
	local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	cancelButton:SetSize(80, 25)
	cancelButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -20, 20)
	cancelButton:SetText("Cancel")
	cancelButton:SetScript("OnClick", function()
		dialog:Hide()
	end)
	
	-- Close on escape
	dialog:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" then
			dialog:Hide()
		end
	end)
	
	dialog:Show()
end

function ShowEditMessageDialog(index, currentMessage)
	local dialog = CreateFrame("Frame", "GratwurstEditDialog", UIParent, "BackdropTemplate")
	dialog:SetSize(400, 200)
	dialog:SetPoint("CENTER")
	dialog:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	dialog:SetMovable(true)
	dialog:EnableMouse(true)
	dialog:RegisterForDrag("LeftButton")
	dialog:SetScript("OnDragStart", dialog.StartMoving)
	dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
	
	-- Title
	local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", dialog, "TOP", 0, -10)
	title:SetText("Edit Message")
	
	-- Input box
	local inputBox = CreateFrame("EditBox", "GratwurstEditInput", dialog, "InputBoxTemplate")
	inputBox:SetSize(350, 20)
	inputBox:SetPoint("TOP", dialog, "TOP", 0, -40)
	inputBox:SetText(currentMessage)
	inputBox:SetAutoFocus(true)
	inputBox:SetScript("OnEnterPressed", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			EditMessage(index, text)
			dialog:Hide()
		end
	end)
	
	-- Label
	local label = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("BOTTOM", inputBox, "TOP", 0, 5)
	label:SetText("Edit your message (use $player for player name):")
	
	-- Buttons
	local saveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	saveButton:SetSize(80, 25)
	saveButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 20, 20)
	saveButton:SetText("Save")
	saveButton:SetScript("OnClick", function()
		local text = inputBox:GetText()
		if text and text ~= "" then
			EditMessage(index, text)
			dialog:Hide()
		end
	end)
	
	local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	cancelButton:SetSize(80, 25)
	cancelButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -20, 20)
	cancelButton:SetText("Cancel")
	cancelButton:SetScript("OnClick", function()
		dialog:Hide()
	end)
	
	-- Close on escape
	dialog:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" then
			dialog:Hide()
		end
	end)
	
	dialog:Show()
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
		Settings.OpenToCategory(category.ID, "Gratwurst")
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
		print("GratwurstVariancePercentage: " .. GratwurstVariancePercentage)
		print("GratwurstIsGratzing: " .. tostring(GratwurstIsGratzing))
		GuildAchievementMessageEventReceived(true);
	end
end

SlashCmdList["GRATWURST"] = slashcmd