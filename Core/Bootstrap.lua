-- TUI Core bootstrap. Loaded before feature files.
TUI = TUI or {}
TUI.version = "2.2.1"
TUI.modules = TUI.modules or {}
TUI._moduleOrder = TUI._moduleOrder or {}
TUI.initialized = TUI.initialized or false

function TUI:RegisterModule(name, initializer)
    assert(type(name) == "string" and name ~= "", "TUI module name is required")
    assert(type(initializer) == "function", "TUI module initializer must be a function")
    if self.modules[name] then
        return false, "duplicate module: " .. name
    end
    self.modules[name] = initializer
    table.insert(self._moduleOrder, name)
    if self.initialized then
        local ok, err = pcall(initializer, self)
        if not ok then self:Error("module " .. name .. " failed: " .. tostring(err)) end
    end
    return true
end

function TUI:Print(message)
    local frame = DEFAULT_CHAT_FRAME
    if frame and frame.AddMessage then
        frame:AddMessage("|cff33ccffTUI|r: " .. tostring(message))
    end
end

function TUI:Error(message)
    self:Print("|cffff5555" .. tostring(message) .. "|r")
end

local function packResults(...)
    return { n = select("#", ...), ... }
end

function TUI:SafeCall(label, callback, ...)
    if type(callback) ~= "function" then return false, "callback is not a function" end
    local results = packResults(pcall(callback, ...))
    if not results[1] then
        self:Error((label or "operation") .. ": " .. tostring(results[2]))
        return false, results[2]
    end
    return true, unpack(results, 2, results.n)
end

function TUI:InitializeModules()
    if self.initialized then return end
    self.initialized = true
    for _, name in ipairs(self._moduleOrder) do
        local initializer = self.modules[name]
        if initializer then
            local ok, err = pcall(initializer, self)
            if not ok then self:Error("module " .. name .. " failed: " .. tostring(err)) end
        end
    end
end

local bootstrap = CreateFrame("Frame")
bootstrap:RegisterEvent("PLAYER_LOGIN")
bootstrap:SetScript("OnEvent", function(self)
    TUI:InitializeModules()
    self:UnregisterEvent("PLAYER_LOGIN")
end)
