local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--This is fairly easy, if we ever get here the unit had an echo consumed by db
--They are guaranteed to get an echoed db, and if they get a normal one it would apply first
function Core.IdentifyDreamBreaths(unit)
    local unitAuras = Data.state.auras[unit]
    local dbTable = Data.state.extras.db[unit]
    dbTable.timer = false
    dbTable.pending = false
    if #dbTable.dbs == 2 then
        unitAuras[dbTable.dbs[1]] = 'DreamBreath'
        unitAuras[dbTable.dbs[2]] = 'EchoDreamBreath'
    else
        unitAuras[dbTable.dbs[1]] = 'EchoDreamBreath'
    end
    wipe(dbTable.dbs)
    Util.UpdateIndicatorsForUnit(unit)
end

--This is a funny one, we can't tell bulwark from weapon apart from the aura or the cast because the id is divine toll
--but we can know what icon is currently replacing divine toll in your bar, so we check if you are showing shield or weapon to know what the last cast was
function Core.IdentifyHolyArmaments()
    local specData = Data.specInfo[Data.playerSpec]
    local currentIcon = C_Spell.GetSpellTexture(375576)
    --If the icon is the weapon we just casted the shield, if its the shield we just casted the weapon
    if currentIcon == specData.icons.weapon then
        return 'HolyBulwark'
    else
        return 'SacredWeapon'
    end
end

--PENDING ISSUES FOR DRUID TODO:
-- Spellqueueing Barkskin off of WildGrowth will mark the WildGrowths as Barkskins (does it?)
function Core.ParseRestorationDruidBuffs(unit, updateInfo)
    local unitAuras = Data.state.auras[unit]
    local state = Data.state
    --Convoke will apply WildGrowth, Regrowth and Rejuv with no cast events, but we can diff those using points
    if updateInfo.addedAuras and state.extras.isConvoking then
        for _, aura in ipairs(updateInfo.addedAuras) do
            if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) then
                local pointCount = #aura.points
                if pointCount == 1 then
                    unitAuras[aura.auraInstanceID] = 'Rejuvenation'
                elseif pointCount == 2 then
                    unitAuras[aura.auraInstanceID] = 'WildGrowth'
                elseif pointCount == 3 then
                    unitAuras[aura.auraInstanceID] = 'Regrowth'
                end
            end
        end
    end

    --One of the resto druid issues is separating rejuv from germ. We do that here
    for instanceId, aura in pairs(unitAuras) do
        if aura == 'Rejuvenation' then
            if Util.DoesAuraDifferBetweenFilters(unit, instanceId) then
                unitAuras[instanceId] = 'Germination'
            end
        end
    end
end

--PENDING ISSUES FOR PRES TODO:
-- Sending a flying TA and immediately dreamflying will cause the echoes from TA to get marked as dreamflight hots
-- The current dreamflight landing detecting is just a 2 seconds timer (this sucks)
function Core.ParsePreservationEvokerBuffs(unit, updateInfo)
    local unitAuras = Data.state.auras[unit]
    local currentTime = GetTime()
    local state = Data.state
    local lastCastTime = state.casts[state.lastCast]

    --Pres handles separate lists to parse db
    if not state.extras.echo then state.extras.echo = {} end
    if not state.extras.db then state.extras.db = {} end
    --If we have this unit saved as having echo beforehand we check if it was removed
    if state.extras.echo[unit] and updateInfo.removedAuraInstanceIDs then
        for _, removedAuraId in ipairs(updateInfo.removedAuraInstanceIDs) do
            --If echo was removed, we init this units table in the dbs to parse later
            if state.extras.echo[unit] == removedAuraId then
                state.extras.db[unit] = { dbs = {}, timer = false, pending = true }
                state.extras.echo[unit] = nil
                break
            end
        end
    end

    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) then
                local pointCount = #aura.points
                --This count can cause issues for auras not from casts
                if pointCount == 2 and not Util.AreTimestampsEqual(currentTime, lastCastTime) then
                    --If we are dreamflying, we assume these are dreamflight hots
                    if state.extras.dreamflight then
                        state.auras[unit][aura.auraInstanceID] = 'DreamFlight'
                    else
                        --Otherwise these have to be echoes from a flying TA
                        state.auras[unit][aura.auraInstanceID] = 'Echo'
                    end
                --If this is a dream breath
                elseif pointCount == 3 and state.lastCast == 'DreamBreath' and Util.AreTimestampsEqual(currentTime, lastCastTime) then
                    --We check if this unit is preparing to parse its dbs
                    if state.extras.db[unit] and state.extras.db[unit].pending then
                        --If this unit had its echo consumed, we insert the dbs in the table for later parsing
                        table.insert(state.extras.db[unit].dbs, aura.auraInstanceID)
                        --If we haven't already, we start a timer to check the dbs after 0.2s
                        if not state.extras.db[unit].timer then
                            C_Timer.After(0.1, function() Core.IdentifyDreamBreaths(unit) end)
                            state.extras.db[unit].timer = true
                        end
                    else
                        --If the unit is not waiting to parse then they didn't had an echo before this application, so this is a normal db
                        state.auras[unit][aura.auraInstanceID] = 'DreamBreath'
                    end
                end
            end
        end
    end

    --Gen function might put several reversions on the same unit when there is echoes
    for instanceId, aura in pairs(unitAuras) do
        if aura == 'Reversion' then
            if Util.DoesAuraDifferBetweenFilters(unit, instanceId) then
                unitAuras[instanceId] = 'EchoReversion'
            end
        elseif aura == 'Echo' and not state.extras.echo[unit] then
            state.extras.echo[unit] = instanceId
        end
    end

