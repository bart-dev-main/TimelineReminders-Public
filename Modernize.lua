local _, LRP = ...

local version = 5

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

    LiquidRemindersSaved.internalVersion = version
end

