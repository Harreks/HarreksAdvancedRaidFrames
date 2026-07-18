local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local Debug = NS.Debug
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

function Core.RegisterEngine(unitFrame, unitId)
    local unit = unitId or (unitFrame and unitFrame.unit)
    if unitFrame and unit then
        
        if InCombatLockdown() then
            Data.pendingRefresh = true
            return
        end

        Core.UnregisterEngine(unitFrame)

        local container = CreateFrame("AuraContainer", nil, unitFrame, "CustomAuraContainerTemplate")
        container:SetAllPoints(unitFrame)
        container:SetUnit(unit)
        
        local specIndicators = SavedIndicators[Data.playerSpec]
        if specIndicators then
            for i, indicator in ipairs(specIndicators) do
                local spellIds = {}
                for id, data in pairs(Data.specInfo[Data.playerSpec].auras) do
                    if data.name == indicator.Spell then
                        spellIds[id] = true
                    end
                end
                
                if next(spellIds) then
                    local button = container:AddAuraSlot("slot_" .. i, "HELPFUL", {
                        candidateFilters = {
                            includeSpellIDs = spellIds
                        },
                        initializeFrame = function(btn)
                            Ui.SetupIndicatorFrame(btn, indicator)
                        end
                    })
                end
            end
        end
        
        container:SetEnabled(true)
        unitFrame.harfContainer = container
    
    end
end

function Core.UnregisterEngine(unitFrame)
    if unitFrame then
        if unitFrame.harfContainer then
            unitFrame.harfContainer:SetEnabled(false)
            unitFrame.harfContainer:Hide()
            unitFrame.harfContainer = nil
        end
    end
end