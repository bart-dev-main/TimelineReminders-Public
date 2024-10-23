local _, LRP = ...

function LRP:CreateButton(parent, title, OnClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")

    button.OnEnter = function() end
    button.OnLeave = function() end

    button:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    button:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    button.OnClick = OnClick
    
    button:SetText(title)
    button:SetNormalFontObject(LRFont13)
    button:SetHighlightFontObject(LRFont13)
    button:SetDisabledFontObject(LRFont13)
    button:SetScript("OnClick", button.OnClick)

    local function UpdateWidth()
        C_Timer.After(0, function() button:SetSize(button:GetTextWidth() + 20, 32) end)
    end

    hooksecurefunc(button, "SetText", UpdateWidth)

    UpdateWidth()
    
    return button
end