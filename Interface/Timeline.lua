local _, LRP = ...

-- Frame levels relative to view
local frameLevels = {
    intervalLine = 1,
    trackHighlight = 2,
    trackEntry = 3,
    phaseLine = 4,
    deathLine = 5,
    reminderLine = 6,
    reminderLineIcon = 7,
    cursorLine = 8,
    cursorTime = 9,
    simulateLine = 10
}

local selectedInstanceType, selectedInstance, selectedEncounter, selectedDifficulty, selectedEncounterID

local timelineData -- The data (boss fight events/phase transitions) currently displayed on the timeline
local reminderData -- The reminders that should be shown for the currently displayed timeline

local mouseoverTime -- Time (in seconds) on the timeline at the cursor location

local spacing = 2 -- Spacing between UI elements

local viewWidth = 0 -- Width of the visible timeline
local viewTime -- Time on the leftmost side of the visible timeline

local timelineDensity = 0.15 -- Number of seconds that one pixel spans. If set to 1, 100 pixels equal 100 seconds.
local timelineWidth -- Width of the timeline. This is just timelineSpan / timelineDensity.
local trackHeight = 24 -- Height of a timeline track. Total height of the timeline is determined by this * number of tracks.
local timelineSpan -- Total time in seconds that the timeline spans (determined from timeline data)

local dragging = false -- Whether the user is dragging the timeline
local dragStartTime, dragStartX -- viewTime/mouse X position when the user started dragging the timeline

local deathLine
local trackLabelPool = {}
local trackEntryPool = {}
local intervalLinePool = {}
local phaseLinePool = {}
local trackHighlightPool = {}

-- Reminder lines are split into two tables based on if they are active or not (rather than a single pool)
-- This is done because we want to be able to conveniently loop over only the active ones while adjusting their visibility
local reminderLineWidth = 2
local reminderLineMargin = 16
local reminderLineIconSize = 24
local activeReminderLines = {}
local inactiveReminderLines = {} -- When a new reminder line is made, first check if one is available here
local inactiveReminderLinesMRT = {} -- Same as the above, but specifically for MRT note reminders

-- UI elements
local dropdownMinWidth = 160 -- Label container is sized according to this
local labelContainer, view, viewMask, timeline, dropdown, relevantRemindersCheckButton, showNoteRemindersCheckButton, showDeathLineCheckButton, unknownEventsLabel, exceedsTimeLabel, simulateButton, simulateLine, warningIcon

-- Functions
local BuildTimeline

local function UpdateLeftRightTime()
    view.leftTime.text:SetText(SecondsToClock(viewTime))
    view.rightTime.text:SetText(SecondsToClock(viewTime + (viewWidth / timelineWidth) * timelineSpan))
end

-- Called when view is moved or timeline density changes
-- Reminder lines that reference unknown events or exceed the maximum time, are always visible
local function UpdateReminderLineVisibility()
    for _, reminderLine in pairs(activeReminderLines) do
        if reminderLine.unknownEvent or reminderLine.exceedsTime then
            reminderLine:Hide()
            reminderLine.icon:Show()
            reminderLine.icon.tex:RemoveMaskTexture(viewMask)

            for _, tex in pairs(reminderLine.icon.border) do
                tex:RemoveMaskTexture(viewMask)
            end
        else
            local time = reminderLine.time

            -- First set visibility based on whether the reminder line falls within the current view
            local visible = time > viewTime and time < viewTime + viewWidth * timelineDensity

            reminderLine:SetShown(visible)
            reminderLine.icon:SetShown(visible)
            reminderLine.icon.tex:AddMaskTexture(viewMask)

            for _, tex in pairs(reminderLine.icon.border) do
                tex:AddMaskTexture(viewMask)
            end
        end
    end
end

-- Called after new reminder lines are added, and when timeline density changes
-- If reminder line icons don't fit next to each other, stacks them
-- If a reminder is relative to an event that is not on in timeline data, it is placed under the "unknown event" section
-- If a reminder's time exceeds the maximum time on the timeline, it is placed under the "exceeds maximum time" section
local function PositionReminderLines()
    table.sort(
        activeReminderLines,
        function(lineA, lineB)
            if lineA.unknownEvent ~= lineB.unknownEvent then
                return lineB.unknownEvent
            elseif lineA.exceedsTime ~= lineB.exceedsTime then
                return lineB.exceedsTime
            elseif lineA.time ~= lineB.time then
                return lineA.time < lineB.time
            else
                return tostring(lineA.id) < tostring(lineB.id)
            end
        end
    )

    for _, reminderLine in ipairs(activeReminderLines) do
        reminderLine:ClearAllPoints()
        reminderLine.icon:ClearAllPoints()
    end

    -- Position reminders on the timeline (i.e. not those with unknown events, or those that exceed the timeline span)
    local lanesMax = {} -- Farthest right pixel occupied per lane
    
    for _, reminderLine in ipairs(activeReminderLines) do
        if reminderLine.unknownEvent or reminderLine.exceedsTime then
            break -- These are sorted to the back, so as soon as we see one there are no more lines to be placed this way
        end

        local pixelOffset = math.floor((reminderLine.time / timelineDensity) - 0.5)
        local iconMin = pixelOffset - (reminderLineIconSize / 2)
        local iconMax = pixelOffset + (reminderLineIconSize / 2) + 1
        local lane = 1

        -- Find the lowest lane that this reminder icon fits into
        for i, laneMax in ipairs(lanesMax) do
            if laneMax < iconMin then
                break
            else
                lane = i + 1
            end
        end

        lanesMax[lane] = iconMax

        reminderLine.icon:SetPoint("TOP", reminderLine, "BOTTOM") -- When reminderLine is displayed on the timeline, icon is attached to the line

        reminderLine:SetPoint("TOPLEFT", timeline, "TOPLEFT", pixelOffset, 0)
        reminderLine:SetPoint("BOTTOMLEFT", timeline, "BOTTOMLEFT", pixelOffset, -reminderLineMargin - (lane - 1) * (reminderLineIconSize + spacing))
    end

    viewMask:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, -reminderLineMargin - #lanesMax * reminderLineIconSize - (#lanesMax - 1) * spacing)

    -- Position reminders that exceed the timeline span (and as such cannot be placed on the timeline itself)
    local exceedsTimelineCount = 0

    for _, reminderLine in ipairs(activeReminderLines) do
        if reminderLine.exceedsTime then
            reminderLine.icon:SetPoint("TOPLEFT", exceedsTimeLabel, "BOTTOMLEFT", exceedsTimelineCount * (spacing + reminderLineIconSize), -spacing)

            exceedsTimelineCount = exceedsTimelineCount + 1
        end
    end

    exceedsTimeLabel:SetShown(exceedsTimelineCount > 0)

    -- Position reminders that reference events that are not in timeline data (and as such cannot be placed on the timeline itself)
    local unknownEventCount = 0

    for _, reminderLine in ipairs(activeReminderLines) do
        if reminderLine.unknownEvent then
            reminderLine.icon:SetPoint("TOPLEFT", unknownEventsLabel, "BOTTOMLEFT", unknownEventCount * (spacing + reminderLineIconSize), -spacing)

            unknownEventCount = unknownEventCount + 1
        end
    end

    unknownEventsLabel:SetShown(unknownEventCount > 0)

    -- This label is placed differently depending on whether the exceeds timeline span label is showing
    -- We use reminderLineIconSize as a somewhat arbitrary spacing between the two labels
    if exceedsTimelineCount == 0 then
        unknownEventsLabel:SetPoint("TOPLEFT", LRP.window.moverFrame, "BOTTOMLEFT", 2 * spacing, -2 * spacing)
    else
        -- If the exceedsTimeLabel is showing, position the unknownEventsLabel based on whether the row of icons below exceedsTimeLabel is larger than the label itself
        local xOffset = math.max(exceedsTimeLabel:GetStringWidth(), exceedsTimelineCount * (spacing + reminderLineIconSize))

        unknownEventsLabel:SetPoint("TOPLEFT", LRP.window.moverFrame, "BOTTOMLEFT", 2 * spacing + reminderLineIconSize + xOffset, -2 * spacing)
    end
