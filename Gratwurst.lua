---@diagnostic disable: param-type-mismatch, missing-parameter, undefined-field
-- create global variables
ConfigTitle = "Gratwurst @project-version@ Config"
PaddingLeft = 20
local category
local GratwurstVIPDialog
local GratwurstBulkEditDialog

local UI = {
	PAD_X = 20,
	PAD_Y = 20,
	PANEL_WIDTH = 560,
	SLIDER_WIDTH = 240,
	SLIDER_HEIGHT = 17,
	LIST_WIDTH = 560,
	LIST_HEIGHT = 350,
	LIST_INNER_PAD = 10,
	ROW_HEIGHT = 30,
	ROW_SPACING = 3,
	BTN_W = 48,
	BTN_H = 20,
	BTN_GAP = 4,
	BTN_RIGHT_PAD = 6,
}

function InitializeAddon(self)
	self:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("ADDON_LOADED")
	
	-- Create delete confirmation dialog
	StaticPopupDialogs["GRATWURST_DELETE_CONFIRM"] = {
		text = "Are you sure you want to delete this message?\n\n\"%s\"",
		button1 = "Delete",
		button2 = "Cancel",
		OnAccept = function(self, data)
			DeleteMessage(data)
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
end

function InitializeSavedVariables(self)
	GratwurstMessage = GratwurstMessage or ""
	GratwurstDelayInSeconds = GratwurstDelayInSeconds or 3
	GratwurstRandomDelayMax = GratwurstRandomDelayMax or GratwurstDelayInSeconds
	if GratwurstEnabled == nil then
		GratwurstEnabled = true
	end
	GratwurstVariancePercentage = GratwurstVariancePercentage or 50
	-- Always reset on load: a timer cannot survive a session boundary, so a
	-- saved true value would permanently block all sends.
	GratwurstIsGratzing = false
	if GratwurstShouldRandomize == nil then
		GratwurstShouldRandomize = true
	end
	
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
			"Gratz %c!",
			"Congratulations %c on %v!",
			"Well done %c (%l)!",
			"Awesome achievement %c!",
			"Nice work %c from <%g>!",
			"Gratz on the achievement %c!",
			"Congratulations %c! Level %l %C",
			"Great job %c!",
			"Achievement unlocked! Well done %c!",
			"Gratz on the progress %c!"
		}
	end

	-- VIP: per-character name list and their special messages
	GratwurstVIPNames = GratwurstVIPNames or {}
	GratwurstVIPMessages = GratwurstVIPMessages or {}
end

-- Splits a multi-line string into a trimmed, non-blank list of strings.
local function ParseLines(text)
	local t = {}
	for line in text:gmatch("[^\n]+") do
		local trimmed = line:match("^%s*(.-)%s*$")
		if trimmed ~= "" then
			table.insert(t, trimmed)
		end
	end
	return t
end

local function HasAnyNonEmptyMessage()
	if type(GratwurstMessages) ~= "table" then
		return false
	end

	for _, message in ipairs(GratwurstMessages) do
		if type(message) == "string" and message:match("%S") then
			return true
		end
	end

	return false
end

