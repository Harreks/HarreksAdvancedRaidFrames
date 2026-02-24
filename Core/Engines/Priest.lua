local _, NS = ...
local Core = NS.Core
local Common = Core.EngineCommon

function Core.ParseDisciplinePriestBuffs(unit, updateInfo)
    return Common.NoopParser(unit, updateInfo)
end

function Core.ParseHolyPriestBuffs(unit, updateInfo)
    return Common.NoopParser(unit, updateInfo)
end
