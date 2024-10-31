---@diagnostic disable: undefined-field
local _, LRP = ...

if LRP.isRetail then
	LRP.timelineData = {
		{ -- Raids
			{
				name = "Nerub-ar Palace",
				icon = 5779391,
				encounters = {
					{
						name = "Ulgrax the Devourer",
						icon = 5779390,
						id = 2902,
						[1] = {}, -- Heroic
						[2] = {}, -- Mythic
					},
					{
						name = "The Bloodbound Horror",
						icon = 5779386,
						id = 2917,
						[1] = {}, -- Heroic
						[2] = {}, -- Mythic
					},
					{
						name = "Sikran, Captain of the Sureki",
						icon = 5779389,
						id = 2898,
						[1] = {}, -- Heroic
						[2] = {}, -- Mythic
					},
					{
						name = "Rasha'nan",
						icon = 5661707,
						id = 2918,
						[1] = {}, -- Heroic
						[2] = {}, -- Mythic
					},
					{
						name = "Broodtwister Ovi'nax",
						icon = 5688871,
						id = 2919,
						[1] = {}, -- Heroic
						[2] = {}, -- Mythic
					},
					{
						name = "Nexus-Princess Ky'veza",
						icon = 5779388,
						id = 2920,
						[1] = {}, -- Heroic
						[2] = {}, -- Mythic
					},
					{
						name = "Silken Court",
						icon = 5779387,
						id = 2921,
						[1] = {}, -- Heroic
						[2] = {}, -- Mythic
					},
					{
						name = "Queen Ansurek",
						icon = 5779391,
						id = 2922,
						[1] = {}, -- Heroic
						[2] = {}, -- Mythic
					},
				},
			}
		},
		{ -- Dungeons
			{
				name = "Ara-Kara, City of Echoes",
				icon = 5899326,
				encounters = {
					{
						name = "Avanoxx",
						icon = 237274,
						id = 2926,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Anub'zekt",
						icon = 237274,
						id = 2906,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Ki'katal the Harvester",
						icon = 237274,
						id = 2901,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
				}
			},
			{
				name = "City of Threads",
				icon = 5899328,
				encounters = {
					{
						name = "Orator Krix'vizk",
						icon = 237274,
						id = 2907,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Fangs of the Queen",
						icon = 237274,
						id = 2908,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "The Coaglamation",
						icon = 237274,
						id = 2905,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Izo, the Grand Splicer",
						icon = 237274,
						id = 2909,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
				}
			},
			{
				name = "The Dawnbreaker",
				icon = 5899330,
				encounters = {
					{
						name = "Speaker Shadowcrown",
						icon = 237274,
						id = 2837,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Anub'ikkaj",
						icon = 237274,
						id = 2838,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Rasha'nan",
						icon = 237274,
						id = 2839,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
				}
			},
			{
				name = "The Stonevault",
				icon = 5899333,
				encounters = {
					{
						name = "E.D.N.A.",
						icon = 237274,
						id = 2854,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Skarmorak",
						icon = 237274,
						id = 2880,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Master Machinists",
						icon = 237274,
						id = 2888,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Void Speaker Eirich",
						icon = 237274,
						id = 2883,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
				}
			},
			{
				name = "Mists of Tirna Scithe",
				icon = 3601531,
				encounters = {
					{
						name = "Ingra Maloch",
						icon = 237274,
						id = 2397,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Tred'ova",
						icon = 237274,
						id = 2393,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
				}
			},
			{
				name = "Necrotic Wake",
				icon = 3601560,
				encounters = {
					{
						name = "Amarth, The Harvester",
						icon = 237274,
						id = 2388,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Surgeon Stitchflesh",
						icon = 237274,
						id = 2389,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Nalthor the Rimebinder",
						icon = 237274,
						id = 2390,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
				}
			},
			{
				name = "Siege of Boralus",
				icon = 2011139,
				encounters = {
					{
						name = "Dread Captain Lockwood",
						icon = 237274,
						id = 2109,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Hadal Darkfathom",
						icon = 237274,
						id = 2099,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Viq'Goth",
						icon = 237274,
						id = 2100,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
				}
			},
			{
				name = "Grim Batol",
				icon = 409596,
				encounters = {
					{
						name = "General Umbriss",
						icon = 237274,
						id = 1051,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Forgemaster Throngus",
						icon = 237274,
						id = 1050,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Drahga Shadowburner",
						icon = 237274,
						id = 1048,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
					{
						name = "Erudax, the Duke of Below",
						icon = 237274,
						id = 1049,
						[1] = {phases = {}, events = {}}, -- Heroic (not supported for dungeons)
						[2] = {}, -- Mythic
					},
				}
			}
		}
	}
else
	LRP.timelineData = {
		{
			{
				name = "Firelands",
				icon = 514278,
				encounters = {
					{
						name = "Beth'tilac",
						icon = 524349,
						id = 1197,
						[1] = {}, -- Normal
						[2] = {}, -- Heroic
					},
                    {
						name = "Lord Rhyolith",
						icon = 524350,
						id = 1204,
						[1] = {}, -- Normal
						[2] = {}, -- Heroic
					},
                    {
						name = "Alysrazor",
						icon = 512826,
						id = 1206,
						[1] = {}, -- Normal
						[2] = {}, -- Heroic
					},
                    {
						name = "Shannox",
						icon = 524351,
						id = 1205,
						warning = "The ability timers for this boss are very inconsistent.|n|nDon't rely on the timeline to be completely accurate.",
						[1] = {}, -- Normal
						[2] = {}, -- Heroic
					},
                    {
						name = "Baleroc, the Gatekeeper",
						icon = 515033,
						id = 1200,
						[1] = {}, -- Normal
						[2] = {}, -- Heroic
					},
                    {
						name = "Majordomo Staghelm",
						icon = 512827,
						id = 1185,
						warning = "The timeline assumes that you start the boss in Cat Form, and briefly swap to Scorpion Form every 4 Leaping Flames casts.|n|nIf you want to set a reminder for a specific time in the fight (rather than for a specific phase), make it relative to pull.",
						[1] = {}, -- Normal
						[2] = {}, -- Heroic
					},
                    {
						name = "Ragnaros",
						icon = 512617,
						id = 1203,
						[1] = {}, -- Normal
						[2] = {}, -- Heroic
					},
				}
			}
		}
	}
end

if LRP.gs.debug then
    table.insert(
        LRP.timelineData[1],
        {
            name = "Castle Nathria",
            icon = 3614361,
            encounters = {
                {
                    name = "Shriekwing",
                    icon = 3614368,
                    id = 2398,
                    [1] = {}, -- Heroic
                    [2] = {}, -- Mythic
                },
            }
        }
    )

	table.insert(
        LRP.timelineData[2],
        {
            name = "Theater of Pain",
            icon = 3601550,
            encounters = {
                {
                    name = "An Affront of Challengers",
                    icon = 237274,
                    id = 2391,
                    [1] = {}, -- Heroic
                    [2] = {}, -- Mythic
                },
            }
        }
    )
end

function LRP:InitializeTimelineData()
    local mythicIcon = LRP:IconString(LRP.isRetail and "UI-HUD-Minimap-GuildBanner-Mythic-Large" or "DungeonSkull")

    -- Transforms the above table into an infotable that can be interpreted by dropdown widgets
    LRP.timelineDataInfoTable = {
        {
            text = "Raids",
            value = 1,
            children = {}
        }
    }

    if LRP.isRetail then
        table.insert(
            LRP.timelineDataInfoTable,
            {
                text = "Dungeons",
                value = 2,
                children = {}
            }
        )
    end

    for instanceType, instances in ipairs(LRP.timelineData) do
        for i, instanceInfo in ipairs(instances) do
            LRP.timelineDataInfoTable[instanceType].children[i] = {
                text = instanceInfo.name,
                icon = instanceInfo.icon,
                value = i,
                children = {}
            }
            
            for j, encounterInfo in ipairs(instanceInfo.encounters) do
                if instanceType == 1 then -- Raid
                    local encounterIcon = LRP:IconString(encounterInfo.icon)
                    
                    if LRP.isRetail then
                        LRP.timelineDataInfoTable[instanceType].children[i].children[j] = {
                            text = encounterInfo.name,
                            icon = encounterInfo.icon,
                            value = j,
                            children = {
                                {
                                    text = "Heroic",
                                    value = string.format("%s %s", encounterIcon, encounterInfo.name)
                                },
                                {
                                    text = "Mythic",
                                    icon = "UI-HUD-Minimap-GuildBanner-Mythic-Large",
                                    value = string.format("%s%s %s", mythicIcon, encounterIcon, encounterInfo.name)
                                },
                            }
                        }
                    else
                        LRP.timelineDataInfoTable[instanceType].children[i].children[j] = {
                            text = encounterInfo.name,
                            icon = encounterInfo.icon,
                            value = j,
                            children = {
                                {
                                    text = "Normal",
                                    value = string.format("%s %s", encounterIcon, encounterInfo.name)
                                },
                                {
                                    text = "Heroic",
                                    icon = "DungeonSkull",
                                    value = string.format("%s%s %s", mythicIcon, encounterIcon, encounterInfo.name)
                                },
                            }
                        }
                    end
                else -- Dungeon
                    LRP.timelineDataInfoTable[instanceType].children[i].children[j] = {
                        text = encounterInfo.name,
                        icon = encounterInfo.icon,
                        value = j
                    }
                end
            end
        end
    end

    -- Add a time field to the phase entries for encounters
    -- This time field is based on when the specified event happens according to the event table
    -- This is only done to know (estimate) where the phase labels/reminder lines should appear on the timeline
    -- Actual reminders during encounters show based on the events themselves, not based on this estimated time
    for _, instances in pairs(LRP.timelineData) do
        for _, instanceInfo in ipairs(instances) do
            for _, encounterInfo in ipairs(instanceInfo.encounters) do
                for _, difficultyInfo in ipairs(encounterInfo) do
                    for _, phaseInfo in ipairs(difficultyInfo.phases) do
                        for _, eventInfo in ipairs(difficultyInfo.events) do
                            if phaseInfo.event == eventInfo.event and phaseInfo.value == eventInfo.value then
                                phaseInfo.time = eventInfo.entries[phaseInfo.count][1]
                            end
                        end
                    end
                end
            end 
        end
    end

    -- Populate the "track visibility" table in options
    -- This table determines which tracks show on the timeline
    -- Users can turn certain tracks off in case they are not interested in them (e.g. role-specific abilities like tank slams)
    if not LiquidRemindersSaved.settings.timeline.trackVisibility then LiquidRemindersSaved.settings.timeline.trackVisibility = {} end

    local trackVisibility = LiquidRemindersSaved.settings.timeline.trackVisibility

    -- Raid track visibility
    for instanceType in pairs(LRP.timelineData) do
        for _, instanceInfo in ipairs(LRP.timelineData[instanceType]) do
            for _, encounterInfo in ipairs(instanceInfo.encounters) do
                local encounterID = encounterInfo.id
    
                -- If this is the first time we see this encounter, create a table for it
                if not trackVisibility[encounterID] then
                    trackVisibility[encounterID] = {}
                end
                
                for _, difficultyInfo in ipairs(encounterInfo) do
                    for _, eventInfo in ipairs(difficultyInfo.events) do
                        if eventInfo.show then
                            local spellID = eventInfo.value
        
                            -- If the entry does not exist yet, set it to show by default
                            if trackVisibility[encounterID][spellID] == nil then
                                trackVisibility[encounterID][spellID] = true
                            end
                        end
                    end
                end
            end 
        end
    end
end