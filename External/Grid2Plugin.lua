if Grid2 then
    local _, NS = ...
    local Data = NS.Data
    local Ui = NS.Ui
    local Util = NS.Util
    local Core = NS.Core

    local Grid2 = Grid2
    local order = 1
    local pluginData = {}
    for spec, specInfo in pairs(Data.specInfo) do
        local categoryData = { name = spec, dataTable = { name = spec, column = 10, order = order }, statuses = {} }
        order = order + 1
        for spell, _ in pairs(specInfo.auras) do
            local status = Grid2.statusPrototype:new(spell)
            status.enabled = false
            status.auras = {}
            status.name = spell
            status.icon = Data.textures[spell]

            function status:OnEnable()
                self.enabled = true
            end

            function status:OnDisable()
                self.enabled = false
                wipe(self.auras)
            end

            function status:IsActive(unit)
                local unitList = Util.GetRelevantList()
                local unitElements = unitList[unit]
                if unitElements and unitElements.auras then
                    local auraData = unitElements.auras[spell]
                    self.auras[unit] = auraData
                    if auraData then
                        return true
                    end
                end
                return false
            end

            function status:GetIcon(unit)
                local aura = self.auras[unit]
                if aura and aura.icon then
                    return aura.icon
                end
            end

            function status:GetBorder()
                return 0
            end

            function status:GetDuration(unit)
                local aura = self.auras[unit]
                if aura and aura.auraInstanceID then
                    local duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                    return duration:GetTotalDuration()
                end
            end

            function status:GetExpirationTime(unit)
                local aura = self.auras[unit]
                if aura and aura.auraInstanceID then
                    local duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                    return duration:GetEndTime()
                end
            end

            function status:GetColor()
                local color = self.dbx.color1
                return color.r, color.g, color.b, color.a
            end

            hooksecurefunc(Util, "UpdateIndicatorsForUnit", function(unit)
            if status.enabled and unit then
                status:UpdateIndicators(unit)
            end
        end)

            Grid2.setupFunc[spell] = function(baseKey, dbx)
                Grid2:RegisterStatus(status, {"color", "icon", "text", "bar"}, baseKey, dbx)
                return status
            end

            Grid2:DbSetStatusDefaultValue(spell, {
                type = spell,
                color1 = { r = 0, g = 1, b = 0, a = 1 }
            })

            table.insert(categoryData.statuses, status)
        end

        table.insert(pluginData, categoryData)
    end

    local PrevLoadOptions = Grid2.LoadOptions
    function Grid2:LoadOptions()
        PrevLoadOptions(self)
        if not Grid2Options then
            return
        end
        for _, category in ipairs(pluginData) do
            Grid2Options:RegisterStatusCategory(category.name, category.dataTable)
            for _, status in ipairs(category.statuses) do
                Grid2Options:RegisterStatusOptions(status.name, category.name, nil, {
                    title = 'Options for ' .. status.name,
                    titleIcon = status.icon
                })
            end
        end
    end
end