-- TUI Buff Reminder
-- Tracks learned, self-cast persistent class buffs and shows an icon when missing
-- or nearing expiration. Spellbook scanning naturally follows the active talent set.
TUI_BuffReminder = TUI_BuffReminder or {}

local catalog = {
    DRUID = {
        { id = 1126, name = "Mark of the Wild" },
        { id = 467, name = "Thorns" },
    },
    SHAMAN = {
        { id = 324, name = "Lightning Shield" },
    },
}

local function spellName(id)
    if GetSpellInfo then return GetSpellInfo(id) end
end

local function knowsSpell(wanted)
    if not wanted then return false end
    if C_SpellBook and C_SpellBook.FindSpellBookSlotForSpell then
        local slot = C_SpellBook.FindSpellBookSlotForSpell(wanted)
        return slot ~= nil
    end
    if GetSpellName then
        for i = 1, 500 do
            local name = GetSpellName(i, BOOKTYPE_SPELL or "spell")
            if not name then break end
            if name == wanted then return true end
        end
    end
    return false
end

local function getPlayerBuff(wanted)
    if not UnitBuff then return nil end
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff("player", i)
        if not name then break end
        if name == wanted then
            return icon, count or 0, duration or 0, expirationTime or 0
        end
    end
end

local function initReminder()
    local _, class = UnitClass("player")
    local entries = catalog[class]
    if not entries then return end

    TUI_BuffReminderDB = TUI_BuffReminderDB or {}
    local cfg = TUI_BuffReminderDB
    if cfg.threshold == nil then cfg.threshold = 60 end
    if cfg.lowStacks == nil then cfg.lowStacks = 1 end
    if cfg.iconSize == nil then cfg.iconSize = 42 end

    local frame = CreateFrame("Frame", "TUIBuffReminderFrame", UIParent)
    frame:SetSize(260, cfg.iconSize + 8)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    frame.icons = {}

    local function makeIcon(index)
        local b = CreateFrame("Frame", nil, frame)
        b:SetSize(cfg.iconSize, cfg.iconSize)
        b:SetPoint("LEFT", frame, "LEFT", (index - 1) * (cfg.iconSize + 8), 0)
        b.texture = b:CreateTexture(nil, "ARTWORK")
        b.texture:SetAllPoints()
        b.time = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        b.time:SetPoint("BOTTOM", b, "BOTTOM", 0, 1)
        b.count = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        b.count:SetPoint("TOPRIGHT", b, "TOPRIGHT", 2, 2)
        b:Hide()
        return b
    end

    for i = 1, #entries do frame.icons[i] = makeIcon(i) end

    local function update()
        local shown = 0
        for _, entry in ipairs(entries) do
            local name = spellName(entry.id) or entry.name
            if knowsSpell(name) then
                local icon, count, duration, expires = getPlayerBuff(name)
                local remaining = expires > 0 and (expires - GetTime()) or 0
                local threshold = cfg.threshold
                if duration > 0 then threshold = math.min(threshold, duration * 0.20) end
                local missing = not icon
                local lowStack = (entry.stacks and count < (entry.stacks)) or false
                if missing or remaining <= threshold or lowStack then
                    shown = shown + 1
                    local b = frame.icons[shown]
                    if b then
                        b.texture:SetTexture(icon or GetSpellTexture(entry.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
                        b.time:SetText(missing and "缺失" or (remaining > 0 and math.ceil(remaining) .. "s" or "刷新"))
                        b.count:SetText(count > 0 and count or "")
                        b:Show()
                    end
                end
            end
        end
        for i = shown + 1, #frame.icons do frame.icons[i]:Hide() end
        frame:SetWidth(math.max(cfg.iconSize, shown * (cfg.iconSize + 8)))
    end

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("SPELLS_CHANGED")
    frame:SetScript("OnEvent", function(self, event, unit)
        if event ~= "UNIT_AURA" or unit == "player" then update() end
    end)
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 1 then self.elapsed = 0; update() end
    end)
    update()
    TUI_BuffReminder = { frame = frame, config = cfg, Refresh = update }
end

if TUI and TUI.RegisterModule then
    TUI:RegisterModule("BuffReminder", initReminder)
else
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("PLAYER_LOGIN")
    loader:SetScript("OnEvent", initReminder)
end
