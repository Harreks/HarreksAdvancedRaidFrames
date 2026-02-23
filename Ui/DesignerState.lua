local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

Ui.DesignerState = Ui.DesignerState or {}
local DesignerState = Ui.DesignerState

function DesignerState.DeepCopyValue(value)
    if type(value) ~= 'table' then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = DesignerState.DeepCopyValue(entry)
    end
    return copy
end

function DesignerState.EnsureSpecIndicators(spec)
    if not SavedIndicators[spec] then
        SavedIndicators[spec] = {}
    end
    return SavedIndicators[spec]
end

function DesignerState.EnsureEditingSpec()
    if Options.editingSpec and Data.specInfo[Options.editingSpec] then
        return Options.editingSpec
    end

    for spec, _ in pairs(Data.specInfo) do
        Options.editingSpec = spec
        break
    end

    return Options.editingSpec
end

function DesignerState.GetSelectedIndicatorIndex()
    local spec = DesignerState.EnsureEditingSpec()
    local indicators = DesignerState.EnsureSpecIndicators(spec)

    if #indicators == 0 then
        Options.designerSelectedIndicatorIndex = nil
        return nil
    end

    local index = tonumber(Options.designerSelectedIndicatorIndex) or 1
    if index < 1 then
        index = 1
    elseif index > #indicators then
        index = #indicators
    end

    Options.designerSelectedIndicatorIndex = index
    return index
end
