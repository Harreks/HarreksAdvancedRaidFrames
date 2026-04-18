local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local Debug = NS.Debug
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--This is deprecated
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

        local introText = optionsIntroPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
        introText:SetPoint('TOP', logo, 'BOTTOM', 0, -20)
        introText:SetWidth(400)
        introText:SetJustifyH('CENTER')
        introText:SetScale(1.15)
        introText:SetWordWrap(true)
        local text = [[Advanced Raid Frames is a simple and straightforward way to enhance your party and raid frames. The main focus is functionality and the goal is to avoid all the fluff and the need to navigate through a lot of different menus. You should find it incredibly simple to set up but still powerful enough to do anything you might need to properly play the game.

If you have any questions, feedback, or bug reports please come by the SpiritbloomPro discord and let me know. The project is constantly evolving and improving and that is made possible thanks to you.

-Harrek

|cFFFFFFFFTo open the designer directly, use the command|r /harf des]]
        introText:SetText(text)
        optionsIntroPanel.text = introText

        optionsIntroPanel.buttons = {}
        local patreonButton = CreateFrame("Button", nil, optionsIntroPanel, "UIPanelButtonTemplate")
        patreonButton:SetSize(120, 30)
        patreonButton:SetText('Patreon')
        patreonButton:SetPoint('BOTTOM', optionsIntroPanel, 'BOTTOM', 0, 50)
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

function Ui.CreateOptions()
    local settingsTable = CopyTable(Data.settings)
    for _, data in ipairs(settingsTable) do
        if data.func and type(data.func) == 'string' then
            if data.func ~= 'Setup' then
                data.funcArgs = { functionToRun = data.func }
            end
            data.func = Core.ModifySettings
        end
    end

    local LAMB = NS.LibAdvancedMenuBuilder
    local HAUS = HarreksAdvancedUiSuite
    local parent = HAUS and HAUS.settingsCategory or nil
    local category = LAMB.CreateOptionsPanel(settingsTable, Options, 'Advanced Raid Frames ' .. NS.Version, 'vertical', parent)
    local designer = Ui.GetDesignerFrame()
    local designerCategory = LAMB.CreateOptionsPanel(designer, nil, 'Designer', 'canvas', category)

    --If the container exists, register harf as a component
    if HAUS and HAUS.RegisterComponent and type(HAUS.RegisterComponent) == 'function' then
        HAUS.RegisterComponent('HarreksAdvancedRaidFrames', NS.Version, category.ID)
    end

    Data.addonSettingsCategory = category.ID
    SLASH_HARREKSADVANCEDRAIDFRAMES1 = "/harf"
    SlashCmdList.HARREKSADVANCEDRAIDFRAMES = function(msg)
        if InCombatLockdown() then
            print('|cnNORMAL_FONT_COLOR:AdvancedRaidFrames:|r Settings can\'t be opened in combat.')
        else
            if msg ~= '' then
                if msg == 'des' then
                    Settings.OpenToCategory(designerCategory.ID)
                elseif msg == 'reset' then
                    Util.DisplayResetPopup()
                end
            else
                Settings.OpenToCategory(category.ID)
            end
        end
    end
end

function AdvancedRaidFrames_CompartmentClick()
    if Data.addonSettingsCategory then
        Settings.OpenToCategory(Data.addonSettingsCategory)
    end
end