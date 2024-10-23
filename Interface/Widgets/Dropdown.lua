local _, LRP = ...

local function GetEntry(t, indexTable)
    local output = t

    for _, index in ipairs(indexTable) do
        output = output.children and output.children[index] or output[index]
    end

    return output
end

function LRP:CreateDropdown(parent, title, _infoTable, OnValueChanged, initialValue)
    local dropdown = CreateFrame("FRAME", nil, parent, "UIDropDownMenuTemplate")

    dropdown.OnEnter = function() end
    dropdown.OnLeave = function() end

    dropdown:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    dropdown:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    local height = 24
	local infoTable = _infoTable

    local dropdownTitle = dropdown:CreateFontString(nil, "OVERLAY")

    dropdownTitle:SetFontObject(LRFont13)
    dropdownTitle:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, -(32 - height) / 2)
    dropdownTitle:SetText(string.format("|cFFFFCC00%s|r", title))

    dropdown.Text:AdjustPointsOffset(0, -1)
    dropdown.Text:SetFontObject(LRFont13)

    -- Value selection
    dropdown.currentValue = {}

	-- Sets the current value of the dropdown
	-- This function expects an array, with the value of each entry being the selection for that level of the dropdown hierarchy
	-- e.g. {2, 3} would select the second value in the first level, and the third value in the second level
    function dropdown:SetValue(newValue)
        if not next(infoTable) then return end
        
        dropdown.currentValue = newValue

        local node = infoTable
        local outputValues = {}

        for _, index in ipairs(newValue) do
            table.insert(outputValues, node[index].value or index)

            node = node[index].children
        end

        local entry = GetEntry(infoTable, newValue)
        local text = entry.text
        local icon = entry.icon

        if icon then
            icon = LRP:IconString(icon)

            UIDropDownMenu_SetText(dropdown, string.format("%s %s", icon, text))
        else
            UIDropDownMenu_SetText(dropdown, text)
        end
        
        OnValueChanged(unpack(outputValues))
        CloseDropDownMenus()
    end

	function dropdown:SetDefaultValue()
		local depth = 0
        local node = infoTable
        local value = {}

        while node do
            depth = depth + 1
            node = node[1] and node[1].children
        end

        for i = 1, depth do
            value[i] = 1
        end

        dropdown:SetValue(value)
	end

	function dropdown:SetInfoTable(__infoTable)
		infoTable = __infoTable

		UIDropDownMenu_Initialize(
			dropdown,
			function(_, level, menuList)
				if not level then level = 1 end
		
				local info = UIDropDownMenu_CreateInfo()

				-- Select the correct info table node to display
				if not menuList then menuList = {} end

				local infoTableNode = infoTable

				for _, index in ipairs(menuList) do
					infoTableNode = infoTableNode[index].children
				end

				for i, entry in ipairs(infoTableNode) do
					local hasChildren = entry.children and type(entry.children) == "table" and #entry.children > 0

                    -- Icons are handled differently in classic than they are in retail
                    -- Atlases are not supported, and neither is x offset to make them not overlap with the arrows
                    -- Just put the icons in front of the text for classic


					info.text = entry.text
					info.hasArrow = hasChildren

					info.menuList = CopyTable(menuList)
					table.insert(info.menuList, i)

					info.checked = tCompare(info.menuList, {unpack(dropdown.currentValue, 1, #info.menuList)})

                    if entry.icon then
                        if LRP.isRetail then
                            info.icon = entry.icon
                            info.iconXOffset = -16
                            info.tCoordLeft = 0.08
                            info.tCoordRight = 0.92
                            info.tCoordTop = 0.08
                            info.tCoordBottom = 0.92
                            info.topPadding = 1
                            info.padding = 8
                        else
                            local icon = LRP:IconString(entry.icon)

                            info.text = string.format("%s %s", icon or "", info.text)
                        end
                    end

					if not hasChildren then
						info.func = function(_, newValue) dropdown:SetValue(newValue) end
						info.arg1 = info.menuList
					end

					UIDropDownMenu_AddButton(info, level)
				end
			end
		)

		dropdown:SetDefaultValue()
	end

	dropdown:SetInfoTable(infoTable)

    if initialValue then
        dropdown:SetValue(initialValue)
	end

    -- Skinning
    local borderColor = LRP.gs.visual.borderColor

    LRP:AddBorder(dropdown, 1, 0, -(32 - height) / 2)
    dropdown:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    dropdown.Left:Hide()
    dropdown.Middle:Hide()
    dropdown.Right:Hide()

    dropdown.tex = dropdown:CreateTexture(nil, "BACKGROUND")
    dropdown.tex:SetHeight(height)
    dropdown.tex:SetPoint("LEFT", dropdown, "LEFT")
    dropdown.tex:SetPoint("RIGHT", dropdown, "RIGHT", -height, 0)
    dropdown.tex:SetColorTexture(0, 0, 0, 0.5)

    dropdown.Button:SetSize(height, height)
    dropdown.Button:ClearAllPoints()
    dropdown.Button:SetPoint("RIGHT", dropdown, "RIGHT")

    LRP:AddBorder(dropdown.Button)
    dropdown.Button:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    dropdown.Button.background = dropdown.Button:CreateTexture(nil, "BACKGROUND")
    dropdown.Button.background:SetAllPoints()
    dropdown.Button.background:SetColorTexture(0, 0, 0, 0.5)

    dropdown.Button:ClearHighlightTexture()
    dropdown.Button:ClearDisabledTexture()

    dropdown.Button.NormalTexture:SetTexture("Interface\\AddOns\\TimelineReminders\\Media\\Textures\\ArrowDown.tga")
    dropdown.Button.PushedTexture:SetTexture("Interface\\AddOns\\TimelineReminders\\Media\\Textures\\ArrowDownPushed.tga")

    dropdown.Button:SetHighlightAtlas("QuestSharing-QuestLog-ButtonHighlight", "ADD")
    dropdown.Button.HighlightTexture:SetAllPoints()

    dropdown.Text:ClearAllPoints()
    dropdown.Text:SetPoint("LEFT", dropdown, "LEFT", 4, 0)
    dropdown.Text:SetPoint("RIGHT", dropdown.Button, "LEFT", -4, 0)

    return dropdown
end