function SetConfigurationWindow()
	local parent = SettingsPanel or InterfaceOptionsFramePanelContainer or UIParent
	local luaFrame = CreateFrame("Frame", "GratwurstPanel", parent)

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

	-- Hidden clickable overlay on the title banner — opens the VIP special-messages dialog.
	-- No label, no visible hint; the cursor just changes to the hand on hover.
	local titleHitbox = CreateFrame("Button", nil, luaFrame)
	titleHitbox:SetPoint("TOP", luaFrame, "TOP", 0, 5)
	titleHitbox:SetSize(320, 50)
	titleHitbox:SetScript("OnClick", function()
		ShowVIPDialog()
	end)
	titleHitbox:SetScript("OnEnter", function()
		titleString:SetTextColor(1, 1, 0.6)
	end)
	titleHitbox:SetScript("OnLeave", function()
		titleString:SetTextColor(1, 0.8196079, 0)
	end)

	Gratwurst = {};
	Gratwurst.ui = {};
	Gratwurst.ui.panel = luaFrame
	Gratwurst.ui.panel.name = "Gratwurst";

	-- Tooltip helpers
	local function ShowTooltip(owner, text)
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
		GameTooltip:SetText(text, 1, 1, 1, 1, true)
		GameTooltip:Show()
	end
	local function AttachTooltip(frame, text)
		if not frame then return end
		if frame.HookScript then
			frame:HookScript("OnEnter", function(self) ShowTooltip(self, text) end)
			frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
		else
			frame:SetScript("OnEnter", function(self) ShowTooltip(self, text) end)
			frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end
	end

	-- Left-hand controls stack: checkbox → Max Delay slider → Frequency slider
	local controlsLeft = CreateFrame("Frame", nil, Gratwurst.ui.panel)
	controlsLeft:SetPoint("TOPLEFT", Gratwurst.ui.panel, "TOPLEFT", UI.PAD_X, -70)
	controlsLeft:SetWidth(UI.SLIDER_WIDTH)
	controlsLeft:SetHeight(160)

	-- Checkbox row
	local randomizeHelpText = "When enabled, Gratwurst picks a random message from your list.\n\nWhen disabled, it always uses the first message (#1) in the list."
	local checkbox = CreateFrame("CheckButton", "GratwurstCheckbox", controlsLeft, "ChatConfigCheckButtonTemplate")
	checkbox:SetPoint("TOPLEFT", controlsLeft, "TOPLEFT", 0, 0)
	checkbox:SetChecked(GratwurstShouldRandomize)
	checkbox:SetScript("OnClick", function(self) GratwurstShouldRandomize = self:GetChecked() end)
	checkbox:SetScript("OnEnter", function(self) ShowTooltip(self, randomizeHelpText) end)
	checkbox:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local checkboxLabel = checkbox:CreateFontString("GratwurstCheckboxLabel")
	checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 4, -1)
	checkboxLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	checkboxLabel:SetWidth(UI.SLIDER_WIDTH - 30)
	checkboxLabel:SetHeight(20)
	checkboxLabel:SetTextColor(1, 1, 1)
	checkboxLabel:SetShadowOffset(1, -1)
	checkboxLabel:SetShadowColor(0, 0, 0)
	checkboxLabel:SetJustifyH("LEFT")
	checkboxLabel:SetText("Random message selection")

	local checkboxLabelHitbox = CreateFrame("Frame", nil, controlsLeft)
	checkboxLabelHitbox:SetPoint("TOPLEFT", checkboxLabel, "TOPLEFT", 0, 4)
	checkboxLabelHitbox:SetPoint("BOTTOMRIGHT", checkboxLabel, "BOTTOMRIGHT", 0, -4)
	checkboxLabelHitbox:EnableMouse(true)
	checkboxLabelHitbox:SetScript("OnEnter", function(self) ShowTooltip(self, randomizeHelpText) end)
	checkboxLabelHitbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
	checkboxLabelHitbox:SetScript("OnMouseUp", function() checkbox:Click() end)

	-- Max Delay slider (below checkbox)
	local maxDelayHelpText = "How long Gratwurst may wait before sending a message.\n\nFor each eligible achievement, it waits a random time from 1 to this value (seconds)."

	local maxDelaySliderLabel = controlsLeft:CreateFontString("MaxDelaySliderLabel")
	maxDelaySliderLabel:SetPoint("TOPLEFT", controlsLeft, "TOPLEFT", 0, -36)
	maxDelaySliderLabel:SetFont("Fonts\\FRIZQT__.TTF", 11)
	maxDelaySliderLabel:SetWidth(UI.SLIDER_WIDTH)
	maxDelaySliderLabel:SetHeight(20)
	maxDelaySliderLabel:SetTextColor(1, 1, 1)
	maxDelaySliderLabel:SetShadowOffset(1, -1)
	maxDelaySliderLabel:SetShadowColor(0, 0, 0)
	maxDelaySliderLabel:SetJustifyH("LEFT")
	maxDelaySliderLabel:SetText("Max Delay (seconds)")

	local maxDelayLabelHitbox = CreateFrame("Frame", nil, controlsLeft)
	maxDelayLabelHitbox:SetPoint("TOPLEFT", maxDelaySliderLabel, "TOPLEFT", 0, 4)
	maxDelayLabelHitbox:SetPoint("BOTTOMRIGHT", maxDelaySliderLabel, "BOTTOMRIGHT", 0, -4)
	maxDelayLabelHitbox:EnableMouse(true)
	AttachTooltip(maxDelayLabelHitbox, maxDelayHelpText)

	local maxDelaySlider = CreateFrame("Slider", "MaxDelaySlider", controlsLeft, "OptionsSliderTemplate")
	maxDelaySlider:SetPoint("TOPLEFT", controlsLeft, "TOPLEFT", 0, -54)
	maxDelaySlider:SetWidth(UI.SLIDER_WIDTH)
	maxDelaySlider:SetHeight(UI.SLIDER_HEIGHT)
	maxDelaySlider:SetOrientation("HORIZONTAL")
	maxDelaySlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	maxDelaySlider:SetMinMaxValues(1, 9)
	maxDelaySlider:SetValue(GratwurstRandomDelayMax)
	maxDelaySlider:SetValueStep(1)
	maxDelaySlider:SetObeyStepOnDrag(true)
	AttachTooltip(maxDelaySlider, maxDelayHelpText)
	_G[maxDelaySlider:GetName().."Low"]:Hide()
	_G[maxDelaySlider:GetName().."High"]:Hide()

	local maxDelayMinLabel = controlsLeft:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	maxDelayMinLabel:SetPoint("TOPLEFT", maxDelaySlider, "BOTTOMLEFT", 0, -4)
	maxDelayMinLabel:SetText("1")
	maxDelayMinLabel:SetTextColor(0.7, 0.7, 0.7)

	local maxDelayMaxLabel = controlsLeft:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	maxDelayMaxLabel:SetPoint("TOPRIGHT", maxDelaySlider, "BOTTOMRIGHT", 0, -4)
	maxDelayMaxLabel:SetText("9")
	maxDelayMaxLabel:SetTextColor(0.7, 0.7, 0.7)

	local maxDelayValueLabel = controlsLeft:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	maxDelayValueLabel:SetPoint("TOP", maxDelaySlider, "BOTTOM", 0, -16)
	maxDelayValueLabel:SetText(GratwurstRandomDelayMax)
	maxDelayValueLabel:SetTextColor(1, 0.82, 0)

	maxDelaySlider:SetScript("OnValueChanged", function(self)
		GratwurstRandomDelayMax = self:GetValue()
		maxDelayValueLabel:SetText(GratwurstRandomDelayMax)
	end)

	-- Frequency slider (below Max Delay)
	local frequencyHelpText = "Chance to send a grats message when a guild achievement happens.\n\nExample: 80% means ~8 out of 10 achievements get a message."

	local MaxFrequencySliderLabel = controlsLeft:CreateFontString("MaxFrequencySliderLabel")
	MaxFrequencySliderLabel:SetPoint("TOPLEFT", controlsLeft, "TOPLEFT", 0, -100)
	MaxFrequencySliderLabel:SetFont("Fonts\\FRIZQT__.TTF", 11)
	MaxFrequencySliderLabel:SetWidth(UI.SLIDER_WIDTH)
	MaxFrequencySliderLabel:SetHeight(20)
	MaxFrequencySliderLabel:SetTextColor(1, 1, 1)
	MaxFrequencySliderLabel:SetShadowOffset(1, -1)
	MaxFrequencySliderLabel:SetShadowColor(0, 0, 0)
	MaxFrequencySliderLabel:SetJustifyH("LEFT")
	MaxFrequencySliderLabel:SetText("Frequency (%)")

	local frequencyLabelHitbox = CreateFrame("Frame", nil, controlsLeft)
	frequencyLabelHitbox:SetPoint("TOPLEFT", MaxFrequencySliderLabel, "TOPLEFT", 0, 4)
	frequencyLabelHitbox:SetPoint("BOTTOMRIGHT", MaxFrequencySliderLabel, "BOTTOMRIGHT", 0, -4)
	frequencyLabelHitbox:EnableMouse(true)
	AttachTooltip(frequencyLabelHitbox, frequencyHelpText)

	local MaxFrequencySlider = CreateFrame("Slider", "MaxFrequencySlider", controlsLeft, "OptionsSliderTemplate")
	MaxFrequencySlider:SetPoint("TOPLEFT", controlsLeft, "TOPLEFT", 0, -118)
	MaxFrequencySlider:SetWidth(UI.SLIDER_WIDTH)
	MaxFrequencySlider:SetHeight(UI.SLIDER_HEIGHT)
	MaxFrequencySlider:SetOrientation("HORIZONTAL")
	MaxFrequencySlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	MaxFrequencySlider:SetMinMaxValues(0, 100)
	MaxFrequencySlider:SetValue(GratwurstVariancePercentage)
	MaxFrequencySlider:SetValueStep(1)
	MaxFrequencySlider:SetObeyStepOnDrag(true)
	AttachTooltip(MaxFrequencySlider, frequencyHelpText)
	_G[MaxFrequencySlider:GetName().."Low"]:Hide()
	_G[MaxFrequencySlider:GetName().."High"]:Hide()

	local frequencyMinLabel = controlsLeft:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frequencyMinLabel:SetPoint("TOPLEFT", MaxFrequencySlider, "BOTTOMLEFT", 0, -4)
	frequencyMinLabel:SetText("0%")
	frequencyMinLabel:SetTextColor(0.7, 0.7, 0.7)

	local frequencyMaxLabel = controlsLeft:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frequencyMaxLabel:SetPoint("TOPRIGHT", MaxFrequencySlider, "BOTTOMRIGHT", 0, -4)
	frequencyMaxLabel:SetText("100%")
	frequencyMaxLabel:SetTextColor(0.7, 0.7, 0.7)

	local frequencyValueLabel = controlsLeft:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frequencyValueLabel:SetPoint("TOP", MaxFrequencySlider, "BOTTOM", 0, -16)
	frequencyValueLabel:SetText(GratwurstVariancePercentage .. "%")
	frequencyValueLabel:SetTextColor(1, 0.82, 0)

	MaxFrequencySlider:SetScript("OnValueChanged", function(self)
		GratwurstVariancePercentage = self:GetValue()
		frequencyValueLabel:SetText(GratwurstVariancePercentage .. "%")
	end)

	-- Create the backdrop for the message list
	local backdropFrame = CreateFrame("Frame", nil, Gratwurst.ui.panel, BackdropTemplateMixin and "BackdropTemplate")
	backdropFrame:SetPoint("TOPLEFT", UI.PAD_X, -240)
	backdropFrame:SetPoint("BOTTOMRIGHT", Gratwurst.ui.panel, "BOTTOMRIGHT", -UI.PAD_X, 18)
	backdropFrame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
		tile = true,
		tileSize = 12,
		edgeSize = 8,
		insets = { left = 5, right = 3, top = 3, bottom = 3	},
	})

	-- Create the Messages List label inside the table area
	local gratzListLabel = backdropFrame:CreateFontString("GratzListLabel")
	gratzListLabel:SetPoint("TOP", backdropFrame, "TOP", 0, -15)
	gratzListLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)
	gratzListLabel:SetWidth(UI.LIST_WIDTH - 30)
	gratzListLabel:SetHeight(20)
	gratzListLabel:SetTextColor(1, 0.8196079, 0)
	gratzListLabel:SetShadowOffset(1, -1)
	gratzListLabel:SetShadowColor(0, 0, 0)
	gratzListLabel:SetText("Messages List")

	-- Message count label (top-right, avoids overlapping bottom buttons)
	local messageCountLabel = backdropFrame:CreateFontString("MessageCountLabel")
	messageCountLabel:SetPoint("TOPRIGHT", backdropFrame, "TOPRIGHT", -18, -16)
	messageCountLabel:SetFont("Fonts\\FRIZQT__.TTF", 11)
	messageCountLabel:SetTextColor(0.8, 0.8, 0.8)
	messageCountLabel:SetText("Messages: 0")
	Gratwurst.ui.messageCountLabel = messageCountLabel

	-- Column headers
	local headerFrame = CreateFrame("Frame", nil, backdropFrame)
	headerFrame:SetPoint("TOPLEFT", backdropFrame, "TOPLEFT", UI.LIST_INNER_PAD, -38)
	headerFrame:SetPoint("TOPRIGHT", backdropFrame, "TOPRIGHT", -(UI.LIST_INNER_PAD + 18), -38) -- 18 ~= scrollbar gutter
	headerFrame:SetHeight(16)

	local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
	headerBg:SetAllPoints()
	headerBg:SetColorTexture(0, 0, 0, 0.25)

	local headerNum = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	headerNum:SetPoint("LEFT", headerFrame, "LEFT", 8, 0)
	headerNum:SetText("#")

	local headerMsg = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	headerMsg:SetPoint("LEFT", headerFrame, "LEFT", 34, 0)
	headerMsg:SetText("Message")

	local headerActions = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	headerActions:SetPoint("RIGHT", headerFrame, "RIGHT", -8, 0)
	headerActions:SetText("Actions")

	-- Create ScrollFrame for message list
	local scrollFrame = CreateFrame("ScrollFrame", "GratwurstMessageScrollFrame", backdropFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -6)
	scrollFrame:SetPoint("BOTTOMRIGHT", backdropFrame, "BOTTOMRIGHT", -30, 42)
	
	-- Create the content frame for the scroll frame
	local contentFrame = CreateFrame("Frame", "GratwurstMessageContentFrame", scrollFrame)
	contentFrame:SetSize(400, 100) -- width updated after layout; height updated dynamically
	scrollFrame:SetScrollChild(contentFrame)

	local function UpdateContentWidth()
		local w = scrollFrame:GetWidth()
		if not w or w <= 0 then
			return
		end
		-- Leave room so rows don't sit under the scrollbar
		local padded = math.max(1, w - 22)
		contentFrame:SetWidth(padded)
	end

	scrollFrame:HookScript("OnShow", UpdateContentWidth)
	scrollFrame:HookScript("OnSizeChanged", UpdateContentWidth)
	UpdateContentWidth()
	
	-- Store references for later use
	Gratwurst.ui.scrollFrame = scrollFrame
	Gratwurst.ui.contentFrame = contentFrame
	Gratwurst.ui.messageFrames = {}
	
	-- Create control buttons below the scroll frame
	local addButton = CreateFrame("Button", "GratwurstAddButton", backdropFrame, "UIPanelButtonTemplate")
	addButton:SetSize(130, 24)
	addButton:SetPoint("BOTTOMLEFT", backdropFrame, "BOTTOMLEFT", 15, 10)
	addButton:SetText("Add Message")
	addButton:SetScript("OnClick", function()
		ShowAddMessageDialog()
	end)
	AttachTooltip(addButton, "Add a new message to your list.")
	
	-- Restore Defaults button
	local restoreButton = CreateFrame("Button", "GratwurstRestoreButton", backdropFrame, "UIPanelButtonTemplate")
	restoreButton:SetSize(130, 24)
	restoreButton:SetPoint("BOTTOMRIGHT", backdropFrame, "BOTTOMRIGHT", -15, 10)
	restoreButton:SetText("Restore Defaults")
	restoreButton:SetScript("OnClick", function()
		-- Show confirmation dialog
		StaticPopupDialogs["GRATWURST_RESTORE_CONFIRM"] = {
			text = "This will replace all your messages with the default ones. Are you sure?",
			button1 = "Yes",
			button2 = "Cancel",
			OnAccept = function()
				RestoreDefaultMessages()
				RefreshMessageList()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("GRATWURST_RESTORE_CONFIRM")
	end)
	AttachTooltip(restoreButton, "Replace your message list with the built-in defaults.\n\nThis cannot be undone.")

	-- Edit as Text button (centre of bottom bar)
	local editAsTextButton = CreateFrame("Button", "GratwurstEditAsTextButton", backdropFrame, "UIPanelButtonTemplate")
	editAsTextButton:SetSize(130, 24)
	editAsTextButton:SetPoint("BOTTOM", backdropFrame, "BOTTOM", 0, 10)
	editAsTextButton:SetText("Edit as Text")
	editAsTextButton:SetScript("OnClick", function()
		ShowBulkEditDialog()
	end)
	AttachTooltip(editAsTextButton, "Edit all messages as plain text.\nOne message per line — paste a whole new set at once.")
	
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
	-- Prevent spam: ignore additional achievements while a gratz is already pending or in-flight
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
		if canGrats and not InCombatLockdown() and GratwurstEnabled then
			-- VIP check: if the achiever is on the VIP list and VIP messages exist, use those
			local vipMessage = GetVIPMessageForAuthor(author)
			if vipMessage then
				if isDebug then
					print("VIP message: " .. vipMessage)
				else
					C_ChatInfo.SendChatMessage(vipMessage, "GUILD")
				end
			elseif HasAnyNonEmptyMessage() then
				if GratwurstShouldRandomize then
					if isDebug then
						print("GetRandomMessageFromList(author): " .. GetRandomMessageFromList(author))
					else
						C_ChatInfo.SendChatMessage(GetRandomMessageFromList(author), "GUILD")
					end
				else
					if isDebug then
						print("GetTopMessageFromList(author): " .. GetTopMessageFromList(author))
					else
						C_ChatInfo.SendChatMessage(GetTopMessageFromList(author), "GUILD")
					end
				end
			end
		end
		GratwurstIsGratzing = false
    end)
