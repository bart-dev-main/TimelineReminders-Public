local _, LRP = ...

local version = 10

function LRP:Modernize()
    local internalVersion = LiquidRemindersSaved.internalVersion or 0

    -- Only mythic used to be supported, and all the reminders were in a single table
    -- Now that two difficulties per game version are supported (heroic/mythic for retail, normal/heroic for classic), split them up
    if internalVersion < 4 then
        for encounterID, encounterReminders in pairs(LiquidRemindersSaved.reminders) do
            if not (encounterReminders[1] or encounterReminders[2]) then
                local copyReminders = CopyTable(encounterReminders)

                LiquidRemindersSaved.reminders[encounterID] = {
                    [1] = {}, -- Heroic
                    [2] = copyReminders
                }
            end
        end
    end

    if internalVersion < 5 then
        local classNames = {
            DEATHKNIGHT = true,
            DEMONHUNTER = true,
            DRUID = true,
            EVOKER = true,
            HUNTER = true,
            MAGE = true,
            MONK = true,
            PALADIN = true,
            PRIEST = true,
            ROGUE = true,
            SHAMAN = true,
            WARLOCK = true,
            WARRIOR = true
        }

        if not LiquidRemindersSaved.spellBookData[10] then -- TWW
            LiquidRemindersSaved.spellBookData[10] = {}
        end

        for class in pairs(classNames) do
            if LiquidRemindersSaved.spellBookData[class] then
                LiquidRemindersSaved.spellBookData[10][class] = CopyTable(LiquidRemindersSaved.spellBookData[class])

                LiquidRemindersSaved.spellBookData[class] = nil
            end
        end
    end

    -- Some users were reporting Lua errors due to encounter reminder tables not having difficulty subtables
    -- This should have been taken care of in version 4, but somehow maybe have failed
    if internalVersion < 6 then
        for _, encounterReminders in pairs(LiquidRemindersSaved.reminders) do
            if not encounterReminders[1] then
                encounterReminders[1] = {}
            end

            if not encounterReminders[2] then
                encounterReminders[2] = {}
            end
        end
    end

    -- spellID field in timeline changed to value
    if internalVersion < 7 then
        for _, difficultyReminders in pairs(LiquidRemindersSaved.reminders) do
            for _, encounterReminders in pairs(difficultyReminders) do
                for _, reminderData in pairs(encounterReminders) do
                    if reminderData.trigger.relativeTo and reminderData.trigger.relativeTo.spellID then
                        reminderData.trigger.relativeTo.value = reminderData.trigger.relativeTo.spellID

                        reminderData.trigger.relativeTo.spellID = nil
                    end
                end
            end
        end
    end

    -- Sounds got introduced to reminders
    if internalVersion < 8 then
        for _, difficultyReminders in pairs(LiquidRemindersSaved.reminders) do
            for _, encounterReminders in pairs(difficultyReminders) do
                for _, reminderData in pairs(encounterReminders) do
                    if not reminderData.sound then
                        reminderData.sound = {
                            enabled = false,
                            time = 0,
                            file = "Interface\\Addons\\TimelineReminders\\Media\\Sounds\\TR_Beep.mp3"
                        }
                    end
                end
            end
        end
    end

    if internalVersion < 9 then
        if LiquidRemindersSaved.settings.defaultReminder and not LiquidRemindersSaved.settings.defaultReminder.sound then
            LiquidRemindersSaved.settings.defaultReminder.sound = {
                enabled = false,
                time = 0,
                file = "Interface\\Addons\\TimelineReminders\\Media\\Sounds\\TR_Beep.mp3"
            }
        end
    end

    -- Countdown got introduced to reminders
    if internalVersion < 10 then
        for _, difficultyReminders in pairs(LiquidRemindersSaved.reminders) do
            for _, encounterReminders in pairs(difficultyReminders) do
                for _, reminderData in pairs(encounterReminders) do
                    if not reminderData.countdown then
                        reminderData.countdown = {
                            enabled = false,
                            start = 3,
                            voice = "Sara"
                        }
                    end
                end
            end
        end

        if LiquidRemindersSaved.settings.defaultReminder and not LiquidRemindersSaved.settings.defaultReminder.countdown then
            LiquidRemindersSaved.settings.defaultReminder.countdown = {
                enabled = false,
                start = 3,
                voice = "Sara"
            }
        end
    end

    -- Public/personal MRT note toggle now shows/hides them in-fight as well (rather than just on the timeline)
    if internalVersion < 11 then
        if LiquidRemindersSaved.settings.timeline.showNoteReminders ~= nil then
            LiquidRemindersSaved.settings.timeline.personalNoteReminders = true
            LiquidRemindersSaved.settings.timeline.publicNoteReminders = true

            LiquidRemindersSaved.settings.timeline.showNoteReminders = nil
        end

        
    end

    LiquidRemindersSaved.internalVersion = version
end

