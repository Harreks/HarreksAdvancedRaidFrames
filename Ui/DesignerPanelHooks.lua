local _, NS = ...
local Ui = NS.Ui

Ui.DesignerPanelHooks = Ui.DesignerPanelHooks or {
    callbacks = {
        show = {},
        hide = {},
        tick = {},
    },
    elapsed = 0,
}

local DesignerPanelHooks = Ui.DesignerPanelHooks

local function registerCallback(eventType, callback)
    if type(callback) ~= 'function' then
        return
    end

    local eventCallbacks = DesignerPanelHooks.callbacks[eventType]
    if not eventCallbacks then
        return
    end

    for _, existing in ipairs(eventCallbacks) do
        if existing == callback then
            return
        end
    end

    table.insert(eventCallbacks, callback)
end

local function runCallbacks(eventType, elapsed)
    local eventCallbacks = DesignerPanelHooks.callbacks[eventType]
    if not eventCallbacks then
        return
    end

    for _, callback in ipairs(eventCallbacks) do
        callback(elapsed)
    end
end

function Ui.RegisterDesignerPanelHook(eventType, callback)
    registerCallback(eventType, callback)

    if SettingsPanel and not DesignerPanelHooks.initialized then
        SettingsPanel:HookScript('OnShow', function()
            runCallbacks('show')
        end)

        SettingsPanel:HookScript('OnHide', function()
            runCallbacks('hide')
        end)

        SettingsPanel:HookScript('OnUpdate', function(_, elapsed)
            DesignerPanelHooks.elapsed = (DesignerPanelHooks.elapsed or 0) + elapsed
            if DesignerPanelHooks.elapsed >= 0.25 then
                local throttledElapsed = DesignerPanelHooks.elapsed
                DesignerPanelHooks.elapsed = 0
                runCallbacks('tick', throttledElapsed)
            end
        end)

        DesignerPanelHooks.initialized = true
    end
end
