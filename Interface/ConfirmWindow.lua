local _, LRP = ...

local showing = false
local windowWidth = 240
local originalAlpha -- Original alpha of the parent window
local spacing = 16
local window

local function UpdateWindowSize()
    C_Timer.After(
        0,
        function()
            window:SetHeight(window.text:GetHeight() + 2 * spacing + 32 + 10)
        end
    )
end

local function HideConfirmWindow()
    local parent = window:GetParent()

    parent:SetAlpha(originalAlpha)

    window:Hide()

    showing = false
end

function LRP:ShowConfirmWindow(parent, newText, onConfirm)
    if showing then
        HideConfirmWindow()
    end

    window:Show()
    window:SetParent(parent)
    window:SetPoint("CENTER", parent, "CENTER")
    window:SetFrameLevel(parent:GetFrameLevel() + 10)

    originalAlpha = parent:GetAlpha()
    parent:SetAlpha(0.5)

    window.text:SetText(newText)
    window.confirmButton:SetScript(
        "OnClick",
        function()
            onConfirm()

            HideConfirmWindow()
        end
    )

    UpdateWindowSize()
    
    showing = true
end

function LRP:InitializeConfirmWindow()
    window = LRP:CreateWindow(nil)
    window:SetWidth(windowWidth)
    window:SetIgnoreParentAlpha(true)
    window:SetFrameStrata("DIALOG")

    window.confirmButton = LRP:CreateButton(window, "|cff00ff00Confirm|r", function() end)
    window.confirmButton:SetPoint("BOTTOMRIGHT", window, "BOTTOM", -4, 10)

    window.cancelButton = LRP:CreateButton(window, "|cffff0000Cancel|r", HideConfirmWindow)
    window.cancelButton:SetPoint("BOTTOMLEFT", window, "BOTTOM", 4, 10)

    window.text = window:CreateFontString(nil, "OVERLAY")
    window.text:SetFontObject(LRFont16)
    window.text:SetPoint("TOP", window, "TOP", 0, -spacing)
    window.text:SetWordWrap(true)
    window.text:SetWidth(windowWidth - 2 * spacing)

    window.textWrapper = CreateFrame("Frame")
    window.textWrapper:SetAllPoints(window.text)
    window.textWrapper:SetScript("OnSizeChanged", UpdateWindowSize)
end

-- When the user clicks outside the confirm window, hide it
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
eventFrame:SetScript(
    "OnEvent",
    function()
        if showing and not window:IsMouseOver() then
            HideConfirmWindow()
        end
    end
)