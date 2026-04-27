local _, NS = ...
NS.LibAdvancedMenuBuilder = {}
local LAMB = NS.LibAdvancedMenuBuilder
local initializerList = {}

LAMB.barTextures = {
    ["Default"] = { type = 'T', path = 7539072 },
    ["Blizzard Raid"] = { type = 'T', path = 'Interface/RaidFrame/Raid-Bar-Hp-Fill' },
    ["Blizzard Flat"] = { type = 'T', path = 'Interface/Buttons/WHITE8X8' },
    ["Smooth"] = { type = 'T', path = 137012 },
    ["Shields"] = { type = 'T', path = 'interface/raidframe/raidframeshieldoverlay' },
    ["Lunar"] = { type = 'A', path = '_Druid-LunarBar' },
    ["Torghast"] = { type = 'A', path = 'jailerstower-scorebar-fill-normal' },
    ["Insanity"] = { type = 'A', path = '_Priest-InsanityBar' },
    ["Empower"] = { type = 'A', path = 'ui-castingbar-disabled-tier4-empower' }
}

function LAMB.FormatForDisplay(number)
    return math.floor(number * 10 + 0.5) / 10
end

function LAMB.GetTextureDropdown()
    local container = Settings.CreateControlTextContainer()
    local sortedNames = {}
    for name in pairs(LAMB.barTextures) do table.insert(sortedNames, name) end
    table.sort(sortedNames)
    for _, name in ipairs(sortedNames) do
        local texture = LAMB.barTextures[name]
        local displayLabel
        if texture.type == 'T' then
            displayLabel = "|T" .. texture.path .. ":14:100|t " .. name
        else
            displayLabel = "|A:" .. texture.path .. ":14:100|a " .. name
        end
        container:Add(name, displayLabel)
    end
    return container:GetData()
end

function LAMB.CreateOptionsElement(data, optionsTable, parent)
    local initializer = nil
    if data.type == "header" then
        initializer = CreateSettingsListSectionHeaderInitializer(data.text, data.tooltip)
        parent.layout:AddInitializer(initializer)
        initializerList[data.key] = initializer
    elseif data.type == "button" then
        local buttonData = {
            name = data.text,
            buttonText = data.content,
            buttonClick = data.func,
            OnButtonClick = data.func,
            click = data.func,
            tooltip = data.tooltip,
            newTagID = nil,
            gameDataFunc = nil
        }
        initializer =  Settings.CreateElementInitializer("SettingButtonControlTemplate", buttonData)
        initializerList[data.key] = initializer
        parent.layout:AddInitializer(initializer)
    elseif data.type == "checkbox-dropdown" or data.type == "checkbox-texture" then
        if optionsTable[data.key] == nil then optionsTable[data.key] = data.default end
        local cbInput = Settings.RegisterAddOnSetting(parent.category, data.key, data.key, optionsTable, type(data.default), data.text, data.default)
        if optionsTable[data.ddKey] == nil then optionsTable[data.ddKey] = data.ddDefault end
        local ddInput = Settings.RegisterAddOnSetting(parent.category, data.ddKey, data.ddKey, optionsTable, type(data.ddDefault), data.ddText or "", data.ddDefault)

        local function callback(_, value)
            local func = data.func
            if func then
                func(value, data.funcArgs)
            end
        end
        cbInput:SetValueChangedCallback(callback)
        ddInput:SetValueChangedCallback(callback)

        local getOptionsFunc
        if data.type == "checkbox-texture" then
            getOptionsFunc = LAMB.GetTextureDropdown
        else
            getOptionsFunc = function()
                local container = Settings.CreateControlTextContainer()
                for _, item in ipairs(data.items) do
                    container:Add(item.value, item.text)
                end
                return container:GetData()
            end
        end

        initializer = CreateSettingsCheckboxDropdownInitializer(cbInput, data.text, data.tooltip, ddInput, getOptionsFunc, data.ddText or "", data.ddTooltip)
        parent.layout:AddInitializer(initializer)
        initializerList[data.key] = initializer
        if data.ddKey then initializerList[data.ddKey] = initializer end
    else
        if optionsTable[data.key] == nil then optionsTable[data.key] = data.default end
        local input = Settings.RegisterAddOnSetting(parent.category, data.key, data.key, optionsTable, type(data.default), data.text, data.default)
        input:SetValueChangedCallback(function(setting, value)
            local settingKey = setting:GetVariable()
            if data.readOnly and optionsTable[settingKey] ~= data.default then
                optionsTable[settingKey] = data.default
            else
                local func = data.func
                if func then
                    func(value, data.funcArgs)
                end
            end
        end)
        if data.type == "checkbox" then
            initializer = Settings.CreateCheckbox(parent.category, input, data.tooltip)
            initializerList[data.key] = initializer
        elseif data.type == "dropdown" then
            local function GetOptions()
                local container = Settings.CreateControlTextContainer()
                for _, item in ipairs(data.items) do
                    container:Add(item.value, item.text)
                end
                return container:GetData()
            end
            initializer = Settings.CreateDropdown(parent.category, input, GetOptions, data.tooltip)
            initializerList[data.key] = initializer
        elseif data.type == "slider" then
            local options = Settings.CreateSliderOptions(data.min, data.max, data.step)
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, LAMB.FormatForDisplay);
            initializer = Settings.CreateSlider(parent.category, input, options, data.tooltip)
            initializerList[data.key] = initializer
        elseif data.type == "color" then
            initializer = Settings.CreateColorSwatch(parent.category, input, data.tooltip)
            initializerList[data.key] = initializer
        elseif data.type == "texture" then
            initializer = Settings.CreateDropdown(parent.category, input, LAMB.GetTextureDropdown, data.tooltip)
            initializerList[data.key] = initializer
        end
    end
    if initializer and data.parent then
        initializer:SetParentInitializer(initializerList[data.parent], function() return optionsTable[data.parent] end)
    end
end

function LAMB.CreateOptionsPanel(optionsContent, optionsTable, name, type, parent)
    local category, layout = nil, nil
    if parent then
        if type == 'canvas' then
            category = Settings.RegisterCanvasLayoutSubcategory(parent, optionsContent, name)
            Settings.RegisterAddOnCategory(category)
        elseif type == 'vertical' then
            category, layout = Settings.RegisterVerticalLayoutSubcategory(parent, name)
            Settings.RegisterAddOnCategory(category)
            for _, data in ipairs(optionsContent) do
                LAMB.CreateOptionsElement(data, optionsTable, { category = category, layout = layout })
            end
        end
    else
        if type == 'canvas' then
            category = Settings.RegisterCanvasLayoutCategory(optionsContent, name)
            Settings.RegisterAddOnCategory(category)
        elseif type == 'vertical' then
            category, layout = Settings.RegisterVerticalLayoutCategory(name)
            Settings.RegisterAddOnCategory(category)
            for _, data in ipairs(optionsContent) do
                LAMB.CreateOptionsElement(data, optionsTable, { category = category, layout = layout })
            end
        end
    end
    return category
end