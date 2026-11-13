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

local Reminder = { states = {}, durations = {}, expirations = {}, tokens = {}, auraInstanceSpells = {}, lastAuraInstanceSet = nil }

local function ReadByID(id)
    if not id or not C_UnitAuras then return nil, false, false end
    local api, useUnitAPI
    if type(C_UnitAuras.GetPlayerAuraBySpellID) == "function" then
        api = C_UnitAuras.GetPlayerAuraBySpellID
    elseif type(C_UnitAuras.GetUnitAuraBySpellID) == "function" then
        api, useUnitAPI = C_UnitAuras.GetUnitAuraBySpellID, true
    else
        return nil, false, false
    end
    if C_Secrets and type(C_Secrets.ShouldSpellAuraBeSecret) == "function" then
        local ok, secret = pcall(C_Secrets.ShouldSpellAuraBeSecret, id)
        if ok and (Secret(secret) or secret == true) then return nil, true, true end
    end
    local ok, aura
    if useUnitAPI then
        ok, aura = pcall(api, "player", id)
    else
        ok, aura = pcall(api, id)
    end
    if not ok or Secret(aura) then return nil, true, true end
    return aura, true, false
end

local function ReadByNameModern(name)
    if not name or not C_UnitAuras then return nil, false, false end
    local supported, unknown, complete = false, false, false
    if type(C_UnitAuras.GetAuraDataBySpellName) == "function" then
        supported = true
        local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", name, "HELPFUL")
        if not ok or Secret(aura) then unknown = true
        elseif aura then return aura, true, false end
    end
    if type(C_UnitAuras.GetAuraDataByIndex) == "function" then
        supported = true
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


-- Track aura instance IDs separately from spell IDs. UNIT_AURA removal data
-- can identify an aura disappearing even when its current AuraData is hidden.
local function EntryForSpell(spellID, name)
    for _, entry in ipairs(Entries()) do
        if (spellID and entry.spellID == spellID)
            or (name and entry.name and string.lower(entry.name) == string.lower(name)) then
            return entry
        end
    end
end

local function ReadAuraByInstanceID(instanceID)
    if not C_UnitAuras or type(C_UnitAuras.GetAuraDataByAuraInstanceID) ~= "function" then
        return nil
    end
    local ok, aura = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, "player", instanceID)
    if not ok or Secret(aura) then return nil end
    return aura
end

local function RememberAuraInstance(aura)
    if not aura or Secret(aura) then return end
    local instanceID, instanceOK = Field(aura, "auraInstanceID")
    if not instanceOK or type(instanceID) ~= "number" then return end
    local spellID, spellOK = Field(aura, "spellId")
    if not spellOK then spellID, spellOK = Field(aura, "spellID") end
    local name, nameOK = Field(aura, "name")
    if not spellOK and not nameOK then return end
    local entry = EntryForSpell(spellOK and spellID or nil, nameOK and name or nil)
    if entry then Reminder.auraInstanceSpells[instanceID] = entry.key end
end

local function SnapshotAuraInstances()
    if not C_UnitAuras or type(C_UnitAuras.GetUnitAuraInstanceIDs) ~= "function" then
        return false
    end
    local ok, ids = pcall(C_UnitAuras.GetUnitAuraInstanceIDs, "player", "HELPFUL")
    if not ok or Secret(ids) or type(ids) ~= "table" then return false end

    local current = {}
    for _, instanceID in ipairs(ids) do
        if Secret(instanceID) or type(instanceID) ~= "number" then return false end
        current[instanceID] = true
        RememberAuraInstance(ReadAuraByInstanceID(instanceID))
    end

    -- A set difference is a second source of removal information for clients
    -- that expose instance IDs but omit removedAuraInstanceIDs from updateInfo.
    if Reminder.lastAuraInstanceSet then
        for instanceID in pairs(Reminder.lastAuraInstanceSet) do
            if not current[instanceID] then
                local key = Reminder.auraInstanceSpells[instanceID]
                if key then
                    Reminder.states[key] = "MISSING"
                    Reminder.expirations[key] = nil
                    Reminder.auraInstanceSpells[instanceID] = nil
                end
            end
        end
    end
    Reminder.lastAuraInstanceSet = current
    return true
end

