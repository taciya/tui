-- Lightweight event bus for new TUI modules; legacy frames may coexist.
TUI_Events = TUI_Events or {}
local listeners = {}
local registered = {}
local eventFrame = CreateFrame("Frame")

local function refreshEvent(event)
    local entries = listeners[event]
    if entries and #entries > 0 then
        if not registered[event] then
            eventFrame:RegisterEvent(event)
            registered[event] = true
        end
    elseif registered[event] then
        eventFrame:UnregisterEvent(event)
        registered[event] = nil
    end
end

function TUI_Events:Register(event, owner, callback)
    assert(type(event) == "string" and type(callback) == "function", "invalid event listener")
    listeners[event] = listeners[event] or {}
    table.insert(listeners[event], { owner = owner, callback = callback })
    refreshEvent(event)
end

function TUI_Events:UnregisterOwner(owner)
    for event, entries in pairs(listeners) do
        for i = #entries, 1, -1 do
            if entries[i].owner == owner then table.remove(entries, i) end
        end
        if #entries == 0 then listeners[event] = nil end
    end
    for event in pairs(registered) do refreshEvent(event) end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local entries = listeners[event]
    if not entries then return end
    for i = 1, #entries do
        local entry = entries[i]
        local ok, err = pcall(entry.callback, event, ...)
        if not ok and TUI and TUI.Error then TUI:Error("event " .. event .. ": " .. tostring(err)) end
    end
end)
