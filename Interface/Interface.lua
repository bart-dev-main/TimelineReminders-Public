local _, LRP = ...

-- Tooltip
CreateFrame("GameTooltip", "LRTooltip", UIParent, "GameTooltipTemplate")

LRP.Tooltip = _G["LRTooltip"]
LRP.Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

LRP.Tooltip:AddFontStrings(
	LRP.Tooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"),
	LRP.Tooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
)

if LRP.isRetail then
    LRP.Tooltip.TextLeft1:SetFontObject(LRFont13)
    LRP.Tooltip.TextRight1:SetFontObject(LRFont13)
end

-- Main window
local windowDefaultWidth = 1200
local windowMinWidth = 800

function LRP:InitializeInterface()
    LRP.window = LRP:CreateWindow("Main", true, true, true)
    LRP.window:SetFrameStrata("HIGH")
    LRP.window:SetResizeBounds(windowMinWidth, 0) -- Height is set based on timeine data
    LRP.window:SetPoint("CENTER")
    LRP.window:Hide()

    LRP.window:SetScript("OnHide", function() LRP:StopSimulation() end)

    -- If there's no saved position/size settings for the main window yet, apply some default values
    local windowSettings = LiquidRemindersSaved.settings.frames["Main"]
    local windowWidth = windowSettings and windowSettings.width

    -- If this is the first time the addon loads, and the user has never resized the window yet, apply some default width
    if not windowWidth then
        windowWidth = windowDefaultWidth

        LRP.window:SetWidth(windowWidth)
    end
    
    -- Settings button
    LRP.window:AddButton(
        "Interface\\Addons\\TimelineReminders\\Media\\Textures\\Cogwheel.tga",
        function()
            LRP.anchors.TEXT:SetShown(not LRP.anchors.TEXT:IsShown())
            LRP.anchors.SPELL:SetShown(not LRP.anchors.SPELL:IsShown())
        end
    )

    -- Timeline
    LRP:InitializeTimeline()
    
    local timeline = LRP.timeline

    timeline:SetParent(LRP.window)
    timeline:SetPoint("LEFT", LRP.window, "LEFT", 16, 0)
    timeline:SetPoint("RIGHT", LRP.window, "RIGHT", -16, 0)

    -- Reminder config
    LRP:InitializeConfig()

    LRP.reminderConfig:SetParent(LRP.window)
    LRP.reminderConfig:SetFrameStrata("DIALOG")
    LRP.reminderConfig:Hide()
end