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

local Reminder = { states = {}, durations = {}, expirations = {}, tokens = {}, auraInstanceSpells = {}, auraInstanceDetails = {}, auraInstanceHistory = {}, auraInstanceSources = {}, lastAuraInstanceSet = nil, instanceTrackedKeys = {}, confirmedRemovedKeys = {}, snapshotPresent = {}, snapshotValid = false, debug = { auraEvents = 0, playerAuraEvents = 0, updateInfoEvents = 0, removedIDs = 0, snapshotOK = 0, snapshotFailed = 0, snapshotRemoved = 0, lastRemoval = "none", alertRefreshes = 0, alertMissingCount = 0, alertLastText = "" } }

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
    Reminder.debug.lastModernScan = string.format("supported:%s unknown:%s complete:%s", tostring(modernOK), tostring(modernUnknown), tostring(modernComplete))
    if modern then return "PRESENT", modern end

    -- A complete modern helpful-aura scan is authoritative for absence.
    -- Do not let a stale legacy UnitAura result resurrect an aura that the
    -- modern spell-name lookup and full indexed scan both failed to find.
    if modernComplete and not modernUnknown then return "MISSING" end

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

local function RememberAuraInstance(aura, source)
    if not aura or Secret(aura) then return end
    local instanceID, instanceOK = Field(aura, "auraInstanceID")
    if not instanceOK or type(instanceID) ~= "number" then return end
    local spellID, spellOK = Field(aura, "spellId")
    if not spellOK then spellID, spellOK = Field(aura, "spellID") end
    local name, nameOK = Field(aura, "name")
    if not spellOK and not nameOK then return end
    local entry = EntryForSpell(spellOK and spellID or nil, nameOK and name or nil)
    if entry then
        Reminder.auraInstanceSpells[instanceID] = entry.key
        Reminder.auraInstanceHistory[instanceID] = entry.key
        Reminder.auraInstanceSources[instanceID] = source or "snapshot"
        Reminder.auraInstanceDetails[instanceID] = {
            spellID = spellOK and spellID or nil,
            name = nameOK and name or nil,
            entryName = entry.name,
            entrySpellID = entry.spellID,
        }
        Reminder.instanceTrackedKeys[entry.key] = true
        -- Only an explicit UNIT_AURA addedAuras record or a direct positive
        -- aura query can clear a confirmed-removal latch. Snapshot enumeration
        -- alone is not sufficient on this client because it can expose stale IDs.
        if source == "event-added" then
            Reminder.confirmedRemovedKeys[entry.key] = nil
        end
    end
end

local function HasOtherAuraInstance(key, excludedInstanceID)
    for instanceID, instanceKey in pairs(Reminder.auraInstanceSpells) do
        -- A snapshot-only sibling is not sufficient evidence of continued
        -- presence on this client: its instance list can retain stale IDs.
        -- Only an explicit addedAuras event confirms a new live sibling.
        if instanceID ~= excludedInstanceID and instanceKey == key
            and Reminder.auraInstanceSources[instanceID] == "event-added" then
            return true
        end
    end
    return false
end

local function MarkRemovedAuraInstance(instanceID, source)
    local key = Reminder.auraInstanceSpells[instanceID] or Reminder.auraInstanceHistory[instanceID]
    if not key then
        if Reminder.debug.lastRemoval == "none" then
            Reminder.debug.lastRemoval = tostring(instanceID) .. " unmapped (" .. tostring(source or "unknown") .. ")"
        end
        return
    end
    local detail = Reminder.auraInstanceDetails[instanceID] or {}
    Reminder.debug.lastRemoval = string.format("%s -> %s [spellID:%s name:%s] (%s)", tostring(instanceID), tostring(key), tostring(detail.spellID or "-"), tostring(detail.name or "-"), tostring(source or "unknown"))
    Reminder.auraInstanceSpells[instanceID] = nil
    Reminder.auraInstanceHistory[instanceID] = nil
    Reminder.auraInstanceSources[instanceID] = nil
    Reminder.auraInstanceDetails[instanceID] = nil
    if not HasOtherAuraInstance(key, instanceID) then
        Reminder.states[key] = "MISSING"
        Reminder.confirmedRemovedKeys[key] = true
        Reminder.expirations[key] = nil
    end
end