local function HandleAuraUpdate(updateInfo)
    if updateInfo and not Secret(updateInfo) and type(updateInfo) == "table" then
        local added = updateInfo.addedAuras
        if not Secret(added) and type(added) == "table" then
            for _, aura in ipairs(added) do RememberAuraInstance(aura) end
        end

        local removed = updateInfo.removedAuraInstanceIDs
        if not Secret(removed) and type(removed) == "table" then
            for _, instanceID in ipairs(removed) do
                if not Secret(instanceID) and type(instanceID) == "number" then
                    local key = Reminder.auraInstanceSpells[instanceID]
                    if key then
                        Reminder.states[key] = "MISSING"
                        Reminder.expirations[key] = nil
                        Reminder.auraInstanceSpells[instanceID] = nil
                    end
                end
            end
        end

        if updateInfo.isFullUpdate == true then
            -- A full update invalidates the old instance snapshot; rebuild it
            -- from the current aura collection rather than diffing stale IDs.
            Reminder.lastAuraInstanceSet = nil
        end
    end

    SnapshotAuraInstances()
    Reminder.CheckAll()
end

local function AlertFrame()
    if Reminder.alert then return Reminder.alert end
    local f = CreateFrame("Frame", "TUI_BuffReminderAlert", UIParent)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetSize(1120, 150)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 105)

    -- High-contrast dark panel with a bright warning border.
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        if f.SetBackdropColor then f:SetBackdropColor(0.12, 0.015, 0.015, 0.96) end
        if f.SetBackdropBorderColor then f:SetBackdropBorderColor(1, 0.25, 0.05, 1) end
    else
        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(f)
        bg:SetTexture(0.12, 0.015, 0.015, 0.96)
    end

    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    fs:SetPoint("CENTER", f, "CENTER", 0, 0)
    fs:SetWidth(1060)
    fs:SetJustifyH("CENTER")
    local font, _, flags = fs:GetFont()
    if font then fs:SetFont(font, 34, "THICKOUTLINE") end
    fs:SetTextColor(1, 0.88, 0.12, 1)
    if fs.SetShadowOffset then fs:SetShadowOffset(2, -2) end
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 1) end
    f.text = fs

    -- A gentle pulse draws attention without a loud sound or rapid flashing.
    f.pulseElapsed = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        if not self:IsShown() then return end
        self.pulseElapsed = self.pulseElapsed + (elapsed or 0)
        local alpha = 0.88 + 0.12 * math.sin(self.pulseElapsed * 3.5)
        self:SetAlpha(alpha)
    end)
    f:Hide()
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

    -- In combat some clients expose the aura itself but hide its timing fields.
    -- Do not erase a previously learned expiry just because those fields became
    -- secret/unreadable; the expiry timer is our fallback for combat detection.
    if durationOK and type(duration) == "number" and duration > 0 then
        Reminder.durations[entry.key] = duration
    elseif not durationOK and expirationOK and type(expiration) == "number" and expiration > GetTime() then
        local inferred = expiration - GetTime()
        if inferred > 0 then Reminder.durations[entry.key] = inferred end
    end

    if expirationOK and type(expiration) == "number" and expiration > 0 then
        Reminder.expirations[entry.key] = expiration
        ScheduleExpiry(entry, expiration)
    elseif expirationOK then
        -- A readable nil/zero expiration is a confirmed non-expiring aura.
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

local function HandleCast(eventArgs)
    local now = GetTime()
    local entries = Entries()
    for _, entry in ipairs(entries) do
        local matched = false
        for _, value in ipairs(eventArgs or {}) do
            if (entry.spellID and value == entry.spellID)
                or (type(value) == "string" and entry.name
                    and string.lower(value) == string.lower(entry.name)) then
                matched = true
                break
            end
        end
        if matched then
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
        local unit, updateInfo = ...
        if unit == "player" then HandleAuraUpdate(updateInfo) end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local args = { ... }
        if args[1] == "player" then
            -- Event signatures differ between the modern and legacy clients;
            -- scan the full payload rather than assuming spellID is arg #3.
            HandleCast(args)
            if C_Timer and C_Timer.After then
                C_Timer.After(0.2, Reminder.CheckAll)
            else
                Reminder.CheckAll()
            end
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Re-evaluate at combat start while the aura data may still be readable.
        Reminder.CheckAll()
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
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_ALIVE")
    frame:RegisterEvent("PLAYER_UNGHOST")
    frame:RegisterEvent("PLAYER_DEAD")
    frame:SetScript("OnEvent", OnEvent)
    SlashCmdList["TUIBUFF"] = Command
    SLASH_TUIBUFF1, SLASH_TUIBUFF2 = "/tuibuff", "/tbuff"
    SnapshotAuraInstances()
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
