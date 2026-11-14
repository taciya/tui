-- TUI shared debug service. Lua 5.1 compatible; bounded in-memory ring buffer.
TUI = TUI or {}
TUI.Debug = TUI.Debug or {}
local Debug = TUI.Debug
Debug.capacity = Debug.capacity or 500
Debug.enabled = Debug.enabled or false
Debug.moduleFilters = Debug.moduleFilters or {}
Debug.entries = Debug.entries or {}
Debug.modules = Debug.modules or {}
Debug.nextID = Debug.nextID or 0

local function stringify(value)
    if value == nil then return "nil" end
    if type(value) == "table" then
        local out = {}
        for k, v in pairs(value) do
            out[#out + 1] = tostring(k) .. "=" .. tostring(v)
        end
        table.sort(out)
        return "{" .. table.concat(out, ", ") .. "}"
    end
    return tostring(value)
end

function Debug:RegisterModule(name, provider)
    if type(name) ~= "string" or name == "" then return false end
    self.modules[name] = type(provider) == "table" and provider or {}
    self:Log(name, "INFO", "debug module registered")
    return true
end

function Debug:UnregisterModule(name)
    self.modules[name] = nil
end

function Debug:SetEnabled(enabled, moduleName)
    if moduleName and moduleName ~= "" then
        self.moduleFilters[moduleName] = enabled and true or nil
    else
        self.enabled = enabled and true or false
    end
    return true
end

function Debug:Log(moduleName, level, message, data)
    moduleName = tostring(moduleName or "TUI")
    level = string.upper(tostring(level or "INFO"))
    if not self.enabled and not self.moduleFilters[moduleName] and level ~= "ERROR" then return false end
    self.nextID = self.nextID + 1
    local stamp = (type(date) == "function" and date("%H:%M:%S")) or "time?"
    local details = data ~= nil and (" " .. stringify(data)) or ""
    self.entries[#self.entries + 1] = {
        id = self.nextID, time = stamp, module = moduleName,
        level = level, message = tostring(message or "") .. details
    }
    while #self.entries > self.capacity do table.remove(self.entries, 1) end
    return true
end

function Debug:Clear()
    self.entries = {}
end

function Debug:GetEntries(moduleName, minLevel)
    local result = {}
    local ranks = { TRACE = 1, DEBUG = 2, INFO = 3, EVENT = 3, WARN = 4, ERROR = 5 }
    local minimum = ranks[string.upper(minLevel or "TRACE")] or 1
    for _, entry in ipairs(self.entries) do
        if (not moduleName or moduleName == "" or moduleName == "全部" or entry.module == moduleName)
            and (ranks[entry.level] or 3) >= minimum then
            result[#result + 1] = entry
        end
    end
    return result
end

function Debug:GetStatus()
    local result = {}
    for name, provider in pairs(self.modules) do
        local status = { name = name, registered = true }
        if type(provider.GetStatus) == "function" then
            local ok, value = pcall(provider.GetStatus)
            if ok then status.data = value else status.error = tostring(value) end
        end
        result[#result + 1] = status
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end

function Debug:BuildReport(moduleName)
    local lines = { "TUI DEBUG REPORT", "Generated: " .. ((type(date) == "function" and date("%Y-%m-%d %H:%M:%S")) or "unknown"), "" }
    lines[#lines + 1] = "=== Module status ==="
    for _, status in ipairs(self:GetStatus()) do
        if not moduleName or moduleName == "" or moduleName == "全部" or status.name == moduleName then
            lines[#lines + 1] = "[" .. status.name .. "]"
            if status.error then lines[#lines + 1] = "  provider error: " .. status.error end
            if status.data then lines[#lines + 1] = "  " .. stringify(status.data) end
        end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "=== Event log ==="
    for _, entry in ipairs(self:GetEntries(moduleName)) do
        lines[#lines + 1] = string.format("%s [%s] [%s] %s", entry.time, entry.module, entry.level, entry.message)
    end
    return table.concat(lines, "\n")
end

function Debug:Open()
    if TUI_DebugCenter and TUI_DebugCenter.Toggle then TUI_DebugCenter:Toggle() end
end
