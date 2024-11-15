local _, LRP = ...

local LS = LibStub("LibSpecialization")

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

-- Outputs a load info table
local function ParseLoad(loadText)
    if not loadText then return end

    loadText = loadText:match("||c%x%x%x%x%x%x%x%x(.-)||r") or loadText -- Remove colors (if any)

    if loadText:match("{everyone}") then
        return {
            type = "ALL"
        }
    else
        local loadType, loadTarget = loadText:match("(.-):(.+)")

        if loadType and loadTarget then
            loadType = loadType:upper()
            loadTarget = loadTarget:upper()

            if loadType == "CLASS" then
                return {
                    type = "CLASS_SPEC",
                    class = loadTarget,
                    spec = loadTarget
                }
            elseif loadType == "GROUP" then
                return {
                    type = "GROUP",
                    group = tonumber(loadTarget) or 0
                }
            elseif loadType == "ROLE" then
                return {
                    type = "ROLE",
                    role = loadTarget
                }
            elseif loadType == "TYPE" then
                return {
                    type = "POSITION",
                    position = loadTarget
                }
            end
        else
            return {
                type = "NAME",
                name = loadText
            }
        end
    end
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
        local loadText, displayText, glowText, load

        -- First test if the line is formatted like Llorgs output (no load text, just a single display text)
        displayText = strtrim(reminder):match("^{spell:%d+}$")

        if displayText then
            load = {
                type = "ALL"
            }
        else -- If it's not formatted like Llorgs, attempt to match Viserio note output
            loadText, displayText, glowText = reminder:match("(.-)%s({.+})(.*)")

            load = ParseLoad(loadText)
        end

        if load then
            if glowText then
                glowText = glowText:match("%s?@(.+)")
            end

            local display = ParseDisplay(displayText)

            if display then
                local glow = ParseGlow(glowText)

                local reminderData = {
                    load = load,
                    trigger = trigger,
                    display = display,
                    glow = glow,
                    sound = {
                        enabled = false
                    },
                    countdown = {
                        enabled = false
                    },
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

    for _, reminderTypeTable in pairs(LRP.MRTReminders) do -- Personal/public
        for _, encounterTypeTable in pairs(reminderTypeTable) do -- Encounter/all
            for _, reminderData in pairs(encounterTypeTable) do
                -- Only apply is to relevant reminders
                -- Don't give the impression that reminders made for others use our default settings
                -- (they use the receiver's default settings, which we do not have access to)
                if LRP:IsRelevantReminder(reminderData) then
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

                    -- Sound
                    reminderData.sound = defaultReminder.sound

                    -- Countdown
                    reminderData.countdown = defaultReminder.countdown
                end
            end
        end
    end
end

-- Calls ParseLine() on every line
-- Populates LRP.MRTReminders
local function ParseNote()
    local encounterID = "ALL"

    LRP.MRTReminders = {personal = {}, public = {}}
    updateQueued = false

    if not VMRT then return end
    if not VMRT.Note then return end

    local notes = {
        personal = VMRT.Note.SelfText,
        public = VMRT.Note.Text1
    }

    for noteType, note in pairs(notes) do
        local reminderArray = {}

        for line in note:gmatch("[^\r\n]+") do
            local newEncounterID = tonumber(line:match("^{[Ee]:(%d+)}$"))

            if newEncounterID then
                encounterID = newEncounterID
            elseif line:match("^{/[Ee]}$") then
                encounterID = "ALL"
            end

            local reminders = ParseLine(line)

            if next(reminders) then
                if not reminderArray[encounterID] then
                    reminderArray[encounterID] = {}
                end

                tAppendAll(reminderArray[encounterID], reminders)
            end
        end

        -- For comparison against reminders we set ourselves (those always have string keys)
        for encounter, reminders in pairs(reminderArray) do
            LRP.MRTReminders[noteType][encounter] = {}

            for i, reminder in ipairs(reminders) do
                LRP.MRTReminders[noteType][encounter][string.format("%s-%d", tostring(encounter), i)] = reminder
            end
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

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
eventFrame:SetScript(
    "OnEvent",
    function(_, event)
        if event == "LOADING_SCREEN_DISABLED" then
            ParseNote()

            LRP:BuildReminderLines()
        end
    end
)