end

local function BuildTrackLabels()
    for _, trackLabel in pairs(trackLabelPool) do
        trackLabel.icon:Hide()
        trackLabel.title:Hide()
    end

    local trackVisibility = LiquidRemindersSaved.settings.timeline.trackVisibility[selectedEncounterID]
    local visibleLabelCount = 0

    -- Order the events first by visibility, then by order of appearance in timeline data
    local visibleEvents = {}
    local invisibleEvents = {}

    for _, eventData in ipairs(timelineData.events) do
        if eventData.show then
            if trackVisibility[eventData.value] then
                table.insert(visibleEvents, eventData)
            else
                table.insert(invisibleEvents, eventData)
            end
        end
    end

    tAppendAll(visibleEvents, invisibleEvents)

    for i, eventData in ipairs(visibleEvents) do
        if eventData.show then
            visibleLabelCount = visibleLabelCount + 1
            
            local spellInfo = LRP.GetSpellInfo(eventData.value)
            local isTrackVisible = trackVisibility[eventData.value]

            -- Icon
            local trackIcon = trackLabelPool[visibleLabelCount] and trackLabelPool[visibleLabelCount].icon or LRP:CreateSpellIcon(view)

            trackIcon:SetSpellID(eventData.value)
            trackIcon:Show()
            trackIcon:SetSize(trackHeight, trackHeight)
            trackIcon:SetPoint("TOPRIGHT", view, "TOPLEFT", -spacing, (visibleLabelCount - 1) * (-trackHeight - spacing))

            trackIcon.tex:SetDesaturated(not isTrackVisible)

            -- Text
            local trackTitle = trackLabelPool[visibleLabelCount] and trackLabelPool[visibleLabelCount].title or CreateFrame("Frame", nil, view)

            trackTitle:Show()
            trackTitle:SetSize(100, trackHeight)
            trackTitle:SetPoint("TOPRIGHT", trackIcon, "TOPLEFT", -spacing, 0)

            trackTitle.tex = trackTitle.tex or trackTitle:CreateTexture(nil, "BACKGROUND")
            trackTitle.tex:SetAllPoints(trackTitle)
            trackTitle.tex:SetColorTexture(0, 0, 0, 0.5)

            trackTitle.text = trackTitle.text or trackTitle:CreateFontString(nil, "OVERLAY")
            trackTitle.text:SetFontObject(LRFont16)
            trackTitle.text:SetPoint("RIGHT", trackTitle, "RIGHT", -6, 0)
            trackTitle.text:SetText(string.format("|c%s%s|r", isTrackVisible and "ffffffff" or "FF858585", spellInfo.name))
            trackTitle.text:GetWidth()

            -- Toggle
            trackTitle.spellID = eventData.value

            local trackToggle = trackLabelPool[visibleLabelCount] and trackLabelPool[visibleLabelCount].toggle

            if not trackToggle then
                trackToggle = LRP:CreateCheckButton(
                    trackTitle,
                    "",
                    function() end
                )
            end

            trackToggle.OnValueChanged = function(checked)
                trackVisibility[trackTitle.spellID] = checked

                BuildTimeline(viewTime)
            end
                
            trackToggle:SetChecked(isTrackVisible, true)
            trackToggle:SetPoint("LEFT", trackTitle, "LEFT", 3, 0)
            trackToggle:SetBackgroundColor(0, 0, 0, 0) -- The track label background is already 0.5 opacity black. Don't double up.

            -- Track highlight
            if isTrackVisible then
                trackTitle:SetScript("OnEnter", function() trackHighlightPool[i]:Show() end)
                trackTitle:SetScript("OnLeave", function() trackHighlightPool[i]:Hide() end)

                trackIcon.OnEnter = function() trackHighlightPool[i]:Show() end
                trackIcon.OnLeave = function() trackHighlightPool[i]:Hide() end
            else
                trackTitle:SetScript("OnEnter", nil)
                trackTitle:SetScript("OnLeave", nil)

                trackIcon.OnEnter = function() end
                trackIcon.OnLeave = function() end
            end

            trackLabelPool[visibleLabelCount] = {
                icon = trackIcon,
                title = trackTitle,
                toggle = trackToggle
            }
        end
    end

    -- Fontstring width is not immediately available, so resize the labels on next frame
    C_Timer.After(0,
        function()
            local padding = 16

            -- This ensures we allow at least enough space for the minimum dropdown width
            -- The trackHeight is included because that is the width of the icon
            -- If track labels exceed this width, this value will be overwritten
            local additionalWidth = padding + spacing + 26 -- 26 is the checkbox width (20) + the 3 pixels of padding on each side
            local labelWidth = dropdownMinWidth - additionalWidth

            for _, trackLabel in ipairs(trackLabelPool) do
                labelWidth = math.max(labelWidth, trackLabel.title.text:GetWidth())
            end

            for _, trackLabel in ipairs(trackLabelPool) do
                trackLabel.title:SetSize(labelWidth + additionalWidth, trackHeight)
            end

            labelContainer:SetWidth(labelWidth + additionalWidth + trackHeight + spacing)
        end
    )
end

local function BuildTrackEntries()
    local timelineUnit = timelineWidth / timelineSpan -- Number of pixels per second

    for _, trackEntry in pairs(trackEntryPool) do
        trackEntry:Hide()
    end

    local poolIndex = 0
    local visibleTracks = 0
    local trackVisibility = LiquidRemindersSaved.settings.timeline.trackVisibility[selectedEncounterID]

    for _, eventData in ipairs(timelineData.events) do
        if eventData.show and trackVisibility[eventData.value] then
            visibleTracks = visibleTracks + 1

            local color = eventData.color

            for _, entry in ipairs(eventData.entries) do
                poolIndex = poolIndex + 1

                local startTime = entry[1] -- Number of seconds into the fight that this event occurs
                local duration = entry[2] -- Number of seconds this event lasts for

                local start = startTime * timelineUnit -- Number of pixels from start of the timeline that this entry should show
                local width = math.min(duration * timelineUnit, timelineWidth - start) -- Width of the entry in pixels

                local trackEntry = trackEntryPool[poolIndex] or CreateFrame("Frame", nil, timeline)

                trackEntry:Show()
                trackEntry:SetSize(width, trackHeight)
                trackEntry:SetFrameLevel(view:GetFrameLevel() + frameLevels.trackEntry)
                trackEntry:SetPoint("TOPLEFT", timeline, "TOPLEFT", start, (visibleTracks - 1) * (-trackHeight - spacing))

                trackEntry.tex = trackEntry.tex or trackEntry:CreateTexture(nil, "BACKGROUND")
                trackEntry.tex:SetAllPoints(trackEntry)
                trackEntry.tex:SetColorTexture(color[1], color[2], color[3], 1)
                trackEntry.tex:AddMaskTexture(viewMask)

                trackEntryPool[poolIndex] = trackEntry
            end
        end
    end
