local _, LRP = ...

function LRP:CreateEditBox(parent, title, OnValueChanged)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")

    local OnTextSet

    editBox.OnEnter = function() end
    editBox.OnLeave = function() end

    editBox:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    editBox:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    editBox:SetAutoFocus(false)
    editBox:SetHeight(18)
    editBox:SetTextInsets(4, 4, 1, 0)
    editBox:SetFontObject(LRFont15)

    local minValue, maxValue
    editBox.currentValue = ""

    function editBox:SetMinimum(value)
        minValue = value
    end

    function editBox:SetMaximum(value)
        maxValue = value
    end

    local function ClampValue(value)
        if not (editBox:IsNumeric() or editBox:IsNumericFullRange()) then return value end

        local numericValue = tonumber(value)

        if not numericValue then return value end

        if minValue then
            numericValue = math.max(numericValue, minValue)
        end

        if maxValue then
            numericValue = math.min(numericValue, minValue)
        end

        return tostring(numericValue)
    end

    -- Background
    editBox.tex = editBox:CreateTexture(nil, "BACKGROUND")
    editBox.tex:SetPoint("TOPLEFT", editBox, "TOPLEFT", 1, -1)
    editBox.tex:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT", -1, 1)
    editBox.tex:SetColorTexture(0, 0, 0, 0.5)

    function editBox:SetBackgroundColor(r, g, b, a)
        editBox.tex:SetColorTexture(r, g, b, a)
    end

    editBox.Left:Hide()
    editBox.Middle:Hide()
    editBox.Right:Hide()

    -- Hover highlight
    editBox.hoverHighlight = editBox:CreateTexture(nil, "HIGHLIGHT")
    editBox.hoverHighlight:SetAllPoints()
    editBox.hoverHighlight:SetAtlas("GarrMission_FollowerListButton-Highlight")

    -- Border
    local borderColor = LRP.gs.visual.borderColor

    LRP:AddBorder(editBox)
    editBox:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Title
    editBox.title = editBox:CreateFontString(nil, "OVERLAY")
    editBox.title:SetFontObject(LRFont13)
    editBox.title:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT")
    editBox.title:SetText(string.format("|cFFFFCC00%s|r", title))

    -- OK button
    editBox.button = LRP:CreateButton(
        editBox,
        "OK",
        function()
            OnTextSet()
        end
    )

    editBox.button:SetPoint("TOPRIGHT", editBox, "TOPRIGHT", 2, 1)
    editBox.button:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT", 2, -1)
    editBox.button:GetFontString():SetFontObject(LRFont11)
    editBox.button:GetFontString():AdjustPointsOffset(0, -1)
    editBox.button:Hide()

    local function UpdateButtonVisibility()
        local text = editBox:GetText()

        editBox.button:SetShown(text ~= editBox.currentValue)
    end

    -- Calls OnValueChanged with the currentValue
    -- Mostly used for updating the highlight when it has a dependency on outside information
    function editBox:Refresh()
        OnValueChanged(editBox.currentValue)
    end

    -- Highlight border
    local highLightWidth = 1

    local highlight = {
        top = CreateFrame("Frame", nil, editBox),
        bottom = CreateFrame("Frame", nil, editBox),
        left = CreateFrame("Frame", nil, editBox),
        right = CreateFrame("Frame", nil, editBox),
    }

    for _, frame in pairs(highlight) do
        frame.tex = frame:CreateTexture(nil, "BORDER")
        frame.tex:SetAllPoints(frame)
        frame.tex:SetColorTexture(1, 0, 0)
    end

    highlight.top:SetHeight(highLightWidth)
    highlight.top:SetPoint("TOPLEFT")
    highlight.top:SetPoint("TOPRIGHT")

    highlight.bottom:SetHeight(highLightWidth)
    highlight.bottom:SetPoint("BOTTOMLEFT")
    highlight.bottom:SetPoint("BOTTOMRIGHT")

    highlight.left:SetWidth(highLightWidth)
    highlight.left:SetPoint("TOPLEFT")
    highlight.left:SetPoint("BOTTOMLEFT")

    highlight.right:SetWidth(highLightWidth)
    highlight.right:SetPoint("TOPRIGHT")
    highlight.right:SetPoint("BOTTOMRIGHT")

    function editBox:ShowHighlight(r, g, b)
        for _, frame in pairs(highlight) do
            frame:Show()

            if r and g and b then
                frame.tex:SetColorTexture(r, g, b)
            end
        end
    end

    function editBox:HideHighlight()
        for _, frame in pairs(highlight) do
            frame:Hide()
        end
    end

    function editBox:SetHighlightShown(shown, r, g, b)
        if shown then
            editBox:ShowHighlight(r, g, b)
        else
            editBox:HideHighlight()
        end
    end

    OnTextSet = function()
        local text = editBox:GetText()

        text = ClampValue(text) -- Clamp value if this edit box is (FullRange)Numeric and either minValue or maxValue are set

        editBox:SetText(text)

        editBox.currentValue = text

        OnValueChanged(text)
        UpdateButtonVisibility()
        editBox:ClearFocus()
    end

    editBox:SetScript(
        "OnEnterPressed",
        function()
            OnTextSet()
        end
    )

    editBox:SetScript(
        "OnTextSet",
        function()
            OnTextSet()
        end
    )

    editBox:SetScript(
        "OnEscapePressed",
        function()
            editBox:SetText(editBox.currentValue or "")

            editBox:ClearFocus()
            UpdateButtonVisibility()
        end
    )

    editBox:SetScript(
        "OnTextChanged",
        UpdateButtonVisibility
    )

    editBox:HideHighlight()

    C_Timer.After(0, function() OnValueChanged(editBox.currentValue) end)

    return editBox
end