-- TUI ItemRack
-- Equipment operations are intentionally out-of-combat only. The legacy
-- /script entry points are not secure actions and must never be used in combat.

local NO_UNDRESS = {
    [2] = true, [4] = true, [11] = true, [12] = true,
    [13] = true, [14] = true, [15] = true, [19] = true,
}

TUI_ItemDB = TUI_ItemDB or {}
NakedObj_Nakie = NakedObj_Nakie or false

local function playerKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName and GetRealmName()
    if realm and realm ~= "" then
        local key = name .. "-" .. realm
        -- One-time migration from the legacy character-name-only key.
        if not TUI_ItemDB[key] and TUI_ItemDB[name] then
            TUI_ItemDB[key] = TUI_ItemDB[name]
        end
        return key
    end
    return name
end

local function playerDB()
    local name = playerKey()
    TUI_ItemDB[name] = TUI_ItemDB[name] or {}
    return TUI_ItemDB[name]
end

local function itemID(link)
    return link and (getID and getID(link) or string.match(link, "item:(%d+)"))
end

local function canMoveItems()
    if InCombatLockdown and InCombatLockdown() then
        TUI_Print("战斗中不能切换装备")
        return false
    end
    if not CursorHasItem then
        TUI_Print("当前客户端缺少 CursorHasItem，已取消装备操作")
        return false
    end
    if CursorHasItem() then
        TUI_Print("请先清空鼠标光标上的物品")
        return false
    end
    if not PickupInventoryItem or not TUI_Compat or not TUI_Compat.PickupContainerItem then
        TUI_Print("当前客户端缺少必要的装备/背包 API")
        return false
    end
    return true
end

local function bagSlots(bag)
    return TUI_Compat.ContainerNumSlots(bag)
end

local function findFreeBagSlot()
    for bag = 0, 4 do
        for slot = 1, bagSlots(bag) do
            if not TUI_Compat.ContainerItemInfo(bag, slot) then
                return bag, slot
            end
        end
    end
end

local function findBagItem(wantedID)
    if not wantedID then return nil end
    wantedID = tostring(wantedID)
    for bag = 0, 4 do
        for slot = 1, bagSlots(bag) do
            local link = TUI_Compat.ContainerItemLink(bag, slot)
            if itemID(link) == wantedID then
                return bag, slot, link
            end
        end
    end
end

local function findEquippedItem(wantedID, exceptSlot)
    if not wantedID then return nil end
    wantedID = tostring(wantedID)
    for slot = 1, 19 do
        if slot ~= exceptSlot then
            local link = GetInventoryItemLink("player", slot)
            if itemID(link) == wantedID then return slot, link end
        end
    end
end

local function moveEquippedToBag(equipSlot, bag, bagSlot)
    local link = GetInventoryItemLink("player", equipSlot)
    if not link then return true end
    PickupInventoryItem(equipSlot)
    if not CursorHasItem() then return false end
    TUI_Compat.PickupContainerItem(bag, bagSlot)
    if CursorHasItem() then
        -- The destination failed; put the item back in its original slot.
        PickupInventoryItem(equipSlot)
        return false
    end
    return true
end

local function equipBagItem(equipSlot, bag, bagSlot)
    TUI_Compat.PickupContainerItem(bag, bagSlot)
    if not CursorHasItem() then return false end
    PickupInventoryItem(equipSlot)
    if CursorHasItem() then
        -- The old equipment is now on the cursor; put it in the vacated bag slot.
        TUI_Compat.PickupContainerItem(bag, bagSlot)
        if CursorHasItem() then
            TUI_Print("装备交换未完成，请检查鼠标光标上的物品")
            return false
        end
    end
    return true
end

local function equipFromOtherSlot(targetSlot, sourceSlot)
    PickupInventoryItem(sourceSlot)
    if not CursorHasItem() then return false end
    PickupInventoryItem(targetSlot)
    if CursorHasItem() then
        -- Target slot had an item: move it back to the vacated source slot.
        PickupInventoryItem(sourceSlot)
        if CursorHasItem() then
            TUI_Print("装备交换未完成，请检查鼠标光标上的物品")
            return false
        end
    end
    return true
end

-- Continue nakedizing only after the client reports an equipment/bag update.
-- Inventory APIs are asynchronous from the addon's point of view: checking the
-- equipment slot immediately after PickupContainerItem can still see stale data.
local nakedizeFrame = CreateFrame("Frame")
nakedizeFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
nakedizeFrame:RegisterEvent("BAG_UPDATE")

local nakedizeState