end

-- Returns a processed VIP message if the author is on the VIP names list and VIP messages
-- are configured, otherwise returns nil so the normal pool is used.
function GetVIPMessageForAuthor(author)
	if type(GratwurstVIPNames) ~= "table" or #GratwurstVIPNames == 0 then
		return nil
	end
	if type(GratwurstVIPMessages) ~= "table" or #GratwurstVIPMessages == 0 then
		return nil
	end

	-- author arrives as "Name-Realm"; compare case-insensitively against stored names
	-- which may be bare names ("Taco") or name-realm ("Taco-Realm").
	local authorLower = author:lower()
	local authorName  = authorLower:match("^([^%-]+)") or authorLower

	local isVIP = false
	for _, vipEntry in ipairs(GratwurstVIPNames) do
		local entryLower = vipEntry:lower():match("^%s*(.-)%s*$")
		if entryLower == authorLower or entryLower == authorName then
			isVIP = true
			break
		end
	end

	if not isVIP then
		return nil
	end

	-- Pick a random VIP message and expand placeholders
	local idx = math.random(1, #GratwurstVIPMessages)
	local message = GratwurstVIPMessages[idx]
	local result = FindAndReplacePlayerNameToken(message, author)
	-- Guard against a blank result so the normal pool is used as fallback
	if not result or not result:match("%S") then
		return nil
	end
	return result
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
	
	-- Always use advanced placeholders (Lancaban mode is now default)
	result = ReplaceLancabanPlaceholders(result, author)
	
	return result
end

function ReplaceLancabanPlaceholders(message, author)
	local result = message
	local playerName = string.gsub(author, "%-.*", "")
	
	-- Check if this is for preview (test data)
	local isPreview = (author == "JohnnyAwesome-TestRealm")
	
	if isPreview then
		-- Use example data for preview
		local exampleLevel = 80
		local exampleClass = "Paladin"
		local exampleGuildName = "Awesome Guild"
		local exampleGuildRank = "Member"
		local maxLevel = 80
		
		-- %c - Character Name
		result = string.gsub(result, "%%c", playerName)
		
		-- %n - name as used in %s (same as character name for now)
		result = string.gsub(result, "%%n", playerName)
		
		-- %a - alias of current character (use short name)
		result = string.gsub(result, "%%a", playerName)
		
		-- %m - main if available (not easily accessible, use current name)
		result = string.gsub(result, "%%m", playerName)
		
		-- %A - Main Alias if available (not easily accessible, use current name)
		result = string.gsub(result, "%%A", playerName)
		
		-- %l - level if available
		result = string.gsub(result, "%%l", tostring(exampleLevel))
		
		-- %L - levels left to cap
		local levelsLeft = math.max(0, maxLevel - exampleLevel)
		result = string.gsub(result, "%%L", tostring(levelsLeft))
		
		-- %C - class if available
		result = string.gsub(result, "%%C", exampleClass)
		
		-- %r - rank name
		result = string.gsub(result, "%%r", exampleGuildRank)
		
		-- %v - achievement (example)
		result = string.gsub(result, "%%v", "Level 80")
		
		-- %g - guild alias (short guild name)
		local guildAlias = string.sub(exampleGuildName, 1, 10)
		result = string.gsub(result, "%%g", guildAlias)
		
		-- %G - Guild Name
		result = string.gsub(result, "%%G", exampleGuildName)
		
		-- Gratz-specific placeholders
		-- #n - Name of the achiever
		result = string.gsub(result, "#n", playerName)
		
		-- #g - Name of the guild
		result = string.gsub(result, "#g", exampleGuildName)
		
		-- #f - Name of your faction
		result = string.gsub(result, "#f", "Horde")
		
		-- #e - Name of the enemy faction
		result = string.gsub(result, "#e", "Alliance")
		
		-- #b - Name of the battleground (example)
		result = string.gsub(result, "#b", "Warsong Gulch")
		
		-- #v - achievement name (example)
		result = string.gsub(result, "#v", "Level 80")
		
		-- Legacy $player support
		result = string.gsub(result, "$player", playerName)
		
	else
		-- Get player info if available (real data)
		local level, class, guildName, guildRank = GetPlayerInfo(author)
		
		-- %c - Character Name
		result = string.gsub(result, "%%c", playerName)
		
		-- %n - name as used in %s (same as character name for now)
		result = string.gsub(result, "%%n", playerName)
		
		-- %a - alias of current character (use short name)
		result = string.gsub(result, "%%a", playerName)
		
		-- %m - main if available (not easily accessible, use current name)
		result = string.gsub(result, "%%m", playerName)
		
		-- %A - Main Alias if available (not easily accessible, use current name)
		result = string.gsub(result, "%%A", playerName)
		
		-- %l - level if available
		if level and level > 0 then
			result = string.gsub(result, "%%l", tostring(level))
		else
			result = string.gsub(result, "%%l", "")
		end
		
		-- %L - levels left to cap
		if level and level > 0 then
			local maxLevel = GetMaxPlayerLevel() or 80
			local levelsLeft = math.max(0, maxLevel - level)
			result = string.gsub(result, "%%L", tostring(levelsLeft))
		else
			result = string.gsub(result, "%%L", "")
		end
		
		-- %C - class if available
		if class and class ~= "" then
			result = string.gsub(result, "%%C", class)
		else
			result = string.gsub(result, "%%C", "")
		end
		
		-- %r - rank name
		if guildRank and guildRank ~= "" then
			result = string.gsub(result, "%%r", guildRank)
		else
			result = string.gsub(result, "%%r", "")
		end
		
		-- %v - achievement (placeholder for now, would need achievement data from event)
		result = string.gsub(result, "%%v", "their achievement")
		
		-- %g - guild alias (short guild name)
		if guildName and guildName ~= "" then
			local guildAlias = string.sub(guildName, 1, 10) -- First 10 chars as alias
			result = string.gsub(result, "%%g", guildAlias)
		else
			result = string.gsub(result, "%%g", "")
		end
		
		-- %G - Guild Name
		if guildName and guildName ~= "" then
			result = string.gsub(result, "%%G", guildName)
		else
			result = string.gsub(result, "%%G", "")
		end
		
		-- Gratz-specific placeholders (these would need more context from the achievement event)
		-- #n - Name of the achiever
		result = string.gsub(result, "#n", playerName)
		
		-- #g - Name of the guild
		if guildName and guildName ~= "" then
			result = string.gsub(result, "#g", guildName)
		else
			result = string.gsub(result, "#g", "")
		end
		
		-- #f - Name of your faction
		local factionName = UnitFactionGroup("player") or ""
		result = string.gsub(result, "#f", factionName)
		
		-- #e - Name of the enemy faction
		local enemyFaction = (factionName == "Alliance") and "Horde" or "Alliance"
		result = string.gsub(result, "#e", enemyFaction)
		
		-- #b - Name of the battleground (would need battleground context)
		result = string.gsub(result, "#b", "")
		
		-- #v - achievement name (would need achievement data from event)
		result = string.gsub(result, "#v", "")
		
		-- Legacy $player support
		result = string.gsub(result, "$player", playerName)
	end
	
	return result
end

function GetPlayerInfo(fullPlayerName)
	local playerName = string.gsub(fullPlayerName, "%-.*", "")
	local level = 0
	local class = ""
	local guildName = ""
	local guildRank = ""
	
	-- Try to get info if player is in guild
	local numGuildMembers = GetNumGuildMembers()
	for i = 1, numGuildMembers do
		local name, rank, rankIndex, playerLevel, playerClass, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i)
		if name and string.gsub(name, "%-.*", "") == playerName then
			level = playerLevel or 0
			class = playerClass or ""
			guildRank = rank or ""
			guildName = GetGuildInfo("player") or ""
			break
		end
	end
	
	return level, class, guildName, guildRank
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
		"Gratz %c!",
		"Congratulations %c on %v!",
		"Well done %c (%l)!",
		"Awesome achievement %c!",
		"Nice work %c from <%g>!",
		"Gratz on the achievement %c!",
		"Congratulations %c! Level %l %C",
		"Great job %c!",
		"Achievement unlocked! Well done %c!",
		"Gratz on the progress %c!"
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
	local frameHeight = UI.ROW_HEIGHT
	local spacing = UI.ROW_SPACING
	local totalHeight = 0
	
	-- Create message frames
	for i, message in ipairs(GratwurstMessages) do
		local messageFrame = CreateFrame("Frame", "GratwurstMessageFrame" .. i, contentFrame)
		messageFrame:SetHeight(frameHeight)
		messageFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -totalHeight)
		messageFrame:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, -totalHeight)
		
		-- Background highlight
		local background = messageFrame:CreateTexture("GratwurstMessageBackground" .. i)
		background:SetAllPoints()
		if i % 2 == 0 then
			background:SetColorTexture(0.15, 0.15, 0.15, 0.8)
		else
			background:SetColorTexture(0.1, 0.1, 0.1, 0.8)
		end

		local hover = messageFrame:CreateTexture(nil, "HIGHLIGHT")
		hover:SetAllPoints()
		hover:SetColorTexture(1, 1, 1, 0.06)
		hover:Hide()
		
		-- Message number
		local numberText = messageFrame:CreateFontString("GratwurstMessageNumber" .. i)
		numberText:SetPoint("LEFT", messageFrame, "LEFT", 8, 0)
		numberText:SetFont("Fonts\\FRIZQT__.TTF", 11)
		numberText:SetWidth(24)
		numberText:SetJustifyH("CENTER")
		numberText:SetText(i)
		numberText:SetTextColor(0.7, 0.7, 0.7)
		
		-- Message text
		-- Move up button
		local upButton = CreateFrame("Button", "GratwurstUpButton" .. i, messageFrame, "UIPanelButtonTemplate")
		upButton:SetSize(UI.BTN_W, UI.BTN_H)
		upButton:SetPoint("RIGHT", messageFrame, "RIGHT", -UI.BTN_RIGHT_PAD, 0)
		upButton:SetText("Up")
		upButton:SetScript("OnClick", function()
			MoveMessageUp(i)
		end)
		if i == 1 then
			upButton:Disable()
			upButton:SetAlpha(0.3)
		end

		-- Move down button
		local downButton = CreateFrame("Button", "GratwurstDownButton" .. i, messageFrame, "UIPanelButtonTemplate")
		downButton:SetSize(UI.BTN_W, UI.BTN_H)
		downButton:SetPoint("RIGHT", upButton, "LEFT", -UI.BTN_GAP, 0)
		downButton:SetText("Down")
		downButton:SetScript("OnClick", function()
			MoveMessageDown(i)
		end)
		if i == #GratwurstMessages then
			downButton:Disable()
			downButton:SetAlpha(0.3)
		end

		-- Edit button
		local editButton = CreateFrame("Button", "GratwurstEditButton" .. i, messageFrame, "UIPanelButtonTemplate")
		editButton:SetSize(UI.BTN_W, UI.BTN_H)
		editButton:SetPoint("RIGHT", downButton, "LEFT", -UI.BTN_GAP, 0)
		editButton:SetText("Edit")
		editButton:SetScript("OnClick", function()
			ShowEditMessageDialog(i, message)
		end)

		-- Delete button
		local deleteButton = CreateFrame("Button", "GratwurstDeleteButton" .. i, messageFrame, "UIPanelButtonTemplate")
		deleteButton:SetSize(UI.BTN_W, UI.BTN_H)
		deleteButton:SetPoint("RIGHT", editButton, "LEFT", -UI.BTN_GAP, 0)
		deleteButton:SetText("Del")
		deleteButton:SetScript("OnClick", function()
			-- Show confirmation dialog for delete
			StaticPopup_Show("GRATWURST_DELETE_CONFIRM", message, nil, i)
		end)

		-- Message text (auto-fills space between number and action buttons)
		local messageText = messageFrame:CreateFontString("GratwurstMessageText" .. i)
		messageText:SetPoint("LEFT", numberText, "RIGHT", 8, 0)
		messageText:SetPoint("RIGHT", deleteButton, "LEFT", -10, 0)
		messageText:SetFont("Fonts\\FRIZQT__.TTF", 11)
		messageText:SetJustifyH("LEFT")
		messageText:SetWordWrap(false)
		messageText:SetMaxLines(1)
		messageText:SetText(message)
		messageText:SetTextColor(1, 1, 1)

		-- subtle separator before actions
		local sep = messageFrame:CreateTexture(nil, "ARTWORK")
		sep:SetPoint("TOPRIGHT", deleteButton, "TOPLEFT", -6, -4)
		sep:SetPoint("BOTTOMRIGHT", deleteButton, "BOTTOMLEFT", -6, 4)
		sep:SetWidth(1)
		sep:SetColorTexture(1, 1, 1, 0.08)

		messageFrame:EnableMouse(true)
		messageFrame:SetScript("OnEnter", function()
			hover:Show()
			if type(message) == "string" and message:match("%S") then
				GameTooltip:SetOwner(messageFrame, "ANCHOR_RIGHT")
				GameTooltip:SetText(message, 1, 1, 1, 1, true)
				GameTooltip:Show()
			end
		end)
		messageFrame:SetScript("OnLeave", function()
			hover:Hide()
			GameTooltip:Hide()
		end)
		
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

