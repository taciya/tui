-- TUI Item Info Enhancer
-- Adds recipe usage and character-specific learned state to item tooltips.
-- Recipe records are data-driven; add another profession to ItemInfoEnhancer_Data.lua
-- and register its Enum.Profession value to extend this module.

TUI_ItemInfoEnhancer = TUI_ItemInfoEnhancer or {}
local Enhancer = TUI_ItemInfoEnhancer

local MAX_TOOLTIP_RECIPES = 10
local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
end

local function parseRecipeRow(row)
    local outputID, minQty, maxQty, yellowAt, greyAt, spellID, reagentText =
        string.match(row or "", "^(%d+);(%d+);(%d+);(%d+);(%d+);(%d+);(.+)$")
    if not outputID then return nil end

    local recipe = {
        outputItemID = tonumber(outputID),
        minQty = tonumber(minQty),
        maxQty = tonumber(maxQty),
        yellowAt = tonumber(yellowAt),
        greyAt = tonumber(greyAt),
        spellID = tonumber(spellID),
        reagents = {},
    }
    for reagent in string.gmatch(reagentText, "[^,]+") do
        local itemID, count = string.match(reagent, "^(%d+):(%d+)$")
        if itemID then
            recipe.reagents[#recipe.reagents + 1] = {
                itemID = tonumber(itemID),
                count = tonumber(count),
            }
        end
    end
    if #recipe.reagents == 0 then return nil end
    return recipe
end

local function rebuildIndexes(profession)
    profession.bySpellID = {}
    profession.byIngredient = {}
    profession.byOutput = {}
    for _, recipe in ipairs(profession.recipes or {}) do
        profession.bySpellID[recipe.spellID] = recipe
        if recipe.outputItemID then
            profession.byOutput[recipe.outputItemID] = profession.byOutput[recipe.outputItemID] or {}
            table.insert(profession.byOutput[recipe.outputItemID], recipe)
        end
        for _, reagent in ipairs(recipe.reagents or {}) do
            profession.byIngredient[reagent.itemID] = profession.byIngredient[reagent.itemID] or {}
            table.insert(profession.byIngredient[reagent.itemID], {
                recipe = recipe,
                count = reagent.count,
            })
        end
    end
end

