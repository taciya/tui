-- Lightweight event bus shared by TUI modules.
TUI_Events = TUI_Events or {}
local listeners = {}
local registered = {}
local eventFrame = CreateFrame("Frame")

local function report(message)
    if TUI and TUI.Error then TUI:Error(message) end
end

local function refreshEvent(event)
    local entries = listeners[event]
    if entries and #entries > 0 then
        if not registered[event] then
            local ok, err = pcall(eventFrame.RegisterEvent, eventFrame, event)
            if ok then
                registered[event] = true
            else
                listeners[event] = nil
                report("无法注册事件 " .. tostring(event) .. ": " .. tostring(err))
            end
        end
    elseif registered[event] then
        pcall(eventFrame.UnregisterEvent, eventFrame, event)
        registered[event] = nil
    end
end

function TUI_Events:Register(event, owner, callback)
    assert(type(event) == "string" and event ~= "", "event name is required")
    assert(type(callback) == "function", "event callback is required")
    listeners[event] = listeners[event] or {}
    for _, entry in ipairs(listeners[event]) do
        if entry.owner == owner and entry.callback == callback then return false end
    end
    table.insert(listeners[event], { owner = owner, callback = callback })
    refreshEvent(event)
    return true
end

function TUI_Events:UnregisterOwner(owner)
    for event, entries in pairs(listeners) do
        for i = #entries, 1, -1 do
            if entries[i].owner == owner then table.remove(entries, i) end
        end
        if #entries == 0 then listeners[event] = nil end
        refreshEvent(event)
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local entries = listeners[event]
    if not entries then return end
    -- Snapshot the list so listeners may unregister safely while dispatching.
    local snapshot = {}
    for i, entry in ipairs(entries) do snapshot[i] = entry end
    for _, entry in ipairs(snapshot) do
        local ok, err = pcall(entry.callback, event, ...)
        if not ok then report("事件 " .. event .. ": " .. tostring(err)) end
    end
end)