function ShowVIPDialog()
	-- Re-use a single instance; refresh content on re-open.
	if GratwurstVIPDialog then
		GratwurstVIPDialog.namesBox:SetText(table.concat(GratwurstVIPNames, "\n"))
		GratwurstVIPDialog.namesBox:SetCursorPosition(0)
		GratwurstVIPDialog.msgsBox:SetText(table.concat(GratwurstVIPMessages, "\n"))
		GratwurstVIPDialog.msgsBox:SetCursorPosition(0)
		GratwurstVIPDialog:Show()
		GratwurstVIPDialog.namesBox:SetFocus()
		return
	end

	local dialog = CreateFrame("Frame", "GratwurstVIPDialogFrame", UIParent, "BackdropTemplate")
	GratwurstVIPDialog = dialog
	dialog:SetSize(660, 520)
	dialog:SetPoint("CENTER")
	dialog:SetFrameStrata("DIALOG")
	dialog:SetFrameLevel(100)
	dialog:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	dialog:SetBackdropColor(0.05, 0.0, 0.08, 1.0)
	dialog:SetMovable(true)
	dialog:EnableMouse(true)
	dialog:RegisterForDrag("LeftButton")
	dialog:SetScript("OnDragStart", dialog.StartMoving)
	dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
	dialog:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" then dialog:Hide() end
	end)

	-- Title
	local titleBorder = dialog:CreateTexture(nil, "BORDER")
	titleBorder:SetWidth(260)
	titleBorder:SetHeight(50)
	titleBorder:SetPoint("TOP", dialog, "TOP", 0, 5)
	titleBorder:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	titleBorder:SetTexCoord(.2, .8, 0, .6)

	local titleStr = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	titleStr:SetPoint("TOP", dialog, "TOP", 0, -15)
	titleStr:SetText("Special Messages")
	titleStr:SetTextColor(1, 0.82, 0)

	-- Subtitle
	local subtitle = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subtitle:SetPoint("TOP", dialog, "TOP", 0, -40)
	subtitle:SetText("When an achievement comes from one of these characters, use one of these messages instead.")
	subtitle:SetTextColor(0.7, 0.7, 0.7)
	subtitle:SetWidth(600)
	subtitle:SetJustifyH("CENTER")

	local PANE_TOP    = -65
	local PANE_BOTTOM = 55  -- space for buttons
	local PANE_W      = 278
	local INNER_PAD   = 12

	-- ── Left pane: character names ───────────────────────────────────────────

	local leftPane = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
	leftPane:SetPoint("TOPLEFT",  dialog, "TOPLEFT",  20, PANE_TOP)
	leftPane:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 20, PANE_BOTTOM)
	leftPane:SetWidth(PANE_W)
	leftPane:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
		tile = true, tileSize = 12, edgeSize = 8,
		insets = { left = 5, right = 3, top = 3, bottom = 3 }
	})

	local leftLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	leftLabel:SetPoint("TOP", leftPane, "TOP", 0, -10)
	leftLabel:SetText("Character Names")
	leftLabel:SetTextColor(1, 0.82, 0)

	local leftHint = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	leftHint:SetPoint("TOP", leftPane, "TOP", 0, -26)
	leftHint:SetText("One name per line")
	leftHint:SetTextColor(0.6, 0.6, 0.6)

	local leftScroll = CreateFrame("ScrollFrame", "GratwurstVIPNamesScroll", leftPane, "UIPanelScrollFrameTemplate")
	leftScroll:SetPoint("TOPLEFT",     leftPane, "TOPLEFT",  INNER_PAD, -46)
	leftScroll:SetPoint("BOTTOMRIGHT", leftPane, "BOTTOMRIGHT", -(INNER_PAD + 18), INNER_PAD)

	local namesBox = CreateFrame("EditBox", "GratwurstVIPNamesBox", leftScroll)
	namesBox:SetMultiLine(true)
	namesBox:SetAutoFocus(false)
	namesBox:SetFontObject("ChatFontNormal")
	namesBox:SetWidth(leftScroll:GetWidth() or 220)
	namesBox:SetTextColor(1, 1, 1)
	namesBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
	leftScroll:SetScrollChild(namesBox)
	leftScroll:HookScript("OnSizeChanged", function()
		local w = leftScroll:GetWidth()
		if w and w > 0 then namesBox:SetWidth(w) end
	end)
	namesBox:SetText(table.concat(GratwurstVIPNames, "\n"))
	namesBox:SetCursorPosition(0)
	dialog.namesBox = namesBox

	-- ── Right pane: special messages ─────────────────────────────────────────

	local rightPane = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
	rightPane:SetPoint("TOPRIGHT",    dialog, "TOPRIGHT",   -20, PANE_TOP)
	rightPane:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -20, PANE_BOTTOM)
	rightPane:SetWidth(PANE_W)
	rightPane:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
		tile = true, tileSize = 12, edgeSize = 8,
		insets = { left = 5, right = 3, top = 3, bottom = 3 }
	})

	local rightLabel = rightPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	rightLabel:SetPoint("TOP", rightPane, "TOP", 0, -10)
	rightLabel:SetText("Special Messages")
	rightLabel:SetTextColor(1, 0.82, 0)

	local rightHint = rightPane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	rightHint:SetPoint("TOP", rightPane, "TOP", 0, -26)
	rightHint:SetText("One message per line  •  supports placeholders")
	rightHint:SetTextColor(0.6, 0.6, 0.6)

	local rightScroll = CreateFrame("ScrollFrame", "GratwurstVIPMsgsScroll", rightPane, "UIPanelScrollFrameTemplate")
	rightScroll:SetPoint("TOPLEFT",     rightPane, "TOPLEFT",  INNER_PAD, -46)
	rightScroll:SetPoint("BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", -(INNER_PAD + 18), INNER_PAD)

	local msgsBox = CreateFrame("EditBox", "GratwurstVIPMsgsBox", rightScroll)
	msgsBox:SetMultiLine(true)
	msgsBox:SetAutoFocus(false)
	msgsBox:SetFontObject("ChatFontNormal")
	msgsBox:SetWidth(rightScroll:GetWidth() or 220)
	msgsBox:SetTextColor(1, 1, 1)
	msgsBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
	rightScroll:SetScrollChild(msgsBox)
	rightScroll:HookScript("OnSizeChanged", function()
		local w = rightScroll:GetWidth()
		if w and w > 0 then msgsBox:SetWidth(w) end
	end)
	msgsBox:SetText(table.concat(GratwurstVIPMessages, "\n"))
	msgsBox:SetCursorPosition(0)
	dialog.msgsBox = msgsBox

	-- ── Bottom buttons ────────────────────────────────────────────────────────

	local saveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	saveButton:SetSize(100, 28)
	saveButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 25, 20)
	saveButton:SetText("Save")
	saveButton:SetScript("OnClick", function()
		GratwurstVIPNames    = ParseLines(namesBox:GetText())
		GratwurstVIPMessages = ParseLines(msgsBox:GetText())
		dialog:Hide()
	end)

	local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	cancelButton:SetSize(80, 28)
	cancelButton:SetPoint("BOTTOMLEFT", saveButton, "BOTTOMRIGHT", 10, 0)
	cancelButton:SetText("Cancel")
	cancelButton:SetScript("OnClick", function()
		dialog:Hide()
	end)

	local clearButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	clearButton:SetSize(80, 28)
	clearButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -25, 20)
	clearButton:SetText("Clear All")
	clearButton:SetScript("OnClick", function()
		namesBox:SetText("")
		msgsBox:SetText("")
	end)

	dialog:Show()
	namesBox:SetFocus()
