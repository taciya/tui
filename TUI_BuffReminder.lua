-- TUI missing-buff reminder: tri-state aura detection for WoW Forever.
TUI_BuffReminderDB = TUI_BuffReminderDB or {}

local function Secret(v)
    if v == nil then return false end
    if type(issecretvalue) == "function" then
        local ok, result = pcall(issecretvalue, v)
        return ok and result == true
    end
    return false
end

local function Field(obj, key)
    if obj == nil or Secret(obj) then return nil, false end
    local ok, value = pcall(function() return obj[key] end)
    if not ok or Secret(value) then return nil, false end
    return value, true
end

local function SpellInfo(identifier)
    if type(identifier) == "number" then
        local name
        if C_Spell and C_Spell.GetSpellName then
            local ok, value = pcall(C_Spell.GetSpellName, identifier)
            if ok and not Secret(value) then name = value end
        end
        if not name and GetSpellInfo then
            local ok, value = pcall(GetSpellInfo, identifier)
            if ok and not Secret(value) then name = value end
        end
        return identifier, name
    end

    local name = tostring(identifier or ""):match("^%s*(.-)%s*$")
    if name == "" then return nil, nil end
    local id
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, name)
        if ok and info and not Secret(info) then
            local value, readable = Field(info, "spellID")
            if readable and type(value) == "number" then id = value end
            local localized, nameReadable = Field(info, "name")
            if nameReadable and type(localized) == "string" then name = localized end
        end
    end
    if not id and GetSpellInfo then
        local ok, localized, _, _, _, _, spellID = pcall(GetSpellInfo, name)
        if ok then
            if type(localized) == "string" then name = localized end
            if type(spellID) == "number" then id = spellID end
        end
    end
    return id, name
end

local function Normalize(raw)
    if type(raw) == "string" then
        local id = tonumber(raw)
        if id then
            local _, name = SpellInfo(id)
            return { spellID = id, name = name or raw }
        end
        return { name = raw }
    end
    if type(raw) ~= "table" then return nil end
    local id = tonumber(raw.spellID)
    local name = type(raw.name) == "string" and raw.name or nil
    if not id and not name then return nil end
    return { spellID = id, name = name }
end