function Enhancer:RegisterProfession(key, definition)
    if type(key) ~= "string" or type(definition) ~= "table" then return false end
    local profession = {
        key = key,
        label = definition.label or key,
        professionEnum = definition.professionEnum,
        recipes = {},
        bySpellID = {},
        byIngredient = {},
        byOutput = {},
    }

    for _, row in ipairs(definition.rows or {}) do
        local recipe = parseRecipeRow(row)
        if recipe then profession.recipes[#profession.recipes + 1] = recipe end
    end
    rebuildIndexes(profession)

    self.professions = self.professions or {}
    self.professions[key] = profession
    return true
end

Enhancer.professions = Enhancer.professions or {}
for key, definition in pairs(TUI_ITEM_INFO_DATA or {}) do
    Enhancer:RegisterProfession(key, definition)
end

local function getCharacterStore()
    TUI_DB = TUI_DB or {}
    TUI_DB.ItemInfoEnhancer = TUI_DB.ItemInfoEnhancer or { characters = {} }
    local root = TUI_DB.ItemInfoEnhancer
    root.characters = root.characters or {}
    local name = (UnitName and UnitName("player")) or "Unknown"
    local realm = (GetRealmName and GetRealmName()) or ""
    local key = tostring(name) .. "-" .. tostring(realm)
    root.characters[key] = root.characters[key] or { learned = {}, professions = {} }
    local character = root.characters[key]
    character.learned = character.learned or {}
    character.professions = character.professions or {}
    character.recipeData = character.recipeData or {}
    return character
end

local function currentProfessionInfo()
    if not (C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo) then return nil end
    return safeCall(C_TradeSkillUI.GetBaseProfessionInfo)
end

local function isCurrentProfession(info, profession)
    if not info or not profession then return false end
    local enumValue = profession.professionEnum
    if enumValue == nil then return false end
    if info.profession == enumValue then return true end

    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionSkillLineID then
        local skillLineID = safeCall(C_TradeSkillUI.GetProfessionSkillLineID, enumValue)
        if skillLineID and info.professionID == skillLineID then return true end
    end

    local name = tostring(info.professionName or "")
    return name == profession.label or string.lower(name) == string.lower(tostring(profession.key))
end

function Enhancer:ScanCurrentProfession(silent)
    if not (C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeInfo) then
        if not silent and TUI and TUI.Print then
            TUI:Print("当前客户端缺少专业配方查询 API，无法同步已学会状态")
        end
        return false
    end

    local info = currentProfessionInfo()
    local selected
    for _, profession in pairs(self.professions) do
        if isCurrentProfession(info, profession) then
            selected = profession
            break
        end
    end
    if not selected then
        if not silent and TUI and TUI.Print then
            TUI:Print("请先打开烹饪专业界面，再执行 /tuiiteminfo scan")
        end
        return false
    end

    local recipeIDs = safeCall(C_TradeSkillUI.GetAllRecipeIDs)
    if type(recipeIDs) ~= "table" then
        if not silent and TUI and TUI.Print then TUI:Print("无法读取当前专业配方列表") end
        return false
    end

    local character = getCharacterStore()
    local learned = character.learned[selected.key] or {}
    local fallbackBySpellID = selected.bySpellID or {}
    local scannedRecipes = {}
    local scanned, learnedCount, unlearnedCount = 0, 0, 0

    -- GetAllRecipeIDs includes learned and unlearned recipes. Prefer the live
    -- client schematic for output/reagent IDs; retain bundled data as a fallback.
    for _, rawRecipeID in ipairs(recipeIDs) do
        local recipeID = tonumber(rawRecipeID)
        if recipeID then
            local recipeInfo = safeCall(C_TradeSkillUI.GetRecipeInfo, recipeID)
            local fallback = fallbackBySpellID[recipeID]
            local schematic
            if C_TradeSkillUI.GetRecipeSchematic then
                schematic = safeCall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
            end

            local recipe = {
                spellID = recipeID,
                name = recipeInfo and recipeInfo.name or (fallback and fallback.name),
                outputItemID = fallback and fallback.outputItemID,
                minQty = fallback and fallback.minQty,
                maxQty = fallback and fallback.maxQty,
                yellowAt = fallback and fallback.yellowAt,
                greyAt = fallback and fallback.greyAt,
                reagents = {},
            }

            if type(schematic) == "table" then
                recipe.outputItemID = tonumber(schematic.outputItemID) or recipe.outputItemID
                recipe.minQty = tonumber(schematic.quantityMin) or recipe.minQty
                recipe.maxQty = tonumber(schematic.quantityMax) or recipe.maxQty
                local basicType = Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic
                for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
                    local isBasic = basicType == nil or slot.reagentType == nil or slot.reagentType == basicType
                    if isBasic then
                        for _, reagent in ipairs(slot.reagents or {}) do
                            local itemID = tonumber(reagent.itemID)
                            if itemID then
                                recipe.reagents[#recipe.reagents + 1] = {
                                    itemID = itemID,
                                    count = tonumber(slot.quantityRequired) or 1,
                                }
                            end
                        end
                    end
                end
            end

            if #recipe.reagents == 0 and fallback then
                recipe.reagents = fallback.reagents
            end

            if recipeInfo and type(recipeInfo.learned) == "boolean" then
                learned[tostring(recipeID)] = recipeInfo.learned
                scanned = scanned + 1
                if recipeInfo.learned then learnedCount = learnedCount + 1
                else unlearnedCount = unlearnedCount + 1 end
            end

            if #recipe.reagents > 0 then
                scannedRecipes[#scannedRecipes + 1] = recipe
            end
        end
    end

    if #scannedRecipes > 0 then
        selected.recipes = scannedRecipes
        rebuildIndexes(selected)
        character.recipeData[selected.key] = scannedRecipes
    end

    character.learned[selected.key] = learned
    character.professions[selected.key] = {
        scannedAt = (date and date("%Y-%m-%d %H:%M:%S")) or "已扫描",
        skillLevel = info and info.skillLevel,
        maxSkillLevel = info and info.maxSkillLevel,
        scannedCount = scanned,
    }

    if not silent and TUI and TUI.Print then
        TUI:Print(string.format("%s配方状态已同步：已学会 %d，未学会 %d，确认 %d 条",
            selected.label, learnedCount, unlearnedCount, scanned))
    end
    return true, scanned
end

local function scheduleScan()
    local function run()
        Enhancer:ScanCurrentProfession(true)
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.2, run)
    else run() end
end

local function getItemIDFromTooltip(tooltip)
    if not tooltip then return nil end

    -- Tooltip APIs differ between client builds. Prefer the structured tooltip
    -- data ID, then the direct item ID, and finally the legacy hyperlink.
    if type(tooltip.GetTooltipData) == "function" then
        local data = safeCall(tooltip.GetTooltipData, tooltip)
        local itemID = data and tonumber(data.id)
        if itemID then return itemID end
    end
    if type(tooltip.GetItemID) == "function" then
        local itemID = tonumber(safeCall(tooltip.GetItemID, tooltip))
        if itemID then return itemID end
    end
    if type(tooltip.GetItem) == "function" then
        local _, link = safeCall(tooltip.GetItem, tooltip)
        local itemID = tonumber(link and string.match(link, "item:(%d+)"))
        if itemID then return itemID end
    end
    return nil
end

local function getRecipeName(recipe)
    if recipe.name then return recipe.name end
    local spellID = recipe.spellID
    local name = TUI_Compat and TUI_Compat.GetSpellNameByID and TUI_Compat.GetSpellNameByID(spellID)
    if name then return name end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = safeCall(C_Spell.GetSpellInfo, spellID)
        if type(info) == "table" then return info.name end
    end
    return "配方 #" .. tostring(spellID)
end

local function learnedState(character, profession, recipe)
    local learned = character.learned[profession.key]
    local state = learned and learned[tostring(recipe.spellID)]
    if state == true then return "已学会", 0.25, 1, 0.25 end
    if state == false then return "未学会", 1, 0.45, 0.35 end
    local scan = character.professions[profession.key]
    if scan and scan.scannedAt then return "客户端未返回", 0.8, 0.8, 0.8 end
    return "待扫描", 0.8, 0.8, 0.8
end

local function appendRecipeLines(tooltip, title, matches, character, profession, isIngredient)
    if not matches or #matches == 0 then return 0 end
    table.sort(matches, function(a, b)
        local ar = a.recipe or a
        local br = b.recipe or b
        if ar.yellowAt ~= br.yellowAt then return (ar.yellowAt or 0) < (br.yellowAt or 0) end
        return ar.spellID < br.spellID
    end)

    tooltip:AddLine(title, 1, 0.82, 0)
    local shown = math.min(#matches, MAX_TOOLTIP_RECIPES)
    for i = 1, shown do
        local match = matches[i]
        local recipe = match.recipe or match
        local state, r, g, b = learnedState(character, profession, recipe)
        local extra = ""
        if isIngredient then extra = string.format("  材料 ×%d", match.count or 1) end
        local skill = ""
        if recipe.yellowAt and recipe.greyAt then
            skill = string.format("  黄字 %d / 灰字 %d", recipe.yellowAt, recipe.greyAt)
        end
        tooltip:AddLine(string.format("%s  %s%s%s",
            state, getRecipeName(recipe), extra, skill), r, g, b, true)
    end
    if #matches > shown then
        tooltip:AddLine(string.format("另有 %d 个配方未显示", #matches - shown), 0.75, 0.75, 0.75, true)
    end
    return shown
end

function Enhancer:OnTooltipSetItem(tooltip, suppliedItemID)
    local itemID = tonumber(suppliedItemID) or getItemIDFromTooltip(tooltip)
    if not itemID or not tooltip or type(tooltip.AddLine) ~= "function" then return end

    local character = getCharacterStore()
    local hasLines = false
    local matchCount = 0
    for _, profession in pairs(self.professions) do
        local usedBy = profession.byIngredient[itemID]
        local madeBy = profession.byOutput[itemID]
        if usedBy and #usedBy > 0 then
            matchCount = matchCount + #usedBy
            appendRecipeLines(tooltip, profession.label .. "用途", usedBy, character, profession, true)
            hasLines = true
        end
        if madeBy and #madeBy > 0 then
            matchCount = matchCount + #madeBy
            appendRecipeLines(tooltip, profession.label .. "可制作", madeBy, character, profession, false)
            hasLines = true
        end
    end
    self.lastTooltipDebug = {
        itemID = itemID,
        matches = matchCount,
        hasLines = hasLines,
    }
    if hasLines and tooltip.Show then tooltip:Show() end
end

local function showStatus()
    local character = getCharacterStore()
    for key, profession in pairs(Enhancer.professions) do
        local scan = character.professions[key]
        local learned = character.learned[key] or {}
        local learnedCount, unlearnedCount = 0, 0
        for _, recipe in ipairs(profession.recipes) do
            local state = learned[tostring(recipe.spellID)]
            if state == true then learnedCount = learnedCount + 1
            elseif state == false then unlearnedCount = unlearnedCount + 1 end
        end
        if TUI and TUI.Print then
            TUI:Print(string.format("%s：数据 %d 条；已学会 %d；未学会 %d；%s",
                profession.label, #profession.recipes, learnedCount, unlearnedCount,
                scan and ("上次扫描 " .. tostring(scan.scannedAt)) or "尚未扫描"))
        end
    end
end

local function handleCommand(message)
    local command = string.lower((string.match(message or "", "^%s*(%S*)") or ""))
    if command == "scan" then
        Enhancer:ScanCurrentProfession(false)
    elseif command == "status" then
        showStatus()
    elseif command == "debug" then
        local profession = Enhancer.professions.Cooking
        local matches = profession and profession.byIngredient[6889] or {}
        local dataCount = profession and #profession.recipes or 0
        local route = Enhancer.tooltipHookMode or "未初始化"
        local last = Enhancer.lastTooltipDebug
        if TUI and TUI.Print then
            TUI:Print(string.format("诊断：模块=%s；配方数据=%d；小蛋(6889)匹配=%d；钩子=%s",
                profession and "已注册" or "未注册", dataCount, #matches, route))
            if last then
                TUI:Print(string.format("最近一次 Tooltip：物品ID=%s；匹配配方=%d；已追加=%s",
                    tostring(last.itemID), last.matches, tostring(last.hasLines)))
            else
                TUI:Print("最近一次 Tooltip：尚未捕获到物品")
            end
        end
    else
        if TUI and TUI.Print then
            TUI:Print("物品信息增强：鼠标悬停材料可查看烹饪用途；先打开烹饪专业界面同步已学状态。")
            TUI:Print("命令：/tuiiteminfo scan | status | debug（别名 /tii）")
        end
    end
end

SLASH_TUIITEMINFO1 = "/tuiiteminfo"
SLASH_TUIITEMINFO2 = "/tii"
SlashCmdList.TUIITEMINFO = handleCommand

local function initialize()
    local character = getCharacterStore()
    for key, profession in pairs(Enhancer.professions) do
        local savedRecipes = character.recipeData[key]
        if type(savedRecipes) == "table" and #savedRecipes > 0 then
            profession.recipes = savedRecipes
            rebuildIndexes(profession)
        end
    end

    -- Prefer the structured tooltip pipeline when available. The previous
    -- implementation registered the legacy hook first and then suppressed
    -- the processor callback for the same frame, which could leave clients
    -- using the processor pipeline without any enhancement lines.
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            local itemID = data and tonumber(data.id)
            Enhancer:OnTooltipSetItem(tooltip, itemID)
        end)
        Enhancer.tooltipHookMode = "TooltipDataProcessor"
    else
        local hooked = {}
        local function hookItemTooltip(tooltip)
            if not tooltip or hooked[tooltip] or type(tooltip.HookScript) ~= "function" then return end
            hooked[tooltip] = true
            tooltip:HookScript("OnTooltipSetItem", function(frame)
                Enhancer:OnTooltipSetItem(frame)
            end)
        end
        hookItemTooltip(GameTooltip)
        hookItemTooltip(ItemRefTooltip)
        Enhancer.tooltipHookMode = "HookScript"
    end

    local eventFrame = CreateFrame("Frame")
    local events = {
        "TRADE_SKILL_SHOW",
        "TRADE_SKILL_LIST_UPDATE",
        "TRADE_SKILL_DATA_SOURCE_CHANGED",
        "NEW_RECIPE_LEARNED",
    }
    for _, eventName in ipairs(events) do
        pcall(eventFrame.RegisterEvent, eventFrame, eventName)
    end
    eventFrame:SetScript("OnEvent", function()
        scheduleScan()
    end)
end

if TUI and TUI.RegisterModule then
    TUI:RegisterModule("ItemInfoEnhancer", initialize)
else
    initialize()
end
