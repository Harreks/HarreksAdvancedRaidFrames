local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

function Ui.GenerateMinimapIcon()
    local HarfLDB = LibStub("LibDataBroker-1.1"):NewDataObject("HARF", {
        type = 'data source',
        text = 'Harrek\'s Advanced Raid Frames',
        icon = 'Interface/Addons/HarreksAdvancedRaidFrames/Assets/harrek-logo.png',
        OnClick = function() Settings.OpenToCategory(Options.lastCategory) end
    })
    local LibDBIcon = LibStub("LibDBIcon-1.0")
    LibDBIcon:Register('HARF', HarfLDB, Options.minimapButton)
end

function Ui.GetOptionsIntroPanel()
    if not Ui.OptionsIntroPanel then
        local optionsIntroPanel = CreateFrame('Frame')
        Ui.OptionsIntroPanel = optionsIntroPanel

        local title = optionsIntroPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
        title:SetScale(1.5)
        title:SetPoint('TOP', optionsIntroPanel, 'TOP', 0, -10)
        title:SetText('Advanced Raid Frames v' .. NS.Version)

        local logo = optionsIntroPanel:CreateTexture(nil, "ARTWORK")
        logo:SetTexture('Interface/Addons/HarreksAdvancedRaidFrames/Assets/harrek-logo.png')
        logo:SetSize(100, 100)
        logo:SetPoint('TOP', title, 'TOP', 0, -30)
        optionsIntroPanel.logo = logo

        local fontString = optionsIntroPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
        fontString:SetPoint('TOP', logo, 'BOTTOM', 0, -10)
        fontString:SetWidth(400)
        fontString:SetScale(1.3)
        local text = 'Advanced Raid Frames is my attempt at giving healers the tools they need to properly play the game, ' ..
        'while this is not a perfect solution i am working very hard trying to make it the best it can possibly be so we can all enjoy the game like we are used to.\n\n' ..
        'The method used can be a bit finnicky in some situations but improvements are constantly being made. If you find any bug or have any questions please contact me so we ' ..
        'can talk about it, i am excited to hear what you think.\n\n-Harrek'
        fontString:SetText(text)
        optionsIntroPanel.text = text

        optionsIntroPanel.buttons = {}
        local patreonButton = CreateFrame("Button", nil, optionsIntroPanel, "UIPanelButtonTemplate")
        patreonButton:SetSize(120, 30)
        patreonButton:SetText('Patreon')
        patreonButton:SetPoint('CENTER', optionsIntroPanel, 'BOTTOM', 0, 100)
        patreonButton:SetScript("OnClick", function()
            Util.DisplayPopupTextbox('Harrek\'s Patreon', 'https://www.patreon.com/cw/harrek')
        end)
        optionsIntroPanel.buttons.Patreon = patreonButton

        local discordButton = CreateFrame("Button", nil, optionsIntroPanel, "UIPanelButtonTemplate")
        discordButton:SetSize(120, 30)
        discordButton:SetText('Discord')
        discordButton:SetPoint('RIGHT', patreonButton, 'LEFT', -50, 0)
        discordButton:SetScript("OnClick", function()
            Util.DisplayPopupTextbox('Spiritbloom.Pro Discord', 'https://discord.gg/MMjNrUTxQe')
        end)

        local kofiButton = CreateFrame("Button", nil, optionsIntroPanel, "UIPanelButtonTemplate")
        kofiButton:SetSize(120, 30)
        kofiButton:SetText('Ko-fi')
        kofiButton:SetPoint('LEFT', patreonButton, 'RIGHT', 50, 0)
        kofiButton:SetScript("OnClick", function()
            Util.DisplayPopupTextbox('Buy me a Coffee', 'https://ko-fi.com/harrek')
        end)

    end
    return Ui.OptionsIntroPanel
end

function Ui.GetOptionsAddonsPanel()
    if not Ui.OptionsAddonsPanel then
        local addonsPanel = CreateFrame('Frame')
        Ui.OptionsAddonsPanel = addonsPanel

        addonsPanel.elements = {}

        for index, panel in ipairs(Data.otherAddonsInfo) do
            local title = addonsPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
            title:SetScale(1.7)
            title:SetText(panel.title)
            title:SetJustifyH('LEFT')
            if index == 1 then
                title:SetPoint('TOPLEFT', addonsPanel, 'TOPLEFT', 0, -10)
            else
                title:SetPoint('TOPLEFT', addonsPanel.elements[index - 1].text, 'BOTTOMLEFT', 0, -15)
            end
            title:SetPoint('RIGHT', addonsPanel, 'RIGHT')

            local text = addonsPanel:CreateFontString(nil, 'ARTWORK', 'GameTooltipText')
            text:SetScale(1.1)
            text:SetText(panel.text)
            text:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -5)
            text:SetPoint('RIGHT', addonsPanel, 'RIGHT', -20, 0)

            table.insert(addonsPanel.elements, { title = title, text = text })
        end
    end
    return Ui.OptionsAddonsPanel