local function finishNakedize(stopped, reason)
    local state = nakedizeState
    if not state then return end
    nakedizeState = nil

    if next(state.saved) then
        state.db.Naked = { active = true, items = state.saved }
        NakedObj_Nakie = true
    else
        state.db.Naked = nil
        NakedObj_Nakie = false
    end

    local total = 0
    for _ in pairs(state.saved) do total = total + 1 end

    if stopped then
        TUI_Print((reason or "脱装备已停止") .. "；本次成功脱下 " ..
            state.moved .. " 件，累计记录 " .. total .. " 件")
    elseif state.moved > 0 then
        TUI_Print("脱装备完成；本次成功脱下 " .. state.moved .. " 件")
    else
        TUI_Print("没有需要脱下的装备")
    end
end

local function processNextNakedItem()
    local state = nakedizeState
    if not state or state.pending then return end

    while state.index <= #state.order do
        if InCombatLockdown and InCombatLockdown() then
            finishNakedize(true, "进入战斗，脱装备操作已停止")
            return
        end
        if CursorHasItem and CursorHasItem() then
            finishNakedize(true, "鼠标光标上有物品，脱装备操作已停止")
            return
        end

        local slot = state.order[state.index]
        state.index = state.index + 1
        local slotKey = tostring(slot)

        if not NO_UNDRESS[slot] and not state.saved[slotKey] then
            local link = GetInventoryItemLink("player", slot)
            local id = itemID(link)
            if link and id then
                local bag, bagSlot = findFreeBagSlot()
                if not bag then
                    finishNakedize(true, "背包空位已用完")
                    return
                end

                state.pending = { slot = slot, id = tostring(id), link = link }
                local ok = moveEquippedToBag(slot, bag, bagSlot)
                if not ok then
                    state.pending = nil
                    finishNakedize(true, "装备移动失败：" .. tostring(link))
                end
                -- Do not inspect the slot here. Wait for the client update event.
                return
            end
        end
    end

    finishNakedize(false)
end

nakedizeFrame:SetScript("OnEvent", function()
    local state = nakedizeState
    local pending = state and state.pending
    if not pending then return end

    -- The item must have left its original slot and the cursor must be clear.
    -- PLAYER_EQUIPMENT_CHANGED and BAG_UPDATE can arrive at different points;
    -- either event may provide the first reliable post-move state.
    if itemID(GetInventoryItemLink("player", pending.slot)) == pending.id then
        return
    end
    if CursorHasItem and CursorHasItem() then
        return
    end

    state.saved[tostring(pending.slot)] = pending.id
    state.moved = state.moved + 1
    state.db.Naked = { active = true, items = state.saved }
    NakedObj_Nakie = true
    state.pending = nil

    processNextNakedItem()
end)