end

local function BuildIntervalLines()
    for _, intervalLine in pairs(intervalLinePool) do
        intervalLine:Hide()
    end

    for i = 10, timelineSpan, 10 do
        local poolIndex = i / 10
        local offset = timelineWidth * i / timelineSpan

        local intervalLine = intervalLinePool[poolIndex] or CreateFrame("Frame", nil, timeline)
        intervalLine:Show()
        intervalLine:SetWidth(1)
        intervalLine:SetFrameLevel(view:GetFrameLevel() + frameLevels.intervalLine)
        intervalLine:SetPoint("TOPLEFT", timeline, "TOPLEFT", offset, 0)
        intervalLine:SetPoint("BOTTOMLEFT", timeline, "BOTTOMLEFT", offset, 0)

        intervalLine.tex = intervalLine.tex or intervalLine:CreateTexture(nil, "BACKGROUND")
        intervalLine.tex:SetAllPoints(intervalLine)
        intervalLine.tex:SetColorTexture(0.3, 0.3, 0.3)
        intervalLine.tex:AddMaskTexture(viewMask)

        intervalLinePool[poolIndex] = intervalLine
    end
end

local function BuildPhaseLines()
    for _, phaseLine in pairs(phaseLinePool) do
        phaseLine:Hide()
    end

    if timelineData.phases then
        for i, phaseInfo in ipairs(timelineData.phases) do
            local phase = i + 1 -- Phase 1 is not included in the table

            local phaseTime = phaseInfo.time
            local phaseShortName = phaseInfo.shortName or string.format("P%d", phase)
            local offset = timelineWidth * phaseTime / timelineSpan

            local phaseLine = phaseLinePool[i] or CreateFrame("Frame", nil, timeline)

            phaseLine:Show()
            phaseLine:SetWidth(2)
            phaseLine:SetFrameLevel(view:GetFrameLevel() + frameLevels.phaseLine)
            phaseLine:SetPoint("TOPLEFT", timeline, "TOPLEFT", offset, 0)
            phaseLine:SetPoint("BOTTOMLEFT", timeline, "BOTTOMLEFT", offset, 0)

            phaseLine.tex = phaseLine.tex or phaseLine:CreateTexture(nil, "BACKGROUND")
            phaseLine.tex:SetAllPoints(phaseLine)
            phaseLine.tex:SetColorTexture(0.6, 0.6, 0.6)
            phaseLine.tex:AddMaskTexture(viewMask)

            phaseLine.label = phaseLine.label or phaseLine:CreateFontString(nil, "OVERLAY")
            phaseLine.label:SetFontObject(LRFont16)
            phaseLine.label:SetPoint("BOTTOM", phaseLine, "TOP", 0, spacing)
            phaseLine.label:SetText(phaseShortName)

            LRP:AddTooltip(phaseLine.label, phaseInfo.name or string.format("Phase %d", phase))

            phaseLinePool[i] = phaseLine
        end
    end
end

local function UpdatePhaseLabelVisibility()
    local minLeft = (view.leftTime:GetRight() or 0) + spacing
    local maxRight = (view.rightTime:GetLeft() or 0) - spacing

    for phase in ipairs(timelineData.phases) do
        local phaseLine = phaseLinePool[phase]

        -- This can be nil directly after changing the displayed encounter because OnSizeChanged runs before BuildPhaseLines
        -- Simply skip updating visibility, since it will be triggered again after BuildPhaseLines runs
        if phaseLine then
            local label = phaseLine.label

            local left = (label:GetLeft() or 0)
            local right = (label:GetRight() or 0)

            label:SetShown(left > minLeft and right < maxRight)
        end
    end
end

function LRP:BuildDeathLine()
    if deathLine then deathLine:Hide() end
    if not LiquidRemindersSaved.settings.timeline.showDeathLine then return end

    local deathInfo = LiquidRemindersSaved.deathData[selectedEncounterID]

    if not deathInfo or next(deathInfo) == nil then return end

    local phase = deathInfo.phase
    local phaseInfo = timelineData.phases[phase]

    if phase > 0 and not phaseInfo then return end -- Somehow this death is relative to a phase, but that phase no longer exists in data

    local phaseTime = phaseInfo and phaseInfo.time or 0
    local offset = timelineWidth * (phaseTime + deathInfo.time) / timelineSpan

    deathLine = deathLine or CreateFrame("Frame", nil, timeline)

    deathLine:Show()
    deathLine:SetWidth(2)
    deathLine:SetFrameLevel(view:GetFrameLevel() + frameLevels.deathLine)
    deathLine:SetPoint("TOPLEFT", timeline, "TOPLEFT", offset, 0)
    deathLine:SetPoint("BOTTOMLEFT", timeline, "BOTTOMLEFT", offset, 0)

    deathLine.tex = deathLine.tex or deathLine:CreateTexture(nil, "BACKGROUND")
    deathLine.tex:SetAllPoints(deathLine)
    deathLine.tex:SetColorTexture(255/255, 5/255, 40/255)
    deathLine.tex:AddMaskTexture(viewMask)
end

local function SetViewTime(seconds)
    -- If no time is specified, set to current viewtime
    -- This is done for the edge case where the timeline is fully zoomed in, and the window is made larger
    -- Without doing this, it creates an empty space on the tail end of the timeline
    seconds = seconds or viewTime

    -- Make sure the timeline always fills the view (do not scroll too far left or right)
    seconds = math.min(timelineSpan - (viewWidth / timelineWidth) * timelineSpan, seconds)
    seconds = math.max(0, seconds)
    viewTime = seconds

    local offset = (seconds / timelineSpan) * timelineWidth

    timeline:SetPoint("LEFT", view, "LEFT", -offset, 0)

    UpdateLeftRightTime()
    UpdateReminderLineVisibility()
    UpdatePhaseLabelVisibility()
end

-- Get the (estimated) time on the timeline of the event that a reminder is relative to
-- If nothing is returned, that means the reminder is relative to an event that does not exist on this timeline
local function GetRelativeToTime(reminder)
    local relativeTo = reminder.trigger.relativeTo

    if not relativeTo then
        return 0 -- Reminder is relative to pull
    end

    local event = relativeTo.event
    local value = relativeTo.value
    local count = relativeTo.count

    for _, eventInfo in ipairs(timelineData.events) do
        if event == eventInfo.event and value == eventInfo.value then
            return eventInfo.entries[count] and eventInfo.entries[count][1]
        end
    end
end