end

function Ui.CreateOptionsElement(data, parent)
    local initializer = nil
    if data.type == "header" then
        initializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", { name = data.text })
        parent.layout:AddInitializer(initializer)
        Data.initializerList[data.key] = initializer
        return
    elseif data.type == "button" then
        local buttonData = {
            name = data.text,
            buttonText = data.content,
            buttonClick = data.func,
            tooltip = data.tooltip,
            newTagID = nil,
            gameDataFunc = nil
        }
        initializer =  Settings.CreateElementInitializer("SettingButtonControlTemplate", buttonData)
        Data.initializerList[data.key] = initializer
        parent.layout:AddInitializer(initializer)
    else
        if not Options[data.key] then Options[data.key] = data.default end
        local input = Settings.RegisterAddOnSetting(parent.category, data.key, data.key, Options, type(data.default), data.text, data.default)
        input:SetValueChangedCallback(function(setting, value)
            local settingKey = setting:GetVariable()
            if data.readOnly and Options[settingKey] ~= data.default then
                Options[settingKey] = data.default
                setting:NotifyUpdate()
            else
                local func
                for _, opt in ipairs(Data.settings) do
                    if opt.key == settingKey then
                        func = opt.func
                        break
                    end
                end
                if func then
                    if func == 'Setup' then
                        Core.ModifySettings()
                    else
                        Core.ModifySettings(func, value)
                    end
                end
            end
        end)
        if data.type == "checkbox" then
            initializer = Settings.CreateCheckbox(parent.category, input, data.tooltip)
            Data.initializerList[data.key] = initializer
        elseif data.type == "dropdown" then
            local function GetOptions()
                local container = Settings.CreateControlTextContainer()
                for _, item in ipairs(data.items) do
                    container:Add(item.value, item.text)
                end
                return container:GetData()
            end
            initializer = Settings.CreateDropdown(parent.category, input, GetOptions, data.tooltip)
            Data.initializerList[data.key] = initializer
        elseif data.type == "slider" then
            local options = Settings.CreateSliderOptions(data.min, data.max, data.step)
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, Util.FormatForDisplay);
            initializer = Settings.CreateSlider(parent.category, input, options, data.tooltip)
            Data.initializerList[data.key] = initializer
        elseif data.type == "color" then
            initializer = Settings.CreateColorSwatch(parent.category, input, data.tooltip)
            Data.initializerList[data.key] = initializer
        end
    end
    if initializer and data.parent then
        initializer:SetParentInitializer(Data.initializerList[data.parent], function() return Options[data.parent] end)
    end
end

function Ui.CreateOptionsPanel(optionsTable)
    local optionsIntroPanel = Ui.GetOptionsIntroPanel()
    local category = Settings.RegisterCanvasLayoutCategory(optionsIntroPanel, "Advanced Raid Frames");
    Settings.RegisterAddOnCategory(category)

    local defaultFramesSubcategory, defaultFramesLayout = Settings.RegisterVerticalLayoutSubcategory(category, 'Default Frames')
    Settings.RegisterAddOnCategory(defaultFramesSubcategory)
    optionsIntroPanel:HookScript('OnShow', function() Options.lastOpenedCategory = category.ID end)
    for _, data in ipairs(optionsTable) do
        Ui.CreateOptionsElement(data, { category = defaultFramesSubcategory, layout = defaultFramesLayout })
    end

    local designer = Ui.GetDesignerFrame()
    local designerSubCategory = Settings.RegisterCanvasLayoutSubcategory(category, designer, 'Designer')
    Settings.RegisterAddOnCategory(designerSubCategory)

    local addonsPanel = Ui.GetOptionsAddonsPanel()
    local addonsSubcategory = Settings.RegisterCanvasLayoutSubcategory(category, addonsPanel, 'Other Frames')
    Settings.RegisterAddOnCategory(addonsSubcategory)

    if not Options.lastCategory then Options.lastCategory = category.ID end

    SLASH_HARREKSADVANCEDRAIDFRAMES1 = "/harf"
    SlashCmdList.HARREKSADVANCEDRAIDFRAMES = function()
        Settings.OpenToCategory(Options.lastCategory)
    end

    Ui.GenerateMinimapIcon()
end