function TUI_Nakedize()
    if nakedizeState then
        TUI_Print("脱装备操作正在进行中")
        return
    end
    if not canMoveItems() then return end

    local db = playerDB()
    local existing = db.Naked and db.Naked.active and type(db.Naked.items) == "table"
        and db.Naked.items or {}

    -- Weapons first, then other eligible slots. Neck, rings and trinkets
    -- remain excluded by NO_UNDRESS.
    local undressOrder = { 16, 17, 18 }
    for slot = 19, 1, -1 do
        if slot ~= 16 and slot ~= 17 and slot ~= 18 then
            undressOrder[#undressOrder + 1] = slot
        end
    end

    local saved = {}
    for slot, id in pairs(existing) do
        slot, id = tostring(slot), tostring(id)
        if itemID(GetInventoryItemLink("player", tonumber(slot))) ~= id then
            saved[slot] = id
        end
    end

    nakedizeState = {
        db = db,
        saved = saved,
        order = undressOrder,
        index = 1,
        moved = 0,
        pending = nil,
    }
    processNextNakedItem()
end

function TUI_Dressing()
    if not canMoveItems() then return end
    local db = playerDB()
    local naked = db.Naked
    if not naked or not naked.active or type(naked.items) ~= "table" then
        TUI_Print("没有可恢复的脱装备记录")
        return
    end

    local restored, missing = 0, 0
    for slot = 19, 1, -1 do
        local wantedID = naked.items[tostring(slot)]
        if wantedID and itemID(GetInventoryItemLink("player", slot)) ~= tostring(wantedID) then
            local bag, bagSlot = findBagItem(wantedID)
            if bag then
                if equipBagItem(slot, bag, bagSlot) then
                    restored = restored + 1
                else
                    TUI_Print("恢复装备失败，已停止后续操作")
                    return
                end
            else
                local sourceSlot = findEquippedItem(wantedID, slot)
                if sourceSlot then
                    if equipFromOtherSlot(slot, sourceSlot) then
                        restored = restored + 1
                    else
                        TUI_Print("恢复装备失败，已停止后续操作")
                        return
                    end
                else
                    missing = missing + 1
                    TUI_Print("背包或其他装备栏中找不到装备 ID：" .. tostring(wantedID))
                end
            end
        end
    end

    if missing == 0 then
        db.Naked = nil
        NakedObj_Nakie = false
        TUI_Print("恢复装备完成")
    else
        TUI_Print(string.format("已恢复 %d 件，仍缺少 %d 件；再次执行 F9 可继续恢复", restored, missing))
    end
end

function TUI_ItemRack_F9()
    local db = playerDB()
    if db.Naked and db.Naked.active then
        TUI_Dressing()
    else
        TUI_Nakedize()
    end
end

local function applySet(setName)
    if not canMoveItems() then return end
    local db = playerDB()[setName]
    if type(db) ~= "table" then
        TUI_Print("装备方案不存在：" .. tostring(setName))
        return
    end

    local changed, missing = 0, 0
    for targetSlot = 18, 1, -1 do
        local desired = db[tostring(targetSlot)]
        local currentLink = GetInventoryItemLink("player", targetSlot)
        local desiredID = desired and desired ~= "null" and itemID(desired) or nil
        local currentID = itemID(currentLink)

        if desired == "null" or desired == nil then
            if currentLink then
                local bag, bagSlot = findFreeBagSlot()
                if not bag then
                    TUI_Print("背包没有空位，无法卸下装备")
                    return
                end
                if moveEquippedToBag(targetSlot, bag, bagSlot) then changed = changed + 1 end
            end
        elseif desiredID and currentID ~= tostring(desiredID) then
            local bag, bagSlot = findBagItem(desiredID)
            if bag then
                if equipBagItem(targetSlot, bag, bagSlot) then
                    changed = changed + 1
                else
                    TUI_Print("装备切换失败，已停止")
                    return
                end
            else
                local sourceSlot = findEquippedItem(desiredID, targetSlot)
                if sourceSlot then
                    if equipFromOtherSlot(targetSlot, sourceSlot) then
                        changed = changed + 1
                    else
                        TUI_Print("装备交换失败，已停止")
                        return
                    end
                else
                    missing = missing + 1
                    TUI_Print("未找到装备：" .. tostring(desired))
                end
            end
        end
    end
    TUI_Print(string.format("%s 切换完成：变更 %d 个栏位，缺少 %d 件装备", setName, changed, missing))
end

function TUI_ItemRack_F10() applySet("F10") end
function TUI_ItemRack_F11() applySet("F11") end
function TUI_ItemRack_F12() applySet("F12") end

-- Backward-compatible entry points used by older user macros.
function TUI_Equip_10() applySet("F10") end
function TUI_Equip_12() applySet("F12") end

local function saveSet(message)
    local number = tonumber(message)
    if not number or number < 10 or number > 12 or number ~= math.floor(number) then
        TUI_Print("用法：/ti 10、/ti 11 或 /ti 12")
        return
    end
    local setName = "F" .. number
    local set = {}
    for slot = 1, 18 do
        set[tostring(slot)] = GetInventoryItemLink("player", slot) or "null"
    end
    playerDB()[setName] = set
    TUI_Print("已保存装备方案 " .. setName)
end

SlashCmdList["TUIITEMRACK"] = saveSet
SLASH_TUIITEMRACK1 = "/TUIITEMRACK"
SLASH_TUIITEMRACK2 = "/ti"

local function saveNamedItem(slotKey, message)
    if not GetItemInfo then
        TUI_Print("当前客户端不支持 GetItemInfo")
        return
    end
    local name = GetItemInfo(message)
    if not name then
        TUI_Print("物品信息尚未缓存，请使用物品链接再试一次")
        return
    end
    playerDB()[slotKey] = name
    TUI_Print("已保存 " .. slotKey .. "：" .. name)
end

SlashCmdList["TUIH3"] = function(message) saveNamedItem("H3", message) end
SLASH_TUIH31 = "/TUIH3"
SLASH_TUIH32 = "/t3"
SlashCmdList["TUIH0"] = function(message) saveNamedItem("H0", message) end
SLASH_TUIH01 = "/TUIH0"
SLASH_TUIH02 = "/t0"

function TUI_Change(message)
    local key = "H" .. tostring(message or "")
    local wanted = playerDB()[key]
    if not wanted then
        TUI_Print("没有保存的武器方案：" .. key)
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        TUI_Print("战斗中不能切换武器")
        return
    end
    if EquipItemByName then
        EquipItemByName(wanted)
    else
        TUI_Print("当前客户端不支持 EquipItemByName")
    end
end