local function Entries()
    local result = {}
    for key, raw in pairs(TUI_BuffReminderDB) do
        local entry = Normalize(raw)
        if entry then
            entry.key = tostring(key)
            result[#result + 1] = entry
        end
    end
    table.sort(result, function(a, b)
        return string.lower(a.name or tostring(a.spellID)) < string.lower(b.name or tostring(b.spellID))
    end)
    return result
end

local function KeyFor(id, name)
    return id and tostring(id) or ("name:" .. string.lower(name))
end

local Reminder = { states = {}, durations = {}, expirations = {}, tokens = {} }

local function ReadByID(id)
    if not id or not C_UnitAuras then return nil, false, false end
    local api = C_UnitAuras.GetPlayerAuraBySpellID or C_UnitAuras.GetAuraDataBySpellID
    if type(api) ~= "function" then return nil, false, false end
    if C_Secrets and type(C_Secrets.ShouldSpellAuraBeSecret) == "function" then
        local ok, secret = pcall(C_Secrets.ShouldSpellAuraBeSecret, id)
        if ok and (Secret(secret) or secret == true) then return nil, true, true end
    end
    local ok, aura = pcall(api, id)
    if not ok or Secret(aura) then return nil, true, true end
    return aura, true, false
end

local function ReadByNameModern(name)
    if not name or not C_UnitAuras then return nil, false, false end
    local supported, unknown = false, false
    if type(C_UnitAuras.GetAuraDataBySpellName) == "function" then
        supported = true
        local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", name, "HELPFUL")
        if not ok or Secret(aura) then unknown = true
        elseif aura then return aura, true, false end
    end
    if type(C_UnitAuras.GetAuraDataByIndex) == "function" then
        supported = true
        local complete = false
        for i = 1, 255 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not ok then unknown = true; break end
            if aura == nil and not Secret(aura) then complete = true; break end
            if Secret(aura) then
                unknown = true
            else
                local auraName, readable = Field(aura, "name")
                if readable and auraName == name then return aura, true, false end
                if not readable then unknown = true end
            end
        end
        if not complete then unknown = true end
    end
    return nil, supported, unknown, complete
end

local function ReadByNameLegacy(name)
    if not name or type(UnitAura) ~= "function" then return nil, false, false end
    local unknown = false
    for i = 1, 255 do
        local values = { pcall(UnitAura, "player", i, "HELPFUL") }
        if not values[1] then return nil, true, true end
        local auraName = values[2]
        if auraName == nil and not Secret(auraName) then return nil, true, unknown, true end
        if Secret(auraName) then
            unknown = true
        elseif auraName == name then
            return { name = auraName, duration = values[5], expirationTime = values[6] }, true, false
        end
    end
    return nil, true, true
end

local function ReadAura(entry)
    local supported, unknown = false, false
    local idReliableAbsent = false
    if entry.spellID then
        local aura, idOK, uncertain = ReadByID(entry.spellID)
        supported, unknown = supported or idOK, unknown or uncertain
        if aura then return "PRESENT", aura end
        idReliableAbsent = idOK and not uncertain
    end

    local modern, modernOK, modernUnknown, modernComplete = ReadByNameModern(entry.name)
    supported, unknown = supported or modernOK, unknown or modernUnknown
    if modern then return "PRESENT", modern end

    local legacy, legacyOK, legacyUnknown, legacyComplete = ReadByNameLegacy(entry.name)
    supported, unknown = supported or legacyOK, unknown or legacyUnknown
    if legacy then return "PRESENT", legacy end

    if unknown or not supported then return "UNKNOWN" end
    if modernComplete or legacyComplete or idReliableAbsent then return "MISSING" end
    return "UNKNOWN"
end

local function AlertFrame()
    if Reminder.alert then return Reminder.alert end
    local f = CreateFrame("Frame", "TUI_BuffReminderAlert", UIParent)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetSize(900, 100)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    f:Hide()
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    fs:SetPoint("CENTER")
    fs:SetWidth(880)
    fs:SetJustifyH("CENTER")
    fs:SetTextColor(1, 0.12, 0.08, 1)
    f.text = fs
    Reminder.alert = f
    return f
end

local function RefreshAlert()
    local missing = {}
    for _, entry in ipairs(Entries()) do
        if Reminder.states[entry.key] == "MISSING" then
            missing[#missing + 1] = entry.name or ("法术 " .. tostring(entry.spellID))
        end
    end
    local f = AlertFrame()
    if #missing == 0 then f:Hide(); return end
    f.text:SetText("|cffff3333缺少效果：|r" .. table.concat(missing, "、"))
    f:Show()
end

local function ScheduleExpiry(entry, expiration)
    if not expiration or not C_Timer or not C_Timer.After then return end
    local token = (Reminder.tokens[entry.key] or 0) + 1
    Reminder.tokens[entry.key] = token
    C_Timer.After(math.max(0, expiration - GetTime()) + 0.8, function()
        if Reminder.tokens[entry.key] == token then Reminder.CheckEntry(entry) end
    end)
end

local function LearnAura(entry, aura)
    local duration, durationOK = Field(aura, "duration")
    local expiration, expirationOK = Field(aura, "expirationTime")
    if expirationOK and type(expiration) == "number" and expiration > 0 then
        Reminder.expirations[entry.key] = expiration
        if durationOK and type(duration) == "number" and duration > 0 then
            Reminder.durations[entry.key] = duration
        elseif not durationOK then
            local inferred = expiration - GetTime()
            if inferred > 0 then Reminder.durations[entry.key] = inferred end
        end
        ScheduleExpiry(entry, expiration)
    else
        Reminder.expirations[entry.key] = nil
    end
end

function Reminder.CheckEntry(entry)
    local state, aura = ReadAura(entry)
    local previous = Reminder.states[entry.key]
    if state == "PRESENT" then
        Reminder.states[entry.key] = state
        LearnAura(entry, aura)
    elseif state == "MISSING" then
        Reminder.states[entry.key] = state
        Reminder.expirations[entry.key] = nil
    else
        -- Unknown/secret data is not absence. Keep the last confirmed state;
        -- a previously learned expiration may confirm expiry after a grace period.
        local expiry = Reminder.expirations[entry.key]
        if previous == "PRESENT" and expiry and GetTime() >= expiry + 0.8 then
            Reminder.states[entry.key] = "MISSING"
        end
    end
    RefreshAlert()
end

function Reminder.CheckAll()
    for _, entry in ipairs(Entries()) do Reminder.CheckEntry(entry) end
    RefreshAlert()
end

local function HandleCast(spellID)
    if type(spellID) ~= "number" then return end
    local now = GetTime()
    for _, entry in ipairs(Entries()) do
        if entry.spellID == spellID then
            local duration = Reminder.durations[entry.key]
            if duration and duration > 0 then
                local expiry = now + duration
                Reminder.expirations[entry.key] = expiry
                Reminder.states[entry.key] = "PRESENT"
                ScheduleExpiry(entry, expiry)
            end
        end
    end
    RefreshAlert()
end

local function OnEvent(_, event, ...)
    if event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then Reminder.CheckAll() end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" then HandleCast(spellID) end
    elseif event == "PLAYER_DEAD" then
        for _, entry in ipairs(Entries()) do
            Reminder.states[entry.key] = "UNKNOWN"
            Reminder.expirations[entry.key] = nil
        end
        RefreshAlert()
    else
        Reminder.CheckAll()
    end
end

local function Print(msg)
    if TUI and TUI.Print then TUI:Print(msg)
    elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("TUI: " .. tostring(msg)) end
end

local function Add(argument)
    local numeric = tonumber(argument)
    local id, name
    if numeric then
        id, name = SpellInfo(numeric)
        name = name or ("法术 " .. tostring(numeric))
    else
        id, name = SpellInfo(argument)
    end
    if not name or name == "" then Print("无法识别法术，请输入法术名称或 ID"); return end
    local key = KeyFor(id, name)
    if TUI_BuffReminderDB[key] then Print(name .. " 已在监控列表中"); return end
    TUI_BuffReminderDB[key] = { spellID = id, name = name }
    Reminder.states[key] = "UNKNOWN"
    Print("已添加：" .. name .. (id and (" (ID:" .. id .. ")") or ""))
    Reminder.CheckAll()
end

local function Delete(argument)
    local numeric = tonumber(argument)
    local _, resolved = SpellInfo(argument)
    local target = string.lower(resolved or argument)
    local count = 0
    for key, raw in pairs(TUI_BuffReminderDB) do
        local entry = Normalize(raw)
        if entry and ((numeric and entry.spellID == numeric)
            or (entry.name and string.lower(entry.name) == target)) then
            TUI_BuffReminderDB[key] = nil
            Reminder.states[key], Reminder.expirations[key] = nil, nil
            Reminder.tokens[key] = (Reminder.tokens[key] or 0) + 1
            count = count + 1
        end
    end
    Print(count > 0 and ("已删除 " .. count .. " 项") or "未找到该监控项")
    RefreshAlert()
end

local function Command(message)
    local cmd, arg = tostring(message or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = string.lower(cmd or "")
    if cmd == "add" and arg ~= "" then
        Add(arg)
    elseif (cmd == "del" or cmd == "remove") and arg ~= "" then
        Delete(arg)
    elseif cmd == "list" then
        local entries = Entries()
        if #entries == 0 then Print("监控列表为空")
        else
            Print("缺失效果监控列表：")
            for _, e in ipairs(entries) do
                Print(string.format("%s | ID:%s | %s", e.name or "未知", tostring(e.spellID or "-"), Reminder.states[e.key] or "UNKNOWN"))
            end
        end
    elseif cmd == "clear" then
        TUI_BuffReminderDB = {}
        Reminder.states, Reminder.expirations, Reminder.tokens = {}, {}, {}
        RefreshAlert()
        Print("监控列表已清空")
    elseif cmd == "check" then
        Reminder.CheckAll()
        Print("已重新检测")
    elseif cmd == "test" then
        local f = AlertFrame()
        f.text:SetText("|cffff3333缺少效果：闪电之盾（测试）|r")
        f:Show()
        if C_Timer and C_Timer.After then C_Timer.After(4, RefreshAlert) end
    else
        Print("用法：/tuibuff add <名称或ID> | del <名称或ID> | list | clear | check | test")
    end
end

local function Initialize()
    TUI_BuffReminderDB = TUI_BuffReminderDB or {}
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_ALIVE")
    frame:RegisterEvent("PLAYER_UNGHOST")
    frame:RegisterEvent("PLAYER_DEAD")
    frame:SetScript("OnEvent", OnEvent)
    SlashCmdList["TUIBUFF"] = Command
    SLASH_TUIBUFF1, SLASH_TUIBUFF2 = "/tuibuff", "/tbuff"
    Reminder.CheckAll()
end

if TUI and TUI.RegisterModule then
    TUI:RegisterModule("BuffReminder", Initialize)
else
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("PLAYER_LOGIN")
    loader:SetScript("OnEvent", function(self)
        Initialize()
        self:UnregisterEvent("PLAYER_LOGIN")
    end)
end
