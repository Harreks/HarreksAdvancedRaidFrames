local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local L = NS.L
local Options = HARFDB.options

function Ui.GenerateMinimapIcon(categoryId)
    local HarfLDB = LibStub("LibDataBroker-1.1"):NewDataObject("HARF", {
        type = 'data source',
        text = 'Harrek\'s Advanced Raid Frames',
        icon = 'Interface/Addons/HarreksAdvancedRaidFrames/Assets/harrek-logo.png',
        OnClick = function() Settings.OpenToCategory(categoryId) end
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
        title:SetText(string.format(L.MENU_INTRO_TITLE_FMT, NS.Version))

        local logo = optionsIntroPanel:CreateTexture(nil, "ARTWORK")
        logo:SetTexture('Interface/Addons/HarreksAdvancedRaidFrames/Assets/harrek-logo.png')
        logo:SetSize(100, 100)
        logo:SetPoint('TOP', title, 'TOP', 0, -30)
        optionsIntroPanel.logo = logo

        local fontString = optionsIntroPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
        fontString:SetPoint('TOP', logo, 'BOTTOM', 0, -10)
        fontString:SetPoint('LEFT', optionsIntroPanel, 'LEFT', 24, 0)
        fontString:SetPoint('RIGHT', optionsIntroPanel, 'RIGHT', -24, 0)
        fontString:SetJustifyH('CENTER')
        fontString:SetScale(1.15)
        fontString:SetWordWrap(true)
        local text = L.MENU_INTRO_BODY
        fontString:SetText(text)
        optionsIntroPanel.text = fontString

        optionsIntroPanel.buttons = {}
        local patreonButton = CreateFrame("Button", nil, optionsIntroPanel, "UIPanelButtonTemplate")
        patreonButton:SetSize(120, 30)
        patreonButton:SetText(L.MENU_BUTTON_PATREON)
        patreonButton:SetPoint('TOP', fontString, 'BOTTOM', 0, -20)
        patreonButton:SetScript("OnClick", function()
            Util.DisplayPopupTextbox(L.MENU_POPUP_PATREON_TITLE, 'https://www.patreon.com/cw/harrek')
        end)
        optionsIntroPanel.buttons.Patreon = patreonButton

        local discordButton = CreateFrame("Button", nil, optionsIntroPanel, "UIPanelButtonTemplate")
        discordButton:SetSize(120, 30)
        discordButton:SetText(L.MENU_BUTTON_DISCORD)
        discordButton:SetPoint('RIGHT', patreonButton, 'LEFT', -50, 0)
        discordButton:SetScript("OnClick", function()
            Util.DisplayPopupTextbox(L.MENU_POPUP_DISCORD_TITLE, 'https://discord.gg/MMjNrUTxQe')
        end)

        local kofiButton = CreateFrame("Button", nil, optionsIntroPanel, "UIPanelButtonTemplate")
        kofiButton:SetSize(120, 30)
        kofiButton:SetText(L.MENU_BUTTON_KOFI)
        kofiButton:SetPoint('LEFT', patreonButton, 'RIGHT', 50, 0)
        kofiButton:SetScript("OnClick", function()
            Util.DisplayPopupTextbox(L.MENU_POPUP_KOFI_TITLE, 'https://ko-fi.com/harrek')
        end)

    end
    return Ui.OptionsIntroPanel
end

function Ui.CreateOptionsElement(data, parent)
    local initializer = nil
    if data.type == "header" then
        initializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", { name = data.text })
        parent.layout:AddInitializer(initializer)
        Data.initializerList[data.key] = initializer
        return
    elseif data.type == "button" then
        local buttonClick = data.func
        if type(buttonClick) == 'string' then
            local functionName = buttonClick
            buttonClick = function()
                local resolvedFunc = Core[functionName]
                if type(resolvedFunc) == 'function' then
                    resolvedFunc()
                end
            end
        end

        local buttonData = {
            name = data.text,
            buttonText = data.content,
            buttonClick = buttonClick,
            OnButtonClick = buttonClick,
            click = buttonClick,
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
    local category = Settings.RegisterCanvasLayoutCategory(optionsIntroPanel, L.MENU_CATEGORY_ADDON)
    Settings.RegisterAddOnCategory(category)

    local defaultFramesSubcategory, defaultFramesLayout = Settings.RegisterVerticalLayoutSubcategory(category, L.MENU_CATEGORY_DEFAULT_FRAMES)
    Settings.RegisterAddOnCategory(defaultFramesSubcategory)

    optionsIntroPanel:HookScript('OnShow', function() Options.lastOpenedCategory = category.ID end)
    for _, data in ipairs(optionsTable) do
        Ui.CreateOptionsElement(data, { category = defaultFramesSubcategory, layout = defaultFramesLayout })
    end

    Ui.CreateDesignerCategory(category)

    SLASH_HARREKSADVANCEDRAIDFRAMES1 = "/harf"
    SlashCmdList.HARREKSADVANCEDRAIDFRAMES = function()
        Settings.OpenToCategory(category.ID)
    end

    Ui.GenerateMinimapIcon(category.ID)
end