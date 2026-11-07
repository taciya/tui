-- TUI Inspector: spell/item/state/API and macro-condition workbench.
-- All API access is guarded because WoW: Infinite may expose a different API subset.
local ADDON, ns = ...
TUI_Inspector = TUI_Inspector or {}
local Inspector = TUI_Inspector
local PREFIX = "|cff33ccffTUI Inspector|r "

local unpackValues = unpack or table.unpack
local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil, "API unavailable" end
    local results = { pcall(fn, ...) }
    if not results[1] then return nil, tostring(results[2]) end
    table.remove(results, 1)
    return unpackValues(results)
end

local function fmt(value)
    if value == nil then return "nil" end
    if type(value) == "boolean" then return value and "true" or "false" end
    if type(value) == "table" then
        local out = {}
        for k, v in pairs(value) do
            out[#out + 1] = tostring(k) .. "=" .. fmt(v)
        end
        table.sort(out)
        return "{" .. table.concat(out, ", ") .. "}"
    end
    return tostring(value)
end

local function spellInfo(query)
    local id = tonumber(query) or tonumber(string.match(query or "", "spell:(%d+)"))
    local info
    if C_Spell and C_Spell.GetSpellInfo then
        info = safeCall(C_Spell.GetSpellInfo, id or query)
        if type(info) == "table" then
            return info.spellID or id, info.name, info.iconID or info.originalIconID,
                info.castTime, info.minRange, info.maxRange, info
        end
    end
    if GetSpellInfo then
        local name, rank, icon, castTime, minRange, maxRange, spellID = safeCall(GetSpellInfo, id or query)
        if name then return spellID or id, name, icon, castTime, minRange, maxRange end
    end
    return id, nil
end

local function itemInfo(query)
    local id = tonumber(query) or tonumber(string.match(query or "", "item:(%d+)"))
    local link = query
    if id and C_Item and C_Item.GetItemInfo then
        link = "item:" .. id
    elseif id then
        link = "item:" .. id
    end
    local name, itemLink, quality, itemLevel, minLevel, itemType, itemSubType,
        stackCount, equipLoc, icon, sellPrice, classID, subclassID, bindType,
        expacID, setID, isCraftingReagent
    if C_Item and C_Item.GetItemInfo then
        name, itemLink, quality, itemLevel, minLevel, itemType, itemSubType,
        stackCount, equipLoc, icon, sellPrice, classID, subclassID, bindType,
        expacID, setID, isCraftingReagent = safeCall(C_Item.GetItemInfo, link)
    elseif GetItemInfo then
        name, itemLink, quality, itemLevel, minLevel, itemType, itemSubType,
        stackCount, equipLoc, icon, sellPrice, classID, subclassID, bindType,
        expacID, setID, isCraftingReagent = safeCall(GetItemInfo, link)
    end
    local instant
    if id and C_Item and C_Item.GetItemInfoInstant then
        instant = { safeCall(C_Item.GetItemInfoInstant, id) }
    elseif id and GetItemInfoInstant then
        instant = { safeCall(GetItemInfoInstant, id) }
    end
    return id, name, itemLink, quality, itemLevel, minLevel, itemType, itemSubType,
        stackCount, equipLoc, icon, sellPrice, instant
end

local CONDITIONS = {
    {"[combat]", "玩家处于战斗状态"}, {"[nocombat]", "玩家不在战斗状态"},
    {"[stealth]", "玩家处于潜行状态"}, {"[nostealth]", "玩家不处于潜行状态"},
    {"[stance:n]", "当前姿态/形态索引匹配 n；需以客户端宏解析器为准"},
    {"[form:n]", "形态条件；具体 token 支持情况需客户端验证"},
    {"[mod]", "任意修饰键按下"}, {"[mod:alt]", "Alt 按下"},
    {"[mod:ctrl]", "Ctrl 按下"}, {"[mod:shift]", "Shift 按下"},
    {"[help]", "目标可被帮助"}, {"[harm]", "目标可被攻击"},
    {"[exists]", "目标存在"}, {"[noexists]", "目标不存在"},
    {"[dead]", "目标死亡"}, {"[nodead]", "目标存活"},
    {"[pet]", "存在指定宠物条件"}, {"[nopet]", "没有宠物"},
    {"[mounted]", "已骑乘"}, {"[nomounted]", "未骑乘"},
    {"[@mouseover]", "以鼠标指向单位作为目标"}, {"[@target]", "以当前目标作为目标"},
    {"[@player]", "以玩家自身作为目标"}, {"[known:技能]", "已学会指定技能（若客户端支持）"},
}

local API_CATALOG = {
    {"GetShapeshiftForm", "读取当前姿态/形态索引"},
    {"GetNumShapeshiftForms", "读取可用姿态/形态数量"},
    {"IsStealthed", "读取潜行状态"},
    {"UnitAffectingCombat", "读取单位战斗状态"},
    {"IsMounted", "读取骑乘状态"},
    {"UnitExists", "检查单位是否存在"},
    {"UnitCanAttack", "检查是否可以攻击单位"},
    {"UnitCanAssist", "检查是否可以帮助单位"},
    {"UnitIsDeadOrGhost", "检查单位是否死亡/灵魂状态"},
    {"IsInInstance", "读取副本状态"},
    {"GetSpellInfo", "旧式技能信息 API（若存在）"},
    {"GetItemInfo", "旧式物品信息 API（若存在）"},
}

local function addLine(lines, label, value)
    lines[#lines + 1] = string.format("%-22s %s", label, fmt(value))
end

local function getStateLines()
    local lines = {"=== 玩家实时状态 ==="}
    local form = safeCall(GetShapeshiftForm)
    addLine(lines, "GetShapeshiftForm()", form)
    local count = safeCall(GetNumShapeshiftForms) or 0
    addLine(lines, "形态数量", count)
    if GetShapeshiftFormInfo and count > 0 then
        lines[#lines + 1] = "形态列表："
        for i = 1, count do
            local icon, name, active, castable = safeCall(GetShapeshiftFormInfo, i)
            lines[#lines + 1] = string.format("  #%d name=%s active=%s castable=%s icon=%s", i, fmt(name), fmt(active), fmt(castable), fmt(icon))
        end
    end
    addLine(lines, "IsStealthed()", safeCall(IsStealthed))
    addLine(lines, "UnitAffectingCombat(player)", safeCall(UnitAffectingCombat, "player"))
    addLine(lines, "IsMounted()", safeCall(IsMounted))
    addLine(lines, "UnitExists(target)", safeCall(UnitExists, "target"))
    addLine(lines, "UnitCanAttack(player,target)", safeCall(UnitCanAttack, "player", "target"))
    addLine(lines, "UnitCanAssist(player,target)", safeCall(UnitCanAssist, "player", "target"))
    addLine(lines, "UnitIsDeadOrGhost(player)", safeCall(UnitIsDeadOrGhost, "player"))
    local inInstance, instanceType = safeCall(IsInInstance)
    addLine(lines, "IsInInstance()", inInstance)
    addLine(lines, "InstanceType", instanceType)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "=== 当前宏条件的可观测近似值 ==="
    addLine(lines, "[stance:" .. tostring(form or "?") .. "]", form ~= nil and form > 0)
    addLine(lines, "[stealth]", safeCall(IsStealthed))
    addLine(lines, "[combat]", safeCall(UnitAffectingCombat, "player"))
    addLine(lines, "说明", "宏条件由安全宏系统判定；此处是 API 观测值，不保证与宏解析器完全等价。")
    return lines
end

local function getSpellLines(query)
    local id, name, icon, castTime, minRange, maxRange, info = spellInfo(query)
    local lines = {"=== 技能信息 ==="}
    addLine(lines, "查询", query)
    addLine(lines, "Spell ID", id)
    addLine(lines, "名称", name)
    addLine(lines, "图标 FileID", icon)
    addLine(lines, "施法时间(ms)", castTime)
    addLine(lines, "最小距离", minRange)
    addLine(lines, "最大距离", maxRange)
    if info then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "=== C_Spell.GetSpellInfo 返回字段 ==="
        for k, v in pairs(info) do addLine(lines, k, v) end
    end
    if id then
        local known
        if IsPlayerSpell then known = safeCall(IsPlayerSpell, id)
        elseif IsSpellKnown then known = safeCall(IsSpellKnown, id) end
        addLine(lines, "已学会(IsPlayerSpell)", known)
        local usable, noMana
        if C_Spell and C_Spell.IsSpellUsable then usable, noMana = safeCall(C_Spell.IsSpellUsable, id)
        elseif IsUsableSpell then usable, noMana = safeCall(IsUsableSpell, id) end
        addLine(lines, "当前可用", usable)
        addLine(lines, "资源不足", noMana)
        local cooldown
        if C_Spell and C_Spell.GetSpellCooldown then cooldown = safeCall(C_Spell.GetSpellCooldown, id) end
        if not cooldown and GetSpellCooldown then
            local start, duration, enabled = safeCall(GetSpellCooldown, id)
            cooldown = { startTime = start, duration = duration, isEnabled = enabled }
        end
        addLine(lines, "冷却信息", cooldown)
        local overrideID
        if C_Spell and C_Spell.GetOverrideSpell then overrideID = safeCall(C_Spell.GetOverrideSpell, id)
        elseif FindSpellOverrideByID then overrideID = safeCall(FindSpellOverrideByID, id) end
        addLine(lines, "Override Spell ID", overrideID)
        local charges
        if C_Spell and C_Spell.GetSpellCharges then charges = safeCall(C_Spell.GetSpellCharges, id) end
        addLine(lines, "充能信息", charges)
    end
    if not name then lines[#lines + 1] = "未取得技能信息：可能是无效 ID、未缓存或当前客户端 API 不支持。" end
    lines[#lines + 1] = "宏示例：/cast " .. (name or (id and ("spell:" .. id) or "技能名称"))
    return lines
end

local function getItemLines(query)
    local id, name, link, quality, itemLevel, minLevel, itemType, itemSubType,
        stackCount, equipLoc, icon, sellPrice, instant = itemInfo(query)
    local lines = {"=== 物品信息 ==="}
    addLine(lines, "查询", query)
    addLine(lines, "Item ID", id)
    addLine(lines, "名称", name)
    addLine(lines, "物品链接", link)
    addLine(lines, "品质", quality)
    addLine(lines, "物品等级", itemLevel)
    addLine(lines, "需求等级", minLevel)
    addLine(lines, "物品类型", itemType)
    addLine(lines, "子类型", itemSubType)
    addLine(lines, "最大堆叠", stackCount)
    addLine(lines, "装备位置", equipLoc)
    addLine(lines, "图标 FileID", icon)
    addLine(lines, "售价(copper)", sellPrice)
    addLine(lines, "Instant 信息", instant)
    if id then
        local count
        if C_Item and C_Item.GetItemCount then count = safeCall(C_Item.GetItemCount, id)
        elseif GetItemCount then count = safeCall(GetItemCount, id) end
        addLine(lines, "拥有数量", count)
        addLine(lines, "可装备", IsEquippableItem and safeCall(IsEquippableItem, id))
        addLine(lines, "已装备", IsEquippedItem and safeCall(IsEquippedItem, id))
        addLine(lines, "当前可用", IsUsableItem and safeCall(IsUsableItem, id))
    end
    lines[#lines + 1] = "宏示例：/use item:" .. (id or "物品ID")
    if not name then lines[#lines + 1] = "提示：物品信息可能尚未缓存；请稍候再次查询或使用物品链接查询。" end
    return lines
end

local function getAPILines()
    local lines = {"=== 可探查 API（只读白名单） ===", "不会执行任意输入的 Lua 代码，以避免污染环境或触发受保护操作。", ""}
    for _, entry in ipairs(API_CATALOG) do
        local exists = type(_G[entry[1]]) == "function"
        lines[#lines + 1] = string.format("%-30s %s | %s", entry[1], exists and "可用" or "不可用", entry[2])
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "API 返回值可在‘状态探查’页查看；后续可扩展白名单和多返回值展开。"
    return lines
end

local function getConditionLines()
    local lines = {"=== 宏条件速查 ===", "条件是否支持，以《魔兽世界：无限》当前客户端宏解析器为准。", ""}
    for _, entry in ipairs(CONDITIONS) do
        lines[#lines + 1] = string.format("%-24s %s", entry[1], entry[2])
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "德鲁伊示例："
    lines[#lines + 1] = "/cast [stealth]突袭;[stance:1]重殴;[stance:3]爪击;愤怒"
    lines[#lines + 1] = "提示：GetShapeshiftForm() 的 API 索引与 [stance:n] 宏条件应分别核对，不要默认它们在所有客户端完全一致。"
    return lines
end

function Inspector:ShowPage(page, query)
    if not self.output then return end
    self.page = page or self.page or "spell"
    query = query or (self.search and self.search:GetText()) or ""
    local lines
    if self.page == "spell" then lines = getSpellLines(query ~= "" and query or "月火术")
    elseif self.page == "item" then lines = getItemLines(query ~= "" and query or "")
    elseif self.page == "state" then lines = getStateLines()
    elseif self.page == "api" then lines = getAPILines()
    else lines = getConditionLines() end
    self.output:SetText(table.concat(lines, "\n"))
    self.output:SetCursorPosition(0)
end

local function makeButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

function Inspector:CreateUI()
    if self.frame then return end
    local frame = CreateFrame("Frame", "TUIInspectorFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(650, 510)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    if frame.TitleText then frame.TitleText:SetText("TUI Inspector - 技能 / 物品 / 状态 / 宏条件") end
    self.frame = frame

    local search = CreateFrame("EditBox", "TUIInspectorSearch", frame, "InputBoxTemplate")
    search:SetSize(310, 26)
    search:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -42)
    search:SetAutoFocus(false)
    search:SetText("月火术")
    search:SetScript("OnEnterPressed", function(edit)
        edit:ClearFocus()
        Inspector:ShowPage(Inspector.page, edit:GetText())
    end)
    self.search = search

    local searchButton = makeButton(frame, "查询", 64, function()
        Inspector:ShowPage(Inspector.page, search:GetText())
    end)
    searchButton:SetPoint("LEFT", search, "RIGHT", 8, 0)

    local pages = {
        {"技能", "spell"}, {"物品", "item"}, {"状态", "state"},
        {"API", "api"}, {"宏条件", "macro"},
    }
    local x = 22
    for _, entry in ipairs(pages) do
        local button = makeButton(frame, entry[1], 76, function()
            Inspector.page = entry[2]
            if entry[2] == "state" or entry[2] == "api" or entry[2] == "macro" then search:Hide() else search:Show() end
            Inspector:ShowPage(entry[2], search:GetText())
        end)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -78)
        x = x + 82
    end

    local scroll = CreateFrame("ScrollFrame", "TUIInspectorScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -112)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -38, 48)
    local output = CreateFrame("EditBox", "TUIInspectorOutput", scroll)
    output:SetMultiLine(true)
    output:SetAutoFocus(false)
    output:SetFontObject(ChatFontNormal)
    output:SetWidth(575)
    output:SetHeight(2600)
    output:SetTextInsets(5, 5, 5, 5)
    output:SetScript("OnEscapePressed", function(edit) edit:ClearFocus() end)
    output:SetScript("OnEditFocusGained", function(edit) edit:HighlightText() end)
    scroll:SetScrollChild(output)
    self.output = output

    local refresh = makeButton(frame, "刷新状态", 90, function() Inspector:ShowPage("state") end)
    refresh:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 14)
    local copyHint = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyHint:SetPoint("LEFT", refresh, "RIGHT", 12, 0)
    copyHint:SetText("选中结果后按 Ctrl+C 复制；/tuiinspect spell|item ID/名称")
    self:ShowPage("spell", search:GetText())
end

function Inspector:Toggle()
    self:CreateUI()
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end

function Inspector:HandleCommand(message)
    local command, query = string.match(message or "", "^(%S+)%s*(.-)%s*$")
    command = string.lower(command or "")
    if command == "spell" or command == "技能" then self:CreateUI(); self.frame:Show(); self.page = "spell"; self.search:Show(); self.search:SetText(query); self:ShowPage("spell", query)
    elseif command == "item" or command == "物品" then self:CreateUI(); self.frame:Show(); self.page = "item"; self.search:Show(); self.search:SetText(query); self:ShowPage("item", query)
    elseif command == "state" or command == "状态" then self:CreateUI(); self.frame:Show(); self.page = "state"; self.search:Hide(); self:ShowPage("state")
    elseif command == "api" then self:CreateUI(); self.frame:Show(); self.page = "api"; self.search:Hide(); self:ShowPage("api")
    elseif command == "macro" or command == "宏" then self:CreateUI(); self.frame:Show(); self.page = "macro"; self.search:Hide(); self:ShowPage("macro")
    else self:Toggle() end
end

SLASH_TUIINSPECT1 = "/tuiinspect"
SLASH_TUIINSPECT2 = "/tiq"
SlashCmdList.TUIINSPECT = function(message) Inspector:HandleCommand(message) end

if TUI and TUI.RegisterModule then
    TUI:RegisterModule("Inspector", function()
        Inspector:CreateUI()
        if TUI_Events then
            local refreshState = function()
                if Inspector.frame and Inspector.frame:IsShown() and Inspector.page == "state" then Inspector:ShowPage("state") end
            end
            TUI_Events:Register("UPDATE_SHAPESHIFT_FORM", Inspector, refreshState)
            TUI_Events:Register("PLAYER_ENTERING_WORLD", Inspector, refreshState)
            TUI_Events:Register("PLAYER_TARGET_CHANGED", Inspector, refreshState)
            TUI_Events:Register("PLAYER_MOUNT_DISPLAY_CHANGED", Inspector, refreshState)
            TUI_Events:Register("PLAYER_REGEN_DISABLED", Inspector, function()
                if Inspector.frame and Inspector.frame:IsShown() and Inspector.page == "state" then Inspector:ShowPage("state") end
            end)
            TUI_Events:Register("PLAYER_REGEN_ENABLED", Inspector, function()
                if Inspector.frame and Inspector.frame:IsShown() and Inspector.page == "state" then Inspector:ShowPage("state") end
            end)
        end
    end)
end