end

--Restoration Shaman has perfect tracking.
--But life can't be perfect. Rsham can apply earth shield to the player by casting water shield with a delay so we still need a function
function Core.ParseRestorationShamanBuffs(unit, updateInfo)
    local specInfo = Data.specInfo[Data.playerSpec]
    local unitAuras = Data.state.auras[unit]
    if UnitIsUnit(unit, 'player') then
        local missingEarthShield = true
        for _, buff in pairs(unitAuras) do
            if buff == 'EarthShield' then missingEarthShield = false end
        end
        if updateInfo.addedAuras and missingEarthShield then
            for _, aura in ipairs(updateInfo.addedAuras) do
                local pointCount = #aura.points
                if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) and pointCount == specInfo.auras['EarthShield'] then
                    unitAuras[aura.auraInstanceID] = 'EarthShield'
                end
            end
        end
    end
end

--PENDING ISUES FOR DISC TODO:
-- PI checking might be finicky, but need real world data to test (move the checking to a separate function when we work on holy)
-- Spellqueueing issue with radiance and pain sup (maybe the spellqueueing is actually widerspread than i thought? (swap to checking all casts in the time window instead?))
function Core.ParseDisciplinePriestBuffs(unit, updateInfo)
    local unitAuras = Data.state.auras[unit]
    local specData = Data.specInfo[Data.playerSpec]
    local currentTime = GetTime()
    local state = Data.state
    --We need to check for PI. It misses the initial filter because the aura is not in RAID_IN_COMBAT
    if updateInfo.addedAuras then
        local lastCastTime = state.casts[state.lastCast]
        if state.lastCast == specData.pi and Util.AreTimestampsEqual(currentTime, lastCastTime) then
            for _, aura in ipairs(updateInfo.addedAuras) do
                if Util.DoesAuraPassRaidFilter(unit, aura.auraInstanceID) and Util.DoesAuraDifferBetweenFilters(unit, aura.auraInstanceID) then
                    local pointCount = #aura.points
                    if pointCount == specData.auras.PowerInfusion then
                        unitAuras[aura.auraInstanceID] = 'PowerInfusion'
                    end
                end
            end
        end
    end
end

--PENDING ISSUES FOR HPAL TODO:
-- Armaments is wonky because of the travel time, i expect to see errors when you cast both charges back to back
function Core.ParseHolyPaladinBuffs(unit, updateInfo)
    local unitAuras = Data.state.auras[unit]
    local specData = Data.specInfo[Data.playerSpec]
    local currentTime = GetTime()
    local isPlayer = UnitIsUnit(unit, 'player')
    local state = Data.state

    local playerArmamentBuffs = {}
    --If this is the player, we save the armament buffs of to check if they were recently added down below
    if isPlayer then
        for instanceId, buff in pairs(unitAuras) do
            if buff == 'HolyBulwark' or buff == 'SacredWeapon' then
                table.insert(playerArmamentBuffs, instanceId)
            end
        end
    end

    if updateInfo.addedAuras then
        local lastCastTime = state.casts[state.lastCast]
        for _, aura in ipairs(updateInfo.addedAuras) do
            local pointCount = #aura.points
            --Same as PI, virtue gets lost in the initial filter because its not in raid in combat
            if state.lastCast == specData.virtue and Util.AreTimestampsEqual(currentTime, lastCastTime)
            and Util.DoesAuraPassRaidFilter(unit, aura.auraInstanceID) and Util.DoesAuraDifferBetweenFilters(unit, aura.auraInstanceID) then
                if pointCount == specData.auras.BeaconOfVirtue then
                    unitAuras[aura.auraInstanceID] = 'BeaconOfVirtue'
                end
            end
            if state.lastCast == specData.armaments and not isPlayer and Util.AreTimestampsEqual(currentTime, lastCastTime, 2) then --2 seconds is insanity wtf
                if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) and pointCount == specData.auras.SacredWeapon then --both arms have the same count
                    unitAuras[aura.auraInstanceID] = Core.IdentifyHolyArmaments()
                end
            end
            --If the player has armaments, check if they were added in this run by the gen function, if they were confirm they are correctly marked
            if isPlayer and #playerArmamentBuffs > 0 then
                for _, instanceId in pairs(playerArmamentBuffs) do
                    if aura.auraInstanceID == instanceId then
                        unitAuras[instanceId] = Core.IdentifyHolyArmaments()
                    end
                end
            end
            --Other buffs that got all the way here and have 7 points have to be beacon of the savior
            if pointCount == 7 and not unitAuras[aura.auraInstanceID] then
                unitAuras[aura.auraInstanceID] = 'BeaconOfTheSavior'
            end
        end
    end