-- Remember to call PositionReminderLines() afterwards!
local function CreateReminderLine(reminderID)
    local reminder = reminderData[reminderID]
    local reminderLine = inactiveReminderLines[#inactiveReminderLines]
    
    if reminderLine then
        inactiveReminderLines[#inactiveReminderLines] = nil
    else
        reminderLine = CreateFrame("Frame", nil, timeline)
        reminderLine:SetFrameLevel(view:GetFrameLevel() + frameLevels.reminderLine)
        reminderLine.icon = CreateFrame("Button", nil, timeline)
        reminderLine.icon:SetFrameLevel(view:GetFrameLevel() + frameLevels.reminderLineIcon) -- Icon might overlap with other reminderLines, so raise its frame level

        LRP:AddBorder(reminderLine.icon)

        reminderLine.icon:SetScript(
            "OnEnter",
            function(self)
                self.tex:SetVertexColor(1, 1, 1)
            end
        )

        reminderLine.icon:SetScript(
            "OnLeave",
            function(self)
                if self.type == "TEXT" then
                    self.tex:SetVertexColor(0.8, 0.8, 0.8)
                end
            end
        )

        LRP:AddTooltip(reminderLine.icon)
    end

    -- Determine the event that this reminder is relative to (if any)
    local relativeToTime = GetRelativeToTime(reminder)

    -- If GetRelativeToTime() did not return anything, that means this reminder is relative to an event that is not on the timeline
    -- Set unknownEvent to true, so that PositionReminderLines() knows to put the reminderIcon in the "unknown reminders" area
    if relativeToTime then
        reminderLine.unknownEvent = false
    else
        reminderLine.unknownEvent = true
    end

    -- Line
    reminderLine.time = relativeToTime and (relativeToTime + reminder.trigger.time) or 0
    reminderLine.id = reminderID
    reminderLine.icon.type = reminder.display.type

    reminderLine:SetWidth(reminderLineWidth)

    reminderLine.tex = reminderLine.tex or reminderLine:CreateTexture(nil, "BACKGROUND")
    reminderLine.tex:SetAllPoints(reminderLine)
    reminderLine.tex:SetColorTexture(1, 1, 1)
    reminderLine.tex:AddMaskTexture(viewMask)

    -- Icon
    reminderLine.icon:SetSize(reminderLineIconSize, reminderLineIconSize)

    reminderLine.icon.tex = reminderLine.icon.tex or reminderLine.icon:CreateTexture(nil, "BACKGROUND")
    reminderLine.icon.tex:SetAllPoints(reminderLine.icon)

    -- Check if the reminder exceeds the maximum time on the timeline
    -- If so, set exceedsTime to true so it is placed under the "exceeds maximum time" section
    -- This will never be set to true if the reminder references an unknown event, because the time is set to 0 in that case
    reminderLine.exceedsTime = reminderLine.time > timelineSpan

    -- Show some additional information in tooltip if the reminder references an unknown event, or exceeds the timeline span
    if reminderLine.unknownEvent then
        local relativeTo = reminder.trigger.relativeTo

        reminderLine.icon.secondaryTooltipText = string.format(
            "Event: %s|nValue: %s|nCount: %s",
            relativeTo.event,
            tostring(relativeTo.value),
            relativeTo.count
        )
    else
        reminderLine.icon.secondaryTooltipText = nil
    end

    local colorString = ConvertRGBtoColorString(reminder.display.color)

    if reminder.display.type == "TEXT" then
        local icon = "Interface\\Addons\\TimelineReminders\\Media\\Textures\\TextPage.tga"

        reminderLine.icon:ClearHighlightTexture()

        reminderLine.icon.tex:SetTexture(icon)
        reminderLine.icon.tex:SetTexCoord(0, 1, 0, 1)
        reminderLine.icon.tex:SetVertexColor(0.8, 0.8, 0.8)

        reminderLine.icon.tooltipText = string.format(
            "(%s) %s%s%s|r",
            LRP:SecondsToClock(reminderLine.time),
            reminder.tts.enabled and "|A:chatframe-button-icon-voicechat:0:0|a" or "",
            colorString,
            LRP:FormatForDisplay(reminder.display.text)
        )

        reminderLine.icon:HideBorder()
    else -- Spell reminder
        local spellInfo = reminder.display.spellID and LRP.GetSpellInfo(reminder.display.spellID)
        local name = spellInfo and spellInfo.name
        local icon = spellInfo and spellInfo.iconID

		if not name then
			name = "Invalid spell ID"
		end

		if not icon then
			icon = "Interface\\Icons\\INV_MISC_QUESTIONMARK"
		end

        reminderLine.icon:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        reminderLine.icon.tex:SetTexture(icon)
        reminderLine.icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        reminderLine.icon.tex:SetVertexColor(1, 1, 1)

        reminderLine.icon.tooltipText = string.format(
            "(%s) %s%s%s|r",
            LRP:SecondsToClock(reminderLine.time),
            reminder.tts.enabled and "|A:chatframe-button-icon-voicechat:0:0|a" or "",
            colorString,
            name
        )

        reminderLine.icon:ShowBorder()
    end

    reminderLine.icon:SetScript(
        "OnClick",
        function()
            LRP:LoadReminder(timelineData, selectedEncounterID, selectedDifficulty, reminderID)
            LRP.reminderConfig:Show()
        end
    )

    LRP:RefreshTooltip()

    table.insert(activeReminderLines, reminderLine)

    return reminderLine
end

-- Same as the above function, but specifically for MRT note reminders
-- These cannot be clicked, and have a different color
local function CreateReminderLineMRT(id, reminder)
    local reminderLine = inactiveReminderLinesMRT[#inactiveReminderLinesMRT]
    
    if reminderLine then
        inactiveReminderLinesMRT[#inactiveReminderLinesMRT] = nil
    else
        reminderLine = CreateFrame("Frame", nil, timeline)
        reminderLine:SetFrameLevel(view:GetFrameLevel() + frameLevels.reminderLine)

        reminderLine.id = id
        reminderLine.icon = CreateFrame("Button", nil, timeline)
        reminderLine.icon:SetFrameLevel(view:GetFrameLevel() + frameLevels.reminderLineIcon) -- Icon might overlap with other reminderLines, so raise its frame level

        LRP:AddBorder(reminderLine.icon)
        reminderLine.icon:SetBorderColor(0.5, 1, 1)

        reminderLine.icon:SetScript(
            "OnEnter",
            function(self)
                self.tex:SetVertexColor(1, 1, 1)
            end
        )
    
        reminderLine.icon:SetScript(
            "OnLeave",
            function(self)
                if self.type == "TEXT" then
                    self.tex:SetVertexColor(0.8, 1, 1)
                end
            end
        )

        LRP:AddTooltip(reminderLine.icon)
    end

    -- Determine the event that this reminder is relative to (if any)
    local relativeToTime = GetRelativeToTime(reminder)

    -- If GetRelativeToTime() did not return anything, that means this reminder is relative to an event that is not on the timeline
    -- Set unknownEvent to true, so that PositionReminderLines() knows to put the reminderIcon in the "unknown reminders" area
    if relativeToTime then
        reminderLine.unknownEvent = false
    else
        reminderLine.unknownEvent = true
    end

    -- Line
    reminderLine.MRT = true
    reminderLine.time = relativeToTime and (relativeToTime + reminder.trigger.time) or 0
    reminderLine.icon.type = reminder.display.type

    reminderLine:SetWidth(reminderLineWidth)

    reminderLine.tex = reminderLine.tex or reminderLine:CreateTexture(nil, "BACKGROUND")
    reminderLine.tex:SetAllPoints(reminderLine)
    reminderLine.tex:SetColorTexture(0.5, 1, 1)
    reminderLine.tex:AddMaskTexture(viewMask)

    -- Icon
    reminderLine.icon:SetSize(reminderLineIconSize, reminderLineIconSize)

    reminderLine.icon.tex = reminderLine.icon.tex or reminderLine.icon:CreateTexture(nil, "BACKGROUND")
    reminderLine.icon.tex:SetAllPoints(reminderLine.icon)

    -- Check if the reminder exceeds the maximum time on the timeline
    -- If so, set exceedsTime to true so it is placed under the "exceeds maximum time" section
    -- This will never be set to true if the reminder references an unknown event, because the time is set to 0 in that case
    reminderLine.exceedsTime = reminderLine.time > timelineSpan

    -- Show some additional information in tooltip if the reminder references an unknown event, or exceeds the timeline span
    if reminderLine.unknownEvent then
        local relativeTo = reminder.trigger.relativeTo
        
        reminderLine.icon.secondaryTooltipText = string.format(
            "Event: %s|nValue: %s|nCount: %s",
            relativeTo.event,
            tostring(relativeTo.value),
            relativeTo.count
        )
    else
        reminderLine.icon.secondaryTooltipText = nil
    end

    local colorString = ConvertRGBtoColorString(reminder.display.color)

    if reminder.display.type == "TEXT" then
        local icon = "Interface\\Addons\\TimelineReminders\\Media\\Textures\\TextPage.tga"

        reminderLine.icon:ClearHighlightTexture()

        reminderLine.icon.tex:SetTexture(icon)
        reminderLine.icon.tex:SetTexCoord(0, 1, 0, 1)
        reminderLine.icon.tex:SetVertexColor(0.8, 1, 1)

        reminderLine.icon.tooltipText = string.format(
            "(%s) %s%s%s|r",
            LRP:SecondsToClock(reminderLine.time),
            colorString,
            reminder.tts.enabled and "|A:chatframe-button-icon-voicechat:0:0|a" or "",
            LRP:FormatForDisplay(reminder.display.text)
        )

        reminderLine.icon:HideBorder()
    else -- Spell reminder
        local spellInfo = LRP.GetSpellInfo(reminder.display.spellID)
        local name = spellInfo and spellInfo.name or string.format("Unknown spell ID: %d", reminder.display.spellID)
        local icon = spellInfo and spellInfo.iconID or "Interface\\Icons\\INV_MISC_QUESTIONMARK"

        reminderLine.icon:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        reminderLine.icon.tex:SetTexture(icon)
        reminderLine.icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        reminderLine.icon.tex:SetVertexColor(1, 1, 1)
        
        reminderLine.icon.tooltipText = string.format(
            "(%s) %s%s%s|r",
            LRP:SecondsToClock(reminderLine.time),
            colorString,
            reminder.tts.enabled and "|A:chatframe-button-icon-voicechat:0:0|a" or "",
            name
        )

        reminderLine.icon:ShowBorder()
    end

    table.insert(activeReminderLines, reminderLine)

    LRP:RefreshTooltip()

    return reminderLine
end

-- Remember to call PositionReminderLines() afterwards!
local function DeleteReminderLine(index)
    local reminderLine = activeReminderLines[index]

    if reminderLine then
        reminderLine:Hide()
        reminderLine.icon:Hide()

        if reminderLine.MRT then
            table.insert(inactiveReminderLinesMRT, reminderLine)
        else
            table.insert(inactiveReminderLines, reminderLine)
        end

        table.remove(activeReminderLines, index)
    end
end

local function DeleteReminderLineByID(reminderID)
    for i, reminderLine in ipairs(activeReminderLines) do
        if reminderLine.id == reminderID then
            DeleteReminderLine(i)
        end
    end
end

function LRP:BuildReminderLines()
    for i in ipairs_reverse(activeReminderLines) do
        DeleteReminderLine(i)
    end

    -- Regular reminders
    local reminders = reminderData

    if reminders then
        local showRelevantRemindersOnly = LiquidRemindersSaved.settings.timeline.showRelevantRemindersOnly
        
        for reminderID in pairs(reminders) do
            local isRelevant = LRP:IsRelevantReminder(reminderData[reminderID])

            if not showRelevantRemindersOnly or isRelevant then
                CreateReminderLine(reminderID)
            end
        end
    end

    -- MRT note reminders
    if LiquidRemindersSaved.settings.timeline.showNoteReminders and LRP.MRTReminders then
        local combinedReminders = {LRP.MRTReminders.ALL or {}, LRP.MRTReminders[selectedEncounterID] or {}}

        for _, encounterReminders in pairs(combinedReminders) do
            for id, reminder in pairs(encounterReminders) do
                CreateReminderLineMRT(id, reminder)
            end
        end
    end

    PositionReminderLines()
	UpdateReminderLineVisibility()
end

local function BuildSimulateLine()
    if simulateLine then return end

    simulateLine = CreateFrame("Frame", nil, timeline)
    simulateLine:SetWidth(4)
    simulateLine:SetFrameLevel(view:GetFrameLevel() + frameLevels.simulateLine)

    simulateLine.tex = simulateLine:CreateTexture(nil, "BACKGROUND")
    simulateLine.tex:SetAllPoints(simulateLine)
    simulateLine.tex:SetColorTexture(0, 1, 0)
    simulateLine.tex:AddMaskTexture(viewMask)

    simulateLine:SetPoint("TOP", timeline, "TOPLEFT")
    simulateLine:SetPoint("BOTTOM", timeline, "BOTTOMLEFT")

    simulateLine:Hide()
end

function LRP:StartSimulateLine(offset)
    simulateLine.startTime = GetTime()
    simulateLine.endTime = simulateLine.startTime + timelineSpan

    simulateLine:SetScript(
        "OnUpdate",
        function()
            local duration = simulateLine.endTime - simulateLine.startTime
            local progress = GetTime() - simulateLine.startTime + offset
            local fraction = progress / duration
            local offsetX = fraction * timelineWidth

            simulateLine:SetPoint("TOP", timeline, "TOPLEFT", offsetX, 0)
            simulateLine:SetPoint("BOTTOM", timeline, "BOTTOMLEFT", offsetX, 0)
        end
    )

    simulateLine:SetFrameLevel(6)
    simulateLine:Show()

    simulateButton:SetText("|cff00ff00Stop|r")
end

function LRP:StopSimulateLine()
    simulateLine:SetPoint("TOP", timeline, "TOPLEFT")
    simulateLine:SetPoint("BOTTOM", timeline, "BOTTOMLEFT")
    simulateLine:Hide()

    simulateButton:SetText("|cff00ff00Simulate|r")
end

-- Typically only called when timelineDensity changes
local function RebuildTimeline(newViewTime)
    BuildTrackEntries()
    BuildIntervalLines()
    BuildPhaseLines()
    LRP:BuildDeathLine()

    SetViewTime(newViewTime or 0)
    PositionReminderLines()

    C_Timer.After(0, UpdatePhaseLabelVisibility) -- leftTime/rightTime not built yet, fire after a frame
end

-- Should be called once whenever timeline data changes (including when a track gets toggled)
-- When a track gets toggled, the current view time should be supplied to not move the view time to 0
-- If no view time is supplied, just move it to 0 (such as when changing the encounter)
BuildTimeline = function(newViewTime)
    -- Public version runs with no data included
    if not timelineData then
        timelineData = {phases = {}, events = {}}

        UIDropDownMenu_SetText(dropdown, "No data")
    end

    if not newViewTime then newViewTime = 0 end

    -- Count visible timeline tracks
    -- Enable highlight for the ones that are visible
    local trackVisibility = LiquidRemindersSaved.settings.timeline.trackVisibility[selectedEncounterID]
    local visibleTracks = 0
    local visibleLabels = 0

    for _, eventData in ipairs(timelineData.events) do
        if eventData.show then
            visibleLabels = visibleLabels + 1

            if trackVisibility[eventData.value] then
                local highlight = trackHighlightPool[visibleTracks + 1]

                if not highlight then
                    highlight = CreateFrame("Frame", nil, view)
                    highlight:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -visibleTracks * (trackHeight + spacing))
                    highlight:SetPoint("BOTTOMRIGHT", view, "TOPRIGHT", 0, -visibleTracks * (trackHeight + spacing) - trackHeight)
                    highlight:SetFrameLevel(view:GetFrameLevel() + frameLevels.trackHighlight)

                    highlight.tex = highlight:CreateTexture(nil, "BACKGROUND")
                    highlight.tex:SetAllPoints(highlight)
                    highlight.tex:SetColorTexture(0.8, 0.8, 1, 0.1)

                    trackHighlightPool[visibleTracks + 1] = highlight
                end

                highlight:Hide()

                visibleTracks = visibleTracks + 1
            end
        end
    end

    local timelineHeight = visibleTracks * (trackHeight + spacing) - spacing
    local labelContainerHeight = visibleLabels * (trackHeight + spacing) - spacing
    timelineSpan = 60 -- Default value is 60 in case the timeline has no events (would retain previous value otherwise)

    -- Determine the length of the fight
    for _, spellData in ipairs(timelineData.events) do
        for _, entry in ipairs(spellData.entries) do
            local startTime = entry[1] -- Number of seconds into the fight that this event occurs
            local duration = entry[2] or 0 -- Number of seconds this event lasts for

            timelineSpan = math.max(timelineSpan or 0, math.ceil(startTime + duration))
        end
    end

    timelineWidth = (timelineSpan or 0) / timelineDensity

    -- Ensure that the containers are all properly sized according to their children
    labelContainer:SetHeight(labelContainerHeight) -- Width is set later inside BuildTrackLabels()
    view:SetHeight(timelineHeight)
    LRP.timeline:SetHeight(labelContainerHeight)
    timeline:SetSize(timelineWidth, timelineHeight)

    BuildTrackLabels()
    BuildSimulateLine()
    RebuildTimeline(newViewTime)
    LRP:BuildReminderLines()

    -- Fix the main window height based on the numer of tracks
    local windowHeight = labelContainerHeight + 280

    LRP.window:SetHeight(windowHeight)
    LRP.window:SetResizeBounds(800, windowHeight, 2000, windowHeight)
end

local function ZoomTimeline(delta)
    -- The time below the cursor should remain "stationary" when zooming
    -- Save the X position of the mouse relative to timeline start, and the time at that position
    -- We use this later in SetViewTime() to accomplish the above
    local zoomX = (mouseoverTime - viewTime) / timelineDensity
    local zoomTime = mouseoverTime

    timelineDensity = math.min(4, math.max(0.05, timelineDensity - delta * 0.02)) -- Constrain the minimum/maximum zoom level
    timelineDensity = math.min(timelineSpan / viewWidth, timelineDensity) -- Make sure we don't zoom out to a point where the timeline is smaller than the view

    timelineWidth = timelineSpan / timelineDensity

    timeline:SetWidth(timelineWidth)

    RebuildTimeline(zoomTime - zoomX * timelineDensity)
end

function LRP:InitializeTimeline()
    -- Parent frame
    LRP.timeline = CreateFrame("Frame", nil, UIParent)

    -- Label container
    labelContainer = CreateFrame("Frame", nil, LRP.timeline)

    labelContainer:SetPoint("TOPLEFT", LRP.timeline)

    -- View frame (visible area of the timeline)
    view = CreateFrame("Button", nil, LRP.timeline)

    view:SetPoint("TOPLEFT", labelContainer, "TOPRIGHT", spacing, 0)
    view:SetPoint("TOPRIGHT", LRP.timeline)

    view.tex = view:CreateTexture(nil, "BACKGROUND")
    view.tex:SetAllPoints(view)
    view.tex:SetColorTexture(0, 0, 0, 0.5)

    view:SetScript(
        "OnEnter",
        function()
            view.cursorLine:Show()
            view.cursorTime:Show()
        end
    )

    view:SetScript(
        "OnLeave",
        function()
            view.cursorLine:Hide()
            view.cursorTime:Hide()
        end
    )

    view:SetScript(
        "OnUpdate",
        function()
            if view:IsMouseOver() then
                -- Position line/timeFrame
                local uiScale = UIParent:GetEffectiveScale()
                local mouseX = GetCursorPosition()
                local frameX = timeline:GetCenter()

                local offset = Round(mouseX / uiScale - frameX)

                view.cursorLine:SetPoint("TOP", timeline, "TOP", offset, 0)
                view.cursorLine:SetPoint("BOTTOM", timeline, "BOTTOM", offset, -spacing)

                -- Display time at line position
                local pixel = timelineWidth / 2 + offset

                mouseoverTime = timelineSpan * pixel / timelineWidth

                view.cursorTime.text:SetText(LRP:SecondsToClock(mouseoverTime))
            end

            if dragging then
                local cursorX = GetCursorPosition() / UIParent:GetEffectiveScale()
                local distance = dragStartX - cursorX

                if distance ~= 0 then
                    local difference = distance * timelineSpan / timelineWidth

                    SetViewTime(dragStartTime + difference)
                end
            end
        end
    )

    view:SetScript(
        "OnMouseDown",
        function(_, button)
            if button == "RightButton" then
                dragging = true
                dragStartTime = viewTime
                dragStartX = GetCursorPosition() / UIParent:GetEffectiveScale()
            end
        end
    )

    view:SetScript(
        "OnMouseUp",
        function(_, button)
            if button == "RightButton" then
                dragging = false
            end
        end
    )

    view:SetScript(
        "OnMouseWheel",
        function(_, delta)
            ZoomTimeline(delta)
        end
    )

    view:SetScript(
        "OnSizeChanged",
        function(_, width)
            viewWidth = width

            -- Make sure the view doesn't become larger than the timeline. If it does, rebuild.
            local oldTimelineDensity = timelineDensity
            timelineDensity = math.min(timelineSpan / viewWidth, timelineDensity)

            if oldTimelineDensity ~= timelineDensity then
                timelineWidth = timelineSpan / timelineDensity

                timeline:SetWidth(timelineWidth)

                RebuildTimeline()
            end

            SetViewTime()
        end
    )

    view:SetScript(
        "OnDoubleClick",
        function(_, button)
            if button == "LeftButton" then
                local phases = timelineData.phases
                local phaseNumber = 0

                for i, phase in ipairs(phases) do
                    if mouseoverTime > phase.time then
                        phaseNumber = i
                    end
                end

                local relativeToTime = phaseNumber == 0 and 0 or timelineData.phases[phaseNumber].time

                LRP:CreateReminderFromTimeline(timelineData, selectedEncounterID, selectedDifficulty, phaseNumber, LRP:Round(mouseoverTime - relativeToTime, 1))
            end
        end
    )

    -- View mask
    viewMask = view:CreateMaskTexture()

    viewMask:SetPoint("TOPLEFT", view, "TOPLEFT")
    viewMask:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, -(reminderLineMargin + reminderLineIconSize))
    viewMask:SetTexture("Interface\\BUTTONS\\WHITE8X8", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")

    -- Timeline
    timeline = CreateFrame("Frame", nil, view)

    -- Cursor line
    view.cursorLine = CreateFrame("Frame", nil, timeline)
    view.cursorLine:SetWidth(1)
    view.cursorLine:SetFrameLevel(view:GetFrameLevel() + frameLevels.cursorLine)
    view.cursorLine:SetPoint("TOP", view, "TOP")
    view.cursorLine:SetPoint("BOTTOM", view, "BOTTOM", 0, -spacing)
    view.cursorLine:SetShown(view:IsMouseOver())

    view.cursorLine.tex = view.cursorLine:CreateTexture(nil, "BACKGROUND")
    view.cursorLine.tex:SetAllPoints(view.cursorLine)
    view.cursorLine.tex:SetColorTexture(1, 1, 1)

    -- Cursor time indicator
    view.cursorTime = CreateFrame("Frame", nil, view)
    view.cursorTime:SetFrameLevel(view:GetFrameLevel() + frameLevels.cursorTime)
    view.cursorTime:SetPoint("TOP", view.cursorLine, "BOTTOM")
    view.cursorTime:SetSize(50, 24)

    view.cursorTime.tex = view.cursorTime:CreateTexture(nil, "BACKGROUND")
    view.cursorTime.tex:SetAllPoints(view.cursorTime)
    view.cursorTime.tex:SetColorTexture(0, 0, 0, .5)
    view.cursorTime:SetShown(view:IsMouseOver())

    view.cursorTime.text = view.cursorTime:CreateFontString(nil, "OVERLAY")
    view.cursorTime.text:SetFontObject(LRFont16)
    view.cursorTime.text:SetPoint("CENTER", view.cursorTime, "CENTER", 1, -1)

    -- Left time
    view.leftTime = CreateFrame("Frame", nil, view)
    view.leftTime:SetPoint("BOTTOMLEFT", view, "TOPLEFT", 0, spacing)
    view.leftTime:SetSize(50, 24)

    view.leftTime.tex = view.leftTime:CreateTexture(nil, "BACKGROUND")
    view.leftTime.tex:SetAllPoints(view.leftTime)
    view.leftTime.tex:SetColorTexture(0, 0, 0, .5)

    view.leftTime.text = view.leftTime:CreateFontString(nil, "OVERLAY")
    view.leftTime.text:SetFontObject(LRFont16)
    view.leftTime.text:SetPoint("CENTER", view.leftTime, "CENTER", 1, -1)

    -- Right time
    view.rightTime = CreateFrame("Frame", nil, view)
    view.rightTime:SetPoint("BOTTOMRIGHT", view, "TOPRIGHT", 0, spacing)
    view.rightTime:SetSize(50, 24)

    view.rightTime.tex = view.rightTime:CreateTexture(nil, "BACKGROUND")
    view.rightTime.tex:SetAllPoints(view.rightTime)
    view.rightTime.tex:SetColorTexture(0, 0, 0, .5)

    view.rightTime.text = view.rightTime:CreateFontString(nil, "OVERLAY")
    view.rightTime.text:SetFontObject(LRFont16)
    view.rightTime.text:SetPoint("CENTER", view.rightTime, "CENTER", 1, -1)

    -- Exceeds timeline span
    exceedsTimeLabel = LRP.window:CreateFontString(nil, "OVERLAY")
    exceedsTimeLabel:SetFontObject(LRFont15)
    exceedsTimeLabel:SetText("|cFFFFCC00Exceeds timeline maximum|r")
    exceedsTimeLabel:SetPoint("TOPLEFT", LRP.window.moverFrame, "BOTTOMLEFT", 2 * spacing, -2 * spacing)
    exceedsTimeLabel:Hide() -- Should only show if there's reminders that exceeds the timeline span

    LRP:AddTooltip(
        exceedsTimeLabel,
        "These reminders are set to show up after the maximum time on the timeline. As such, they cannot be displayed.|n|n" ..
        "|cff29ff62These reminders may still show up during an encounter, if it lasts long enough!|r"
    )

    -- Unknown events label (this element is positioned in PositionReminderLines(), based on the number of reminders with unknown events)
    unknownEventsLabel = LRP.window:CreateFontString(nil, "OVERLAY")
    unknownEventsLabel:SetFontObject(LRFont15)
    unknownEventsLabel:SetText("|cFFFFCC00References unknown event|r")
    unknownEventsLabel:Hide() -- Should only show if there's reminders that reference unknown events

    LRP:AddTooltip(
        unknownEventsLabel,
        "These reminders are relative to events that are not on the timeline. As such, the the addon doesn't know where to display them.|n|n" ..
        "|cff29ff62These reminders may still show up during an encounter, if the event does occur!|r"
    )

	-- Warning icon
	warningIcon = CreateFrame("Button", nil, LRP.timeline)

    warningIcon:SetSize(20, 20)
    warningIcon:SetHighlightAtlas("services-icon-warning", "ADD")
    warningIcon:Hide()

    warningIcon.tex = warningIcon:CreateTexture()
    warningIcon.tex:SetAllPoints(warningIcon)
    warningIcon.tex:SetAtlas("services-icon-warning")

    -- Dropdown
    dropdown = LRP:CreateDropdown(
        LRP.timeline,
        "",
        LRP.timelineDataInfoTable,
        function(instanceType, instance, encounter, difficulty)
            -- Slightly hacky implementation: the "difficulty" value for raids is actually in the format <difficulty icon><encounter icon><encounter name>
            -- This is used to set the dropdown text after selecting it, since by default it would just become "<heroic icon> Heroic" (or similar for mythic)
            local dropdownText = difficulty

            difficulty = difficulty and (difficulty:match("Mythic") or difficulty:match("DungeonSkull")) and 2 or 1

            -- Dungeons are mythic-only
            if instanceType == 2 then
                difficulty = 2
            end

            if instanceType ~= selectedInstanceType or instance ~= selectedInstance or encounter ~= selectedEncounter or difficulty ~= selectedDifficulty then
				local encounterInfo = LRP.timelineData[instanceType][instance] and LRP.timelineData[instanceType][instance].encounters[encounter]

                timelineData = encounterInfo and encounterInfo[difficulty]
    
                -- If somehow we are trying to load an encounter that doesn't exist, just load the default one
                if not timelineData then
                    instanceType = 1
                    instance = 1
                    encounter = 1
					difficulty = 2
					
					encounterInfo = LRP.timelineData[instanceType][instance].encounters[encounter]
                    timelineData = encounterInfo[difficulty]
                end
    
                -- Set in SavedVariables so we can restore current timeline after (re)load
                LiquidRemindersSaved.settings.timeline.selectedInstanceType = instanceType
                LiquidRemindersSaved.settings.timeline.selectedInstance = instance
                LiquidRemindersSaved.settings.timeline.selectedEncounter = encounter
                LiquidRemindersSaved.settings.timeline.selectedDifficulty = difficulty
                
                selectedInstanceType = instanceType
                selectedInstance = instance
                selectedEncounter = encounter
                selectedDifficulty = difficulty
                selectedEncounterID = encounterInfo.id
        
                -- Ensure phases are ordered by time
                table.sort(
                    timelineData.phases,
                    function(phaseA, phaseB)
                        return phaseA.time < phaseB.time
                    end
                )

				-- Show/hide warning
				if encounterInfo.warning then
					warningIcon:Show()

					LRP:AddTooltip(warningIcon, encounterInfo.warning)
				else
					warningIcon:Hide()
				end
                
                -- If this is the first time we view this encounter, there is no reminder data yet
                -- Create the table
                if not LiquidRemindersSaved.reminders[selectedEncounterID] then
                    LiquidRemindersSaved.reminders[selectedEncounterID] = {{},{}}
                end
        
                reminderData = LiquidRemindersSaved.reminders[selectedEncounterID][selectedDifficulty]
        
                BuildTimeline()
            end
    
            if LRP.reminderConfig then
                LRP.reminderConfig:Hide()
            end
    
            if LRP.simulation then
                LRP:StopSimulation()
            end

            if dropdown and dropdownText then
                UIDropDownMenu_SetText(dropdown, dropdownText)
            end
        end,
        {
            -- Dungeons don't have a heroic/mythic choice in the dropdown, so if we previously had a dungeon timeline suggested, don't supply a difficulty
            LiquidRemindersSaved.settings.timeline.selectedInstanceType or 1,
            LiquidRemindersSaved.settings.timeline.selectedInstance or 1,
            LiquidRemindersSaved.settings.timeline.selectedEncounter or 1,
            LiquidRemindersSaved.settings.timeline.selectedInstanceType ~= 2 and (LiquidRemindersSaved.settings.timeline.selectedDifficulty or 2) or nil
        }
    )

	warningIcon:SetPoint("BOTTOMRIGHT", dropdown, "TOPRIGHT", 0, -3)
    dropdown:SetPoint("BOTTOMLEFT", labelContainer, "TOPLEFT", 0, spacing - 4)
    dropdown:SetPoint("BOTTOMRIGHT", labelContainer, "TOPRIGHT", -trackHeight - spacing, spacing - 4)
    UIDropDownMenu_SetWidth(dropdown, dropdownMinWidth - 2 *  (UIDROPDOWNMENU_DEFAULT_WIDTH_PADDING or 25)) -- This is overwritten in BuildTrackLabels() if the track width exceeds it

    -- If a raid is selected, we set the dropdown text manually
    -- Normally this is done inside of the dropdown's SetValue function, but for the initial load it can't do so because it doesn't exist yet
    -- If we don't do this, the dropdown text will be "Heroic" or "Mythic", since that is the deepest dropdown level that is selected
    -- We could just call SetValue with these values, but then we have to rebuild the timeline, and we don't want that
    if selectedInstanceType == 1 then
        local instanceType = LiquidRemindersSaved.settings.timeline.selectedInstanceType
        local instance = LiquidRemindersSaved.settings.timeline.selectedInstance
        local encounter = LiquidRemindersSaved.settings.timeline.selectedEncounter
        local difficulty = LiquidRemindersSaved.settings.timeline.selectedDifficulty
        local text = LRP.timelineDataInfoTable[instanceType].children[instance].children[encounter].children[difficulty].value

        UIDropDownMenu_SetText(dropdown, text)
    end

    -- Relevant reminder toggle
    relevantRemindersCheckButton = LRP:CreateCheckButton(
        LRP.window,
        "Show relevant reminders only",
        function(checked)
            LiquidRemindersSaved.settings.timeline.showRelevantRemindersOnly = checked

            LRP:BuildReminderLines()
        end,
        true
    )

    relevantRemindersCheckButton:SetPoint("TOPRIGHT", LRP.window.moverFrame, "BOTTOMRIGHT", -2 * spacing, -2 * spacing)
    relevantRemindersCheckButton:SetChecked(LiquidRemindersSaved.settings.timeline.showRelevantRemindersOnly)
    relevantRemindersCheckButton:SetSize(20, 20)
    relevantRemindersCheckButton.title:SetFontObject(LRFont15)

    LRP:AddTooltip(relevantRemindersCheckButton, "Only show reminders that are relevant to your current character/class/spec")
    LRP:AddTooltip(relevantRemindersCheckButton.title, "Only show reminders that are relevant to your current character/class/spec")

    -- Show MRT note reminder toggle
    showNoteRemindersCheckButton = LRP:CreateCheckButton(
        LRP.window,
        "Show |cff80ffffMRT|r note reminders",
        function(checked)
            LiquidRemindersSaved.settings.timeline.showNoteReminders = checked

            LRP:BuildReminderLines()
        end,
        true
    )

    showNoteRemindersCheckButton:SetPoint("TOPRIGHT", relevantRemindersCheckButton, "BOTTOMRIGHT", 0, - 2 * spacing)
    showNoteRemindersCheckButton:SetChecked(LiquidRemindersSaved.settings.timeline.showNoteReminders)
    showNoteRemindersCheckButton:SetSize(20, 20)
    showNoteRemindersCheckButton.title:SetFontObject(LRFont15)

    LRP:AddTooltip(showNoteRemindersCheckButton, "Show MRT note reminders on the timeline. These cannot be modified.|n|nThis option will show them regardless of which encounter you are viewing.")
    LRP:AddTooltip(showNoteRemindersCheckButton.title, "Show MRT note reminders on the timeline. These cannot be modified.|n|nThis option will show them regardless of which encounter you are viewing.")

    -- Show death lines toggle
    showDeathLineCheckButton = LRP:CreateCheckButton(
        LRP.window,
        "Show |cffff052bdeath|r line",
        function(checked)
            LiquidRemindersSaved.settings.timeline.showDeathLine = checked

            LRP:BuildDeathLine()
        end,
        true
    )

    showDeathLineCheckButton:SetPoint("TOPRIGHT", showNoteRemindersCheckButton, "BOTTOMRIGHT", 0, - 2 * spacing)
    showDeathLineCheckButton:SetChecked(LiquidRemindersSaved.settings.timeline.showDeathLine)
    showDeathLineCheckButton:SetSize(20, 20)
    showDeathLineCheckButton.title:SetFontObject(LRFont15)

    LRP:AddTooltip(showDeathLineCheckButton, "Show a |cffff052bred|r line for where you last died on this encounter")
    LRP:AddTooltip(showDeathLineCheckButton.title, "Show a |cffff052bred|r line for where you last died on this encounter")

    -- Simulate button
    simulateButton = LRP:CreateButton(
        timeline,
        "|cff00ff00Simulate|r",
        function()
            if LRP.simulation then
                LRP:StopSimulation()
            else
                LRP:StartSimulation(selectedInstanceType, selectedInstance, selectedEncounter, selectedDifficulty, timelineSpan, viewTime)
            end
        end
    )

    simulateButton:SetPoint("TOPLEFT", labelContainer, "BOTTOMLEFT", spacing, -spacing)

    LRP:AddTooltip(simulateButton, "Simulates the fight and shows all relevant reminders. Simulation progression is indicated by the green line.|n|nSimulation starts where you are currently viewing the timeline.")

    -- Build timeline
    BuildTimeline()
end