local function SnapshotAuraInstances()
    if not C_UnitAuras or type(C_UnitAuras.GetUnitAuraInstanceIDs) ~= "function" then
        return false
    end
    local ok, ids = pcall(C_UnitAuras.GetUnitAuraInstanceIDs, "player", "HELPFUL")
    if not ok or Secret(ids) or type(ids) ~= "table" then Reminder.debug.snapshotFailed = Reminder.debug.snapshotFailed + 1; return false end

    local current = {}
    for _, instanceID in ipairs(ids) do
        if Secret(instanceID) or type(instanceID) ~= "number" then Reminder.debug.snapshotFailed = Reminder.debug.snapshotFailed + 1; return false end
        current[instanceID] = true
        RememberAuraInstance(ReadAuraByInstanceID(instanceID))
    end

    -- A set difference is a second source of removal information for clients
    -- that expose instance IDs but omit removedAuraInstanceIDs from updateInfo.
    if Reminder.lastAuraInstanceSet then
        for instanceID in pairs(Reminder.lastAuraInstanceSet) do
            if not current[instanceID] then
                MarkRemovedAuraInstance(instanceID, "snapshot")
                Reminder.debug.snapshotRemoved = Reminder.debug.snapshotRemoved + 1
            end
        end
    end
    -- Drop stale mappings, then derive an authoritative per-entry presence view
    -- from the complete instance-ID snapshot. This prevents a stale spell/name
    -- lookup from changing a confirmed removal back to PRESENT.
    for instanceID in pairs(Reminder.auraInstanceSpells) do
        if not current[instanceID] then
            Reminder.auraInstanceSpells[instanceID] = nil
            Reminder.auraInstanceSources[instanceID] = nil
            -- Keep the historical key until a delayed removedAuraInstanceIDs
            -- event arrives; active presence is tracked separately above.
            Reminder.auraInstanceDetails[instanceID] = nil
        end
    end
    local present = {}
    for instanceID in pairs(current) do
        local key = Reminder.auraInstanceSpells[instanceID]
        if key then present[key] = true end
    end
    Reminder.snapshotPresent = present
    Reminder.snapshotValid = true
    Reminder.lastAuraInstanceSet = current
    Reminder.debug.snapshotOK = Reminder.debug.snapshotOK + 1
    return true
end

