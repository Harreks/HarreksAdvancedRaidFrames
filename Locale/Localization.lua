local _, NS = ...

local activeLocale = GetLocale and GetLocale() or 'enUS'
local L = NS.L or {}
NS.L = L

setmetatable(L, {
    __index = function(_, key)
        return key
    end
})

function NS.GetLocaleTable(locale, isDefault)
    if isDefault or locale == activeLocale then
        return L
    end
    return nil
end

NS.ActiveLocale = activeLocale