end

function ShowBulkEditDialog()
	-- Re-use a single instance if it already exists
	if GratwurstBulkEditDialog then
		-- Refresh the text with the current messages and re-show
		local joined = table.concat(GratwurstMessages, "\n")
		GratwurstBulkEditDialog.inputBox:SetText(joined)
		GratwurstBulkEditDialog.inputBox:SetCursorPosition(0)
		GratwurstBulkEditDialog:Show()
		GratwurstBulkEditDialog.inputBox:SetFocus()
		return
	end

	local dialog = CreateFrame("Frame", "GratwurstBulkEditDialogFrame", UIParent, "BackdropTemplate")
	GratwurstBulkEditDialog = dialog
	dialog:SetSize(600, 500)
	dialog:SetPoint("CENTER")
	dialog:SetFrameStrata("DIALOG")
	dialog:SetFrameLevel(100)
	dialog:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	dialog:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
	dialog:SetMovable(true)
	dialog:EnableMouse(true)
	dialog:RegisterForDrag("LeftButton")
	dialog:SetScript("OnDragStart", dialog.StartMoving)
	dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)

	-- Title
	local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", dialog, "TOP", 0, -15)
	title:SetText("Edit Messages as Text")

	-- Instructions
	local instructions = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	instructions:SetPoint("TOPLEFT", dialog, "TOPLEFT", 25, -45)
	instructions:SetWidth(550)
	instructions:SetJustifyH("LEFT")
	instructions:SetText("One message per line. Edit, paste, or replace the whole list, then click Save.")
	instructions:SetTextColor(1, 0.82, 0)

	-- Scroll frame + multiline EditBox
	local scrollFrame = CreateFrame("ScrollFrame", "GratwurstBulkEditScroll", dialog, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, -75)
	scrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -36, 60)

	local inputBox = CreateFrame("EditBox", "GratwurstBulkEditInput", scrollFrame)
	inputBox:SetMultiLine(true)
	inputBox:SetAutoFocus(false)
	inputBox:SetFontObject("ChatFontNormal")
	inputBox:SetWidth(scrollFrame:GetWidth() or 520)
	inputBox:SetTextColor(1, 1, 1)
	inputBox:SetScript("OnEscapePressed", function()
		dialog:Hide()
	end)
	scrollFrame:SetScrollChild(inputBox)
	scrollFrame:HookScript("OnSizeChanged", function()
		local w = scrollFrame:GetWidth()
		if w and w > 0 then
			inputBox:SetWidth(w)
		end
	end)
	dialog.inputBox = inputBox

	-- Populate with current messages
	local joined = table.concat(GratwurstMessages, "\n")
	inputBox:SetText(joined)
	inputBox:SetCursorPosition(0)

	-- Save button
	local saveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	saveButton:SetSize(100, 28)
	saveButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 25, 20)
	saveButton:SetText("Save")
	saveButton:SetScript("OnClick", function()
		local newMessages = ParseLines(inputBox:GetText())
		if #newMessages > 0 then
			GratwurstMessages = newMessages
			SaveMessagesToVariables()
			RefreshMessageList()
		end
		dialog:Hide()
	end)

	local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	cancelButton:SetSize(80, 28)
	cancelButton:SetPoint("BOTTOMLEFT", saveButton, "BOTTOMRIGHT", 10, 0)
	cancelButton:SetText("Cancel")
	cancelButton:SetScript("OnClick", function()
		dialog:Hide()
	end)

	dialog:Show()
	inputBox:SetFocus()