end

--PENDING ISSUES FOR MW TODO:
-- Soom is a bit fucked. I can currently tell when you are sooming very well but i need to look deep into event ordering and timestamps to keep the sooms in the correct targets when you envm
function Core.ParseMistweaverMonkBuffs(unit, updateInfo)
    local specInfo = Data.specInfo[Data.playerSpec]
    local unitAuras = Data.state.auras[unit]
    local state = Data.state
    local currentTime = GetTime()
    local lastCastTime = state.casts[state.lastCast]
    local aspectOfHarmony = false
    if state.extras.moh then
        --Aspect of harmony can have travel time (this might fuck up rems that jump during the 1s after a vivify or sheiluns casts, def need to revisit)
        if Util.AreTimestampsEqual(currentTime, state.casts[116670], 1) or Util.AreTimestampsEqual(currentTime, state.casts[399491], 1) then
            aspectOfHarmony = true
        end
    end

    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) then
                local pointCount = #aura.points
                --Cocoon requires special checks if you have mists of life
                if state.lastCast == 'LifeCocoon' and Util.AreTimestampsEqual(currentTime, lastCastTime) and pointCount == 3 then
                    if Util.IsExternalDefensive(unit, aura.auraInstanceID) then
                        unitAuras[aura.auraInstanceID] = 'LifeCocoon'
                    else
                        unitAuras[aura.auraInstanceID] = 'EnvelopingMist'
                    end
                end
                if aspectOfHarmony and not unitAuras[aura.auraInstanceID] and pointCount == specInfo.auras.AspectOfHarmony then
                    unitAuras[aura.auraInstanceID] = 'AspectOfHarmony'
                end
                --Randomly applied shit with no cast is either rems jumping or envms spawned by rem (mists of life rem would also be caught here)
                if not unitAuras[aura.auraInstanceID] then
                    if pointCount == specInfo.auras.RenewingMist then
                        unitAuras[aura.auraInstanceID] = 'RenewingMist'
                    else
                        unitAuras[aura.auraInstanceID] = 'EnvelopingMist'
                    end
                end
            end
        end
    end
end

--PENDING ISSUES FOR AUG TODO:
-- Theres potentially some spellqueueing issues here with empower into blistering scales or ebonmight into pres, but some will improve massively with the fitler data rework so *shrug*
function Core.ParseAugmentationEvokerBuffs(unit, updateInfo)
    local unitAuras = Data.state.auras[unit]
    --Only random auras are the ones from motes or blossom
    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) and not unitAuras[aura.auraInstanceID] then
                local pointCount = #aura.points
                if pointCount == 3 then
                    unitAuras[aura.auraInstanceID] = 'Prescience'
                elseif pointCount == 2 then
                    unitAuras[aura.auraInstanceID] = 'ShiftingSands'
                elseif pointCount == 1 then
                    unitAuras[aura.auraInstanceID] = 'SymbioticBloom'
                elseif pointCount == 0 then
                    unitAuras[aura.auraInstanceID] = 'InfernosBlessing'
                end
            end
        end
    end
end

--Check data of UNIT_AURA to update its status
function Core.UpdateAuraStatus(unit, updateInfo)
    local specInfo = Data.specInfo[Data.playerSpec]
    local currentTime = GetTime()
    local state = Data.state
    if not state.auras[unit] then state.auras[unit] = {} end
    if not updateInfo then updateInfo = {} end

    --If an auraInstanceID that we have saved has been removed, get it away
    if updateInfo.removedAuraInstanceIDs then
        local currentUnitAuras = state.auras[unit]
        if currentUnitAuras then
            for _, auraId in ipairs(updateInfo.removedAuraInstanceIDs) do
                if currentUnitAuras[auraId] then
                    currentUnitAuras[auraId] = nil
                end
            end
        end
    end

    --If the unit got new auras added, check if they came from a cast
    if updateInfo.addedAuras then
        local lastCastTime = state.casts[state.lastCast]
        --If these auras match a spell cast
        if lastCastTime and Util.AreTimestampsEqual(currentTime, lastCastTime) then
            --Get the buffs this cast can apply
            local castBuffs = specInfo.casts[state.lastCast]
            if castBuffs then
                for _, aura in ipairs(updateInfo.addedAuras) do
                    if Util.IsAuraFromPlayer(unit, aura.auraInstanceID)  then
                        local pointCount = #aura.points
                        for _, buff in ipairs(castBuffs) do
                            if pointCount == specInfo.auras[buff] then
                                state.auras[unit][aura.auraInstanceID] = buff
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    --We pass the data to specialized functions
    local engineFunction = Data.engineFunctions[Data.playerSpec]
    if engineFunction then
        engineFunction(unit, updateInfo)
    end

    --Hit a refresh of the indicators at the end
    Util.UpdateIndicatorsForUnit(unit)
end