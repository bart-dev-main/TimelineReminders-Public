local _, LRP = ...

local LS = LibStub("LibSpecialization")

local playerClass, playerGroup, playerRole, playerPosition

local initialized = false
local updateQueued = false

local eventShorthands = {
    SCS = "SPELL_CAST_START",
    SCC = "SPELL_CAST_SUCCESS",
    SAA = "SPELL_AURA_APPLIED",
    SAR = "SPELL_AURA_REMOVED"
}

-- Outputs a trigger info table
local function ParseTrigger(triggerText)
    if not triggerText then return end

    local event, spellID, count
    local minutes, seconds = triggerText:match("time:(%d-):(%d+)$")

    -- If this reminder is relative to an event, match a different pattern
    if not minutes then
        minutes, seconds, event, spellID, count = triggerText:match("time:(%d-):(%d-),(%a-):(%d-):(%d+)")
    end

    -- This typically should not happen, but if the count is omitted the above might still not match correctly
    if not minutes then
        minutes, seconds, event, spellID = triggerText:match("time:(%d-):(%d-),(%a-):(%d+)")
        count = 1
    end

    minutes = tonumber(minutes)
    seconds = tonumber(seconds)

    if not minutes then return end
    if not seconds then return end

    if event then
        spellID = tonumber(spellID)
        count = tonumber(count)
        event = eventShorthands[event]

        if not spellID then return end
        if not count then return end
        if not event then return end

        return {
            relativeTo = {
                event = event,
                value = spellID,
                count = count
            },
            time = minutes * 60 + seconds,
            duration = 8,
            hideOnUse = true
        }
    else
        return {
            time = minutes * 60 + seconds,
            duration = 8,
            hideOnUse = true
        }
    end
end

-- Returns whether the reminder is relevant for the player (boolean)
local function ParseLoad(loadText)
    if not loadText then return end

    loadText = loadText:match("||c%x%x%x%x%x%x%x%x(.-)||r") or loadText -- Remove colors (if any)

    if loadText:match("{everyone}") then
        return true
    else
        local loadType, loadTarget = loadText:match("(.-):(.+)")

        if loadType and loadTarget then
            loadTarget = loadTarget:upper()

            if loadType == "class" and loadTarget == playerClass then
                return true
            elseif loadType == "group" and tonumber(loadTarget) == playerGroup then
                return true
            elseif loadType == "role" and loadTarget == playerRole then
                return true
            elseif loadType == "type" and loadTarget == playerPosition then
                return true
            end
        else
            local playerName = UnitName("player")
            local playerNickname = LiquidAPI and LiquidAPI:GetName("player")

            if loadText == playerName or loadText == playerNickname then
                return true
            end
        end
    end

    return false
end

-- Returns a display table with color set to white (color is not supported for note reminders)
local function ParseDisplay(displayText)
    if not displayText then return end

    local text = displayText:match("{[Tt][Ee][Xx][Tt]}(.-){/[Tt][Ee][Xx][Tt]}")

    if text then -- Text reminder
        return {
            type = "TEXT",
            text = text,
            color = {
                r = 1,
                g = 1,
                b = 1
            }
        }
    else -- Spell reminder
        local spellID = tonumber(displayText:match("{spell:(%d+)}"))

        if not spellID then return end

        return {
            type = "SPELL",
            spellID = spellID,
            color = {
                r = 1,
                g = 1,
                b = 1
            }
        }
    end
end

local function ParseGlow(glowText)
    if not glowText then
        return {
            enabled = false
        }
    end

    local glowNames = {}

    for name in string.gmatch(glowText, "([^,]+)") do
        name = strtrim(name:lower():gsub("^%l", string.upper)) -- Remove space and make sure only the first letter is capitalised
        
        table.insert(glowNames, name)
    end

    if #glowNames > 0 then
        return {
            enabled = true,
            names = glowNames,
            type = "PIXEL",
            color = {
                r = 0.95,
                g = 0.95,
                b = 0.32
            }
        }
    else
        return {
            enabled = false
        }
    end
end