end

function ShowAddMessageDialog()
	local dialog = CreateFrame("Frame", "GratwurstAddDialog", UIParent, "BackdropTemplate")
	dialog:SetSize(750, 400)
	dialog:SetPoint("CENTER")
	dialog:SetFrameStrata("DIALOG")
	dialog:SetFrameLevel(100)
	dialog:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	dialog:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
	dialog:SetMovable(true)
	dialog:EnableMouse(true)
	dialog:RegisterForDrag("LeftButton")
	dialog:SetScript("OnDragStart", dialog.StartMoving)
	dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
	
	-- Title
	local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", dialog, "TOP", 0, -15)
	title:SetText("Add New Message")
	
	-- Instructions
	local instructions = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	instructions:SetPoint("TOPLEFT", dialog, "TOPLEFT", 25, -50)
	instructions:SetText("Enter your congratulations message:")
	instructions:SetTextColor(1, 0.82, 0)
	
	-- Input box
	local inputBox = CreateFrame("EditBox", "GratwurstAddInput", dialog, "InputBoxTemplate")
	inputBox:SetSize(350, 25)
	inputBox:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -15)
	inputBox:SetAutoFocus(true)
	inputBox:SetScript("OnEnterPressed", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			AddNewMessage(text)
			dialog:Hide()
		end
	end)
	inputBox:SetScript("OnEscapePressed", function()
		dialog:Hide()
	end)
	
	-- Preview
	local previewLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	previewLabel:SetPoint("TOPLEFT", inputBox, "BOTTOMLEFT", 0, -15)
	previewLabel:SetText("Preview:")
	previewLabel:SetTextColor(0.8, 0.8, 0.8)
	
	local previewText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	previewText:SetPoint("TOPLEFT", previewLabel, "BOTTOMLEFT", 0, -5)
	previewText:SetWidth(350)
	previewText:SetJustifyH("LEFT")
	previewText:SetText("Gratz JohnnyAwesome!")
	previewText:SetTextColor(0.5, 1, 0.5)
	
	-- Update preview when typing
	inputBox:SetScript("OnTextChanged", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			local preview = ReplaceLancabanPlaceholders(text, "JohnnyAwesome-TestRealm")
			previewText:SetText(preview)
		else
			previewText:SetText("Gratz JohnnyAwesome!")
		end
	end)
	
	-- Helper pane
	local helperFrame = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
	helperFrame:SetSize(300, 320)
	helperFrame:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -25, -50)
	helperFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
		tile = true,
		tileSize = 12,
		edgeSize = 8,
		insets = { left = 5, right = 3, top = 3, bottom = 3 }
	})
	
	local helperTitle = helperFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	helperTitle:SetPoint("TOP", helperFrame, "TOP", 0, -10)
	helperTitle:SetText("Available Placeholders")
	helperTitle:SetTextColor(1, 0.82, 0)
	
	local helperText = helperFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	helperText:SetPoint("TOPLEFT", helperFrame, "TOPLEFT", 15, -35)
	helperText:SetWidth(270)
	helperText:SetJustifyH("LEFT")
	helperText:SetText(
		"|cFFFFFF00Player Info:|r\n" ..
		"%c - Character Name\n" ..
		"%l - Player Level\n" ..
		"%C - Player Class\n" ..
		"%L - Levels to Cap\n\n" ..
		"|cFFFFFF00Guild Info:|r\n" ..
		"%g - Guild Alias\n" ..
		"%G - Guild Name\n" ..
		"%r - Guild Rank\n\n" ..
		"|cFFFFFF00Achievement:|r\n" ..
		"%v - Achievement Name\n" ..
		"#n - Achiever Name\n" ..
		"#g - Guild Name\n\n" ..
		"|cFFFFFF00PvP Info:|r\n" ..
		"#f - Your Faction\n" ..
		"#e - Enemy Faction\n" ..
		"#b - Battleground\n\n" ..
		"|cFFFFFF00Legacy:|r\n" ..
		"$player - Player Name"
	)
	
	-- Buttons
	local addButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	addButton:SetSize(90, 28)
	addButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 25, 20)
	addButton:SetText("Add Message")
	addButton:SetScript("OnClick", function()
		local text = inputBox:GetText()
		if text and text ~= "" then
			AddNewMessage(text)
			dialog:Hide()
		end
	end)
	
	local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	cancelButton:SetSize(80, 28)
	cancelButton:SetPoint("BOTTOMLEFT", addButton, "BOTTOMRIGHT", 10, 0)
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
	inputBox:SetFocus()