local function HandleAuraUpdate(updateInfo)
    if updateInfo and not Secret(updateInfo) and type(updateInfo) == "table" then Reminder.debug.updateInfoEvents = Reminder.debug.updateInfoEvents + 1 end
    if updateInfo and not Secret(updateInfo) and type(updateInfo) == "table" then
        local added = updateInfo.addedAuras
        if not Secret(added) and type(added) == "table" then
            for _, aura in ipairs(added) do RememberAuraInstance(aura, "event-added") end
        end

        local removed = updateInfo.removedAuraInstanceIDs
        if not Secret(removed) and type(removed) == "table" then
            for _, instanceID in ipairs(removed) do
                if not Secret(instanceID) and type(instanceID) == "number" then
                    MarkRemovedAuraInstance(instanceID, "event")
                    Reminder.debug.removedIDs = Reminder.debug.removedIDs + 1
                end
            end
        end

        local fullUpdate, fullUpdateOK = Field(updateInfo, "isFullUpdate")
        if fullUpdateOK and fullUpdate == true then
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
    -- Put the warning above ordinary dialogs and addon frames. Do not rely on
    -- the default strata/level, which can be covered by other UI elements.
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(500)
    f:SetToplevel(true)
    if f.SetClampedToScreen then f:SetClampedToScreen(true) end
    if f.SetIgnoreParentAlpha then f:SetIgnoreParentAlpha(true) end
    f:SetSize(1120, 150)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 105)

    -- Use an explicit color texture: SetTexture(r,g,b,a) is not portable
    -- across the older client builds supported by this addon.
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    if bg.SetColorTexture then
        bg:SetColorTexture(0.12, 0.015, 0.015, 0.96)
    else
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0.12, 0.015, 0.015, 0.96)
    end

    local border = f:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    if border.SetColorTexture then
        border:SetColorTexture(1, 0.25, 0.05, 0.9)
    else
        border:SetTexture("Interface\\Buttons\\WHITE8X8")
        border:SetVertexColor(1, 0.25, 0.05, 0.9)
    end
    -- Inset dark panel leaves a clearly visible warning-colored rim.
    local panel = f:CreateTexture(nil, "ARTWORK")
    panel:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3)
    panel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
    if panel.SetColorTexture then
        panel:SetColorTexture(0.045, 0.008, 0.008, 0.98)
    else
        panel:SetTexture("Interface\\Buttons\\WHITE8X8")
        panel:SetVertexColor(0.045, 0.008, 0.008, 0.98)
    end

    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    fs:SetPoint("CENTER", f, "CENTER", 0, 0)
    fs:SetWidth(1060)
    fs:SetJustifyH("CENTER")
    local font = fs:GetFont()
    if font then fs:SetFont(font, 34, "THICKOUTLINE") end
    fs:SetTextColor(1, 0.88, 0.12, 1)
    if fs.SetShadowOffset then fs:SetShadowOffset(2, -2) end
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 1) end
    fs:SetAlpha(1)
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
    Reminder.debug.alertRefreshes = Reminder.debug.alertRefreshes + 1
    Reminder.debug.alertMissingCount = #missing
    if #missing == 0 then
        Reminder.debug.alertLastText = ""
        f:Hide()
        return
    end
    Reminder.debug.alertLastText = "缺少效果：" .. table.concat(missing, "、")
    f.text:SetText("|cffff3333" .. Reminder.debug.alertLastText .. "|r")
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
    -- Once this configured aura has been observed by instance ID, a successful
    -- complete snapshot is more reliable than spell/name lookup in combat.
    if Reminder.snapshotValid and Reminder.instanceTrackedKeys[entry.key] then
        -- Once UNIT_AURA explicitly reports removal of the last tracked
        -- instance, a later snapshot-only ID must not resurrect the buff.
        -- On this client the instance list can contain stale/recycled entries.
        if Reminder.confirmedRemovedKeys[entry.key] then
            state, aura = "MISSING", nil
        elseif state == "MISSING" then
            aura = nil
        elseif not state or state == "UNKNOWN" then
            -- Snapshot presence may bootstrap an unknown entry only before
            -- a confirmed removal has occurred in this session.
            state = Reminder.snapshotPresent[entry.key] and "PRESENT" or "MISSING"
            if state == "MISSING" then aura = nil end
        end
    end
    local previous = Reminder.states[entry.key]
    if state == "PRESENT" then
        Reminder.confirmedRemovedKeys[entry.key] = nil
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
        Reminder.debug.auraEvents = Reminder.debug.auraEvents + 1
        local args = { ... }
        local unit = args[1]
        if unit == "player" then
            Reminder.debug.playerAuraEvents = Reminder.debug.playerAuraEvents + 1
            -- Some client builds differ in the UNIT_AURA payload; locate the update table instead of assuming arg #2.
            local updateInfo
            for i = 2, #args do
                local candidate = args[i]
                if not Secret(candidate) and type(candidate) == "table"
                    and (candidate.addedAuras ~= nil or candidate.removedAuraInstanceIDs ~= nil or candidate.isFullUpdate ~= nil) then
                    updateInfo = candidate
                    break
                end
            end
            HandleAuraUpdate(updateInfo)
        end
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
    elseif cmd == "debug" then
        local auraAPI = C_UnitAuras and type(C_UnitAuras.GetUnitAuraInstanceIDs) == "function"
        local lookupAPI = C_UnitAuras and type(C_UnitAuras.GetAuraDataByAuraInstanceID) == "function"
        local mapped = 0
        for _ in pairs(Reminder.auraInstanceSpells) do mapped = mapped + 1 end
        Print("Aura Instance API: " .. (auraAPI and "可用" or "不可用"))
        Print("Aura Instance 查询 API: " .. (lookupAPI and "可用" or "不可用"))
        Print("已映射实例: " .. tostring(mapped))
        Print(string.format("UNIT_AURA: %d (player:%d, updateInfo:%d)", Reminder.debug.auraEvents, Reminder.debug.playerAuraEvents, Reminder.debug.updateInfoEvents))
        Print(string.format("移除ID:%d | 快照成功:%d 失败:%d | 快照发现移除:%d", Reminder.debug.removedIDs, Reminder.debug.snapshotOK, Reminder.debug.snapshotFailed, Reminder.debug.snapshotRemoved))
        Print("最近移除: " .. tostring(Reminder.debug.lastRemoval))
        Print("现代名称扫描: " .. tostring(Reminder.debug.lastModernScan or "尚未执行"))
        local alert = Reminder.alert
        Print(string.format("提醒诊断: refresh:%d missing:%d shown:%s visible:%s alpha:%s effective:%s strata:%s text:%s", Reminder.debug.alertRefreshes, Reminder.debug.alertMissingCount, tostring(alert and alert:IsShown() or false), tostring(alert and alert:IsVisible() or false), tostring(alert and alert:GetAlpha() or "-"), tostring(alert and alert:GetEffectiveAlpha() or "-"), tostring(alert and alert:GetFrameStrata() or "-"), tostring(Reminder.debug.alertLastText)))
        local activeIDs = {}
        for instanceID, key in pairs(Reminder.auraInstanceSpells) do
            activeIDs[#activeIDs + 1] = instanceID
        end
        table.sort(activeIDs)
        for _, instanceID in ipairs(activeIDs) do
            local key = Reminder.auraInstanceSpells[instanceID]
            local detail = Reminder.auraInstanceDetails[instanceID] or {}
            Print(string.format("当前实例:%s -> %s | AuraID:%s | 名称:%s", tostring(instanceID), tostring(key), tostring(detail.spellID or "-"), tostring(detail.name or "-")))
        end
        for _, entry in ipairs(Entries()) do
            if Reminder.instanceTrackedKeys[entry.key] then
                Print((entry.name or tostring(entry.spellID)) .. " 实例快照: " .. (Reminder.snapshotValid and (Reminder.snapshotPresent[entry.key] and "PRESENT" or "MISSING") or "UNKNOWN"))
            end
        end
        for _, entry in ipairs(Entries()) do
            Print((entry.name or tostring(entry.spellID)) .. " | " .. tostring(Reminder.states[entry.key] or "UNKNOWN"))
            if entry.spellID then
                local aura, supported, uncertain = ReadByID(entry.spellID)
                local instanceID = aura and Field(aura, "auraInstanceID") or nil
                Print("  SpellID查询: " .. (not supported and "UNAVAILABLE" or uncertain and "UNKNOWN" or aura and ("PRESENT instance:" .. tostring(instanceID or "-")) or "ABSENT"))
            end
            if entry.name and C_UnitAuras and type(C_UnitAuras.GetAuraDataBySpellName) == "function" then
                local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", entry.name, "HELPFUL")
                local name, nameOK = Field(aura, "name")
                local auraID, idOK = Field(aura, "spellId")
                if not idOK then auraID, idOK = Field(aura, "spellID") end
                local instanceID, instanceOK = Field(aura, "auraInstanceID")
                Print("  SpellName查询: " .. (not ok and "ERROR" or Secret(aura) and "UNKNOWN" or not aura and "ABSENT" or string.format("PRESENT name:%s id:%s instance:%s", nameOK and tostring(name) or "?", idOK and tostring(auraID) or "?", instanceOK and tostring(instanceID) or "?")))
            end
            if entry.name and C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function" then
                local found = false
                local count, matches = 0, 0
                local stopReason = "LIMIT"
                for index = 1, 255 do
                    local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", index, "HELPFUL")
                    if not ok then
                        local err = tostring(aura):gsub("[%r\n]+", " ")
                        Reminder.debug.lastIndexError = string.format("index:%d error:%s", index, err)
                        stopReason = "API_ERROR@" .. index
                        break
                    end
                    if Secret(aura) then stopReason = "SECRET_AURA@" .. index; break end
                    if aura == nil then stopReason = "END@" .. index; break end
                    count = count + 1
                    local auraName, nameOK = Field(aura, "name")
                    if not nameOK then stopReason = "SECRET_NAME@" .. index; break end
                    if auraName == entry.name then
                        matches = matches + 1
                        found = true
                        local auraID = Field(aura, "spellId")
                        if not auraID then auraID = Field(aura, "spellID") end
                        local instanceID = Field(aura, "auraInstanceID")
                        Print(string.format("  Index匹配:%d name:%s id:%s instance:%s", index, tostring(auraName), tostring(auraID or "?"), tostring(instanceID or "?")))
                    end
                end
                Print(string.format("  Index扫描: %d项 | 匹配:%d | stop:%s | %s", count, matches, stopReason, found and "PRESENT" or (stopReason:match("^END") and "ABSENT" or "UNKNOWN")))
                Print("  Index API错误: " .. tostring(Reminder.debug.lastIndexError or "none"))
            else
                Print("  Index扫描: API不可用")
                Print("  Index API错误: API不可用")
            end
        end
    elseif cmd == "alert" then
        -- Force the normal alert refresh path using the current reminder states.
        RefreshAlert()
        local alert = Reminder.alert
        Print(string.format("提醒刷新完成 | missing:%d | shown:%s | text:%s", Reminder.debug.alertMissingCount, tostring(alert and alert:IsShown() or false), tostring(Reminder.debug.alertLastText)))
    elseif cmd == "test" then
        local f = AlertFrame()
        f.text:SetText("|cffff3333缺少效果：闪电之盾（测试）|r")
        f:Show()
        if C_Timer and C_Timer.After then C_Timer.After(4, RefreshAlert) end
    else
        Print("用法：/tuibuff add <名称或ID> | del <名称或ID> | list | clear | check | debug | alert | test")
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
