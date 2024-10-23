local _, LRP = ...

function LRP:CreateSpellReminder(callback)
    local expirationTime, spellName, colorString
    local spellReminder = CreateFrame("FRAME", nil, UIParent)

    spellReminder:SetFrameStrata(LRP.anchors.TEXT:GetFrameStrata())
    spellReminder:SetFrameLevel(LRP.anchors.TEXT:GetFrameLevel())

    spellReminder.tex = spellReminder:CreateTexture(nil, "BACKGROUND")
    spellReminder.tex:SetAllPoints(spellReminder)
    spellReminder.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local spellNameText = spellReminder:CreateFontString(nil, "OVERLAY")
    local cooldownText = spellReminder:CreateFontString(nil, "OVERLAY")

    cooldownText:SetPoint("CENTER", spellReminder, "CENTER", 0, -2)

    LRP:AddBorder(spellReminder)

    function spellReminder:UpdateTextVisibility()
        spellNameText:SetShown(not LiquidRemindersSaved.settings.reminderTypes.SPELL.showIconsOnly)
    end

    function spellReminder:UpdateAlignment()
        local size = LiquidRemindersSaved.settings.reminderTypes.SPELL.size
        local alignment = LiquidRemindersSaved.settings.reminderTypes.SPELL.alignment
        local relativePoint = alignment == "LEFT" and "RIGHT" or "LEFT"
        local offsetX = math.floor(alignment == "LEFT" and size * 0.125 or -size * 0.125)

        spellNameText:ClearAllPoints()
        spellNameText:SetPoint(alignment, spellReminder, relativePoint, offsetX, 0)
    end

    function spellReminder:UpdateSize()
        local font = LiquidRemindersSaved.settings.reminderTypes.SPELL.font
        local iconSize = LiquidRemindersSaved.settings.reminderTypes.SPELL.size
        local fontSize = math.floor(iconSize * 0.5)

        spellReminder:SetSize(iconSize, iconSize)
        cooldownText:SetFont(font, fontSize, "OUTLINE")
        spellNameText:SetFont(font, fontSize, "OUTLINE")
        spellNameText:SetText(string.format("%s%s|r", colorString, spellName))
    end

    function spellReminder:Initialize(id, reminderData, simulationOffset)
        local spellInfo = LRP.GetSpellInfo(reminderData.display.spellID)
        local duration = math.min(reminderData.trigger.duration, reminderData.trigger.time - simulationOffset)

        spellName = spellInfo.name
        expirationTime = GetTime() + duration
        colorString = ConvertRGBtoColorString(reminderData.display.color)

        spellReminder.tex:SetTexture(spellInfo.iconID)
        spellReminder:Show()

        spellReminder:SetScript(
            "OnUpdate",
            function()
                local remainingTime = expirationTime - GetTime()

                if remainingTime > 0 then
                    cooldownText:SetText(string.format("%.1f", remainingTime))
                else
                    spellReminder:SetScript("OnUpdate", nil)

                    callback(nil, id, false)
                end
            end
        )

        spellReminder:UpdateSize()
        spellReminder:UpdateAlignment()
        spellReminder:UpdateTextVisibility()
    end

    function spellReminder:GetExpirationTime()
        return expirationTime
    end

    return spellReminder
end