-- Operates on a single line of the note
-- A line is structured as follows: [trigger] - [load][display][glow]  [load][display][glow]   [load][display][glow] , etc.
-- This function feeds the respective parts into their corresponding functions
-- The output is a table of relevant reminders with each their own trigger, display, tts, and glow tables
local function ParseLine(line)
    -- The gmatch pattern below only matches the last reminder if the line has two trailing spaces
    -- This is fine if the note is output from the Viserio sheet, but often is forgotten about when made manually
    -- We just add them here (even if they were already there, it's fine)
    line = line .. "  "

    local reminders = {}
    local triggerText, reminderText = line:match("^{(.-)}.-%s%-%s(.+)")

    -- If the ability name is not included, the above match fails
    if not triggerText then
        triggerText, reminderText = line:match("^{(.-)}(.+)")
    end

    local trigger = ParseTrigger(triggerText)

    if not trigger then return reminders end

    for reminder in reminderText:gmatch("(.-)%s%s") do
        local loadText, displayText, glowText, isRelevant

        -- First test if the line is formatted like Llorgs output (no load text, just a single display text)
        displayText = strtrim(reminder):match("^{spell:%d+}$")

        if displayText then
            isRelevant = true
        else -- If it's not formatted like Llorgs, attempt to match Viserio note output
            loadText, displayText, glowText = reminder:match("(.-)%s({.+})(.*)")

            isRelevant = ParseLoad(loadText)
        end

        if isRelevant then
            if glowText then
                glowText = glowText:match("%s?@(.+)")
            end

            local display = ParseDisplay(displayText)

            if display then
                local glow = ParseGlow(glowText)

                local reminderData = {
                    trigger = trigger,
                    display = display,
                    glow = glow,
                    tts = {
                        enabled = false
                    }
                }

                table.insert(reminders, reminderData)
            end
        end
    end

    return reminders
end

function LRP:ApplyDefaultSettingsToNote()
    local defaultReminder = LiquidRemindersSaved.settings.defaultReminder

    if not defaultReminder then return end
    if not LRP.MRTReminders then return end

    for _, encounterReminders in pairs(LRP.MRTReminders) do
        for _, reminderData in pairs(encounterReminders) do
            -- Trigger
            reminderData.trigger.duration = defaultReminder.trigger.duration
            reminderData.trigger.hideOnUse = defaultReminder.trigger.hideOnUse
    
            -- Display
            reminderData.display.color = defaultReminder.display.color
    
            -- Glow
            reminderData.glow.type = defaultReminder.glow.type
            reminderData.glow.color = defaultReminder.glow.color
    
            -- TTS
            reminderData.tts = defaultReminder.tts
        end
    end
end

-- Calls ParseLine() on every line
-- Populates LRP.MRTReminders
local function ParseNote()
    local encounterID = "ALL"
    local mrtReminderArray = {} -- This gets turned into a hash table later, because we need string keys

    LRP.MRTReminders = {}
    updateQueued = false

    if not VMRT then return end
    if not VMRT.Note then return end
    if not VMRT.Note.Text1 then return end
    if type(VMRT.Note.Text1) ~= "string" then return end

    local notes = {
        VMRT.Note.Text1, VMRT.Note.SelfText
    }

    for _, note in ipairs(notes) do
        for line in note:gmatch("[^\r\n]+") do
            local newEncounterID = tonumber(line:match("^{[Ee]:(%d+)}$"))

            if newEncounterID then
                encounterID = newEncounterID
            elseif line:match("^{/[Ee]}$") then
                encounterID = "ALL"
            end

            if not mrtReminderArray[encounterID] then
                mrtReminderArray[encounterID] = {}
            end

            local reminders = ParseLine(line)
    
            tAppendAll(mrtReminderArray[encounterID], reminders)
        end
    end

    -- For comparison against reminders we set ourselves (those always have string keys)
    for encounter, reminders in pairs(mrtReminderArray) do
        LRP.MRTReminders[encounter] = {}

        for i, reminder in ipairs(reminders) do
            LRP.MRTReminders[encounter][string.format("%s-%d", tostring(encounter), i)] = reminder
        end
    end
    
    LRP:ApplyDefaultSettingsToNote()
end

function LRP:InitializeNoteInterpreter()
    if not initialized and MRTNote and MRTNote.text then
        initialized = true

        hooksecurefunc(
            MRTNote.text,
            "SetText",
            function()
                if not updateQueued then
                    updateQueued = true

                    C_Timer.After(
                        1,
                        function()
                            ParseNote()

                            LRP:BuildReminderLines()
                        end
                    )
                end
            end
        )
    end
end

-- Caches player info like class, spec, raid group, etc.
-- This is used to compare against the [load] part of reminders, to determine if they are relevant for us
local function UpdatePlayerInfo()
    playerClass = UnitClassBase("player")

    local _, role, position = LS:MySpecialization()

    if role and position then
        playerRole = role
        playerPosition = position
    end

    playerGroup = UnitInRaid("player") and GetRaidRosterInfo(UnitInRaid("player")) or 1
end

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

eventFrame:SetScript(
    "OnEvent",
    function(_, event, ...)
        if event == "LOADING_SCREEN_DISABLED" then
            UpdatePlayerInfo()
            ParseNote()

            LRP:BuildReminderLines()
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "GROUP_ROSTER_UPDATE" then
            UpdatePlayerInfo()
        end
    end
)