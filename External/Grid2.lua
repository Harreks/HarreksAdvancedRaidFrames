if Grid2 then
    local _, NS = ...
    local Util = NS.Util
    local Core = NS.Core

    local Grid2 = Grid2
    local HealerBuff = Grid2.statusPrototype:new("HealerBuff")
    HealerBuff.enabled = false
    HealerBuff.auras = {}

    local HealerBuffName = 'Display important buffs for healers'
    local HealerBuffIcon = 'Interface/Addons/HarreksAdvancedRaidFrames/HarreksAdvancedRaidFrames.tga'
    local HealerBuffDesc = 'The description goes here'

    function HealerBuff:OnEnable()
        self.enabled = true
    end

    function HealerBuff:OnDisable()
        self.enabled = false
        wipe(self.auras)
    end

    function HealerBuff:IsActive(unit)
        local hasBuff, aura = Core.CheckAuraStatus(unit)
        self.auras[unit] = aura
        return hasBuff
    end

    function HealerBuff:GetIcon(unit)
        local aura = self.auras[unit]
        if aura and aura.icon then
            return aura.icon
        end
    end

    function HealerBuff:GetExpirationTime(unit)
        local aura = self.auras[unit]
        if aura and aura.expirationTime then
            return aura.expirationTime
        end
    end

    function HealerBuff:GetColor()
        local color = self.dbx.color1
        return color.r, color.g, color.b, color.a
    end

    Grid2.setupFunc["HealerBuff"] = function(baseKey, dbx)
        Grid2:RegisterStatus(HealerBuff, {"color", "icon", "text"}, baseKey, dbx)
        Util.Grid2Plugin = HealerBuff
        return HealerBuff
    end

    Grid2:DbSetStatusDefaultValue("HealerBuff", {
        type = "HealerBuff",
        color1 = { r = 0, g = 1, b = 0, a = 1 }
    })

    local PrevLoadOptions = Grid2.LoadOptions
    function Grid2:LoadOptions()
        PrevLoadOptions(self)
        Grid2Options:RegisterStatusOptions("HealerBuff", "buff", nil, {
            title = HealerBuffName,
            titleIcon = HealerBuffIcon,
            titleDesc = HealerBuffDesc
        })
    end
end