end

function ShowEditMessageDialog(index, currentMessage)
	local dialog = CreateFrame("Frame", "GratwurstEditDialog", UIParent, "BackdropTemplate")
	dialog:SetSize(750, 400)
	dialog:SetPoint("CENTER")
	dialog:SetFrameStrata("DIALOG")
	dialog:SetFrameLevel(100)
	dialog:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	dialog:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
	dialog:SetMovable(true)
	dialog:EnableMouse(true)
	dialog:RegisterForDrag("LeftButton")
	dialog:SetScript("OnDragStart", dialog.StartMoving)
	dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
	
	-- Title
	local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", dialog, "TOP", 0, -15)
	title:SetText("Edit Message")
	
	-- Instructions
	local instructions = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	instructions:SetPoint("TOPLEFT", dialog, "TOPLEFT", 25, -50)
	instructions:SetText("Modify your congratulations message:")
	instructions:SetTextColor(1, 0.82, 0)
	
	-- Input box
	local inputBox = CreateFrame("EditBox", "GratwurstEditInput", dialog, "InputBoxTemplate")
	inputBox:SetSize(350, 25)
	inputBox:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -15)
	inputBox:SetText(currentMessage)
	inputBox:SetAutoFocus(true)
	inputBox:SetScript("OnEnterPressed", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			EditMessage(index, text)
			dialog:Hide()
		end
	end)
	inputBox:SetScript("OnEscapePressed", function()
		dialog:Hide()
	end)
	
	-- Preview
	local previewLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	previewLabel:SetPoint("TOPLEFT", inputBox, "BOTTOMLEFT", 0, -15)
	previewLabel:SetText("Preview:")
	previewLabel:SetTextColor(0.8, 0.8, 0.8)
	
	local previewText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	previewText:SetPoint("TOPLEFT", previewLabel, "BOTTOMLEFT", 0, -5)
	previewText:SetWidth(350)
	previewText:SetJustifyH("LEFT")
	local initialPreview = ReplaceLancabanPlaceholders(currentMessage, "JohnnyAwesome-TestRealm")
	previewText:SetText(initialPreview)
	previewText:SetTextColor(0.5, 1, 0.5)
	
	-- Update preview when typing
	inputBox:SetScript("OnTextChanged", function(self)
		local text = self:GetText()
		if text and text ~= "" then
			local preview = ReplaceLancabanPlaceholders(text, "JohnnyAwesome-TestRealm")
			previewText:SetText(preview)
		else
			previewText:SetText("Gratz JohnnyAwesome!")
		end
	end)
	
	-- Helper pane
	local helperFrame = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
	helperFrame:SetSize(300, 320)
	helperFrame:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -25, -50)
	helperFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
		tile = true,
		tileSize = 12,
		edgeSize = 8,
		insets = { left = 5, right = 3, top = 3, bottom = 3 }
	})
	
	local helperTitle = helperFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	helperTitle:SetPoint("TOP", helperFrame, "TOP", 0, -10)
	helperTitle:SetText("Available Placeholders")
	helperTitle:SetTextColor(1, 0.82, 0)
	
	local helperText = helperFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	helperText:SetPoint("TOPLEFT", helperFrame, "TOPLEFT", 15, -35)
	helperText:SetWidth(270)
	helperText:SetJustifyH("LEFT")
	helperText:SetText(
		"|cFFFFFF00Player Info:|r\n" ..
		"%c - Character Name\n" ..
		"%l - Player Level\n" ..
		"%C - Player Class\n" ..
		"%L - Levels to Cap\n\n" ..
		"|cFFFFFF00Guild Info:|r\n" ..
		"%g - Guild Alias\n" ..
		"%G - Guild Name\n" ..
		"%r - Guild Rank\n\n" ..
		"|cFFFFFF00Achievement:|r\n" ..
		"%v - Achievement Name\n" ..
		"#n - Achiever Name\n" ..
		"#g - Guild Name\n\n" ..
		"|cFFFFFF00PvP Info:|r\n" ..
		"#f - Your Faction\n" ..
		"#e - Enemy Faction\n" ..
		"#b - Battleground\n\n" ..
		"|cFFFFFF00Legacy:|r\n" ..
		"$player - Player Name"
	)
	
	-- Buttons
	local saveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	saveButton:SetSize(100, 28)
	saveButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 25, 20)
	saveButton:SetText("Save Changes")
	saveButton:SetScript("OnClick", function()
		local text = inputBox:GetText()
		if text and text ~= "" then
			EditMessage(index, text)
			dialog:Hide()
		end
	end)
	
	local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
	cancelButton:SetSize(80, 28)
	cancelButton:SetPoint("BOTTOMLEFT", saveButton, "BOTTOMRIGHT", 10, 0)
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
	inputBox:SetFocus()
	inputBox:HighlightText()
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
		DEFAULT_CHAT_FRAME:AddMessage("|cffffedbaGratwurst:|r   /gw c       -> Open Configuration")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffedbaGratwurst:|r   /gw enable  -> Enable Gratwurst")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffedbaGratwurst:|r   /gw disable -> Disable Gratwurst")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffedbaGratwurst:|r   /gw debug   -> Print state and simulate a grats")
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
		print("GratwurstEnabled: " .. tostring(GratwurstEnabled))
		print("GratwurstIsGratzing: " .. tostring(GratwurstIsGratzing))
		print("GratwurstRandomDelayMax: " .. GratwurstRandomDelayMax)
		print("GratwurstDelayInSeconds: " .. GratwurstDelayInSeconds)
		print("GratwurstVariancePercentage: " .. GratwurstVariancePercentage)
		print("GratwurstShouldRandomize: " .. tostring(GratwurstShouldRandomize))
		print("GratwurstMessages count: " .. #GratwurstMessages)
		GuildAchievementMessageEventReceived(true);
	end
end

SlashCmdList["GRATWURST"] = slashcmd