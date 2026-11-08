-- TUI Macro: import/update macro templates in the out-of-combat macro UI.
-- Commands: /tuimacro [preview|load|scope account|scope character|help]
local ADDON, TUI = ...
TUI = TUI or _G.TUI or {}
_G.TUI = TUI

local Macro = {}
TUI.Macro = Macro

local function Print(message)
    if TUI.Print then
        TUI:Print("|cff80d8ff宏管理|r " .. tostring(message))
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff80d8ffTUI 宏管理|r " .. tostring(message))
    end
end

local function UTF8Length(value)
    -- Count UTF-8 leading bytes; WoW's Lua 5.1 runtime has no guaranteed utf8 library.
    local _, count = tostring(value or ""):gsub("[^\128-\191]", "")
    return count
end

local function Trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function Parse(source)
    local entries, errors = {}, {}
    local current, body = nil, {}
    local lineNumber = 0

    for line in (tostring(source or "") .. "\n"):gmatch("(.-)\n") do
        lineNumber = lineNumber + 1
        line = line:gsub("\r$", "")
        if not current then
            if Trim(line) ~= "" then
                local version, sourceID, name, icon = line:match('^%s*VER%s+(%d+)%s+([%x]+)%s+"(.-)"%s+"(.-)"%s*$')
                if version and sourceID then
                    current = {
                        version = tonumber(version),
                        sourceID = sourceID:upper(),
                        name = name,
                        icon = tonumber(icon) or icon,
                        headerLine = lineNumber,
                    }
                    body = {}
                else
                    table.insert(errors, "第 " .. lineNumber .. " 行：无法识别宏头，已忽略")
                end
            end
        elseif Trim(line) == "END" then
            current.body = table.concat(body, "\n")
            current.body = current.body:gsub("\n+$", "")
            table.insert(entries, current)
            current, body = nil, {}
        else
            -- Keep intentional blank lines and comments in the macro body.
            table.insert(body, line)
        end
    end

    if current then
        table.insert(errors, "第 " .. current.headerLine .. " 行：宏 " .. current.name .. " 缺少 END，已忽略")
    end
    return entries, errors
end

local function GetMacroCounts()
    if type(GetNumMacros) ~= "function" then return nil, nil end
    local account, character = GetNumMacros()
    return tonumber(account) or 0, tonumber(character) or 0
end

local function GetMacroSnapshot(index)
    if type(GetMacroInfo) ~= "function" then return nil end
    local name, icon, body = GetMacroInfo(index)
    if not name then return nil end
    return { name = name, icon = icon, body = body or "" }
end

local function SameIcon(a, b)
    return tostring(a or "") == tostring(b or "")
end

local function FindSnapshot(snapshot)
    if not snapshot then return nil end
    local account, character = GetMacroCounts()
    if not account then return nil end
    for index = 1, account + character do
        local current = GetMacroSnapshot(index)
        if current and current.name == snapshot.name and current.body == snapshot.body and SameIcon(current.icon, snapshot.icon) then
            return index
        end
    end
end

local function FindUniqueName(name)
    local account, character = GetMacroCounts()
    if not account then return nil, false end
    local found, count
    count = 0
    for index = 1, account + character do
        local current = GetMacroSnapshot(index)
        if current and current.name == name then
            found, count = index, count + 1
        end
    end
    if count == 1 then return found, true end
    return nil, count > 1
end

local function MacroLimit(perCharacter)
    if perCharacter then
        return tonumber(MAX_CHARACTER_MACROS) or 18
    end
    return tonumber(MAX_ACCOUNT_MACROS) or 120
end

local function Validate(entry)
    if not entry.name or entry.name == "" then return false, "名称为空" end
    if UTF8Length(entry.name) > 16 then return false, "名称超过 16 个字符" end
    if UTF8Length(entry.body) > 255 then return false, "正文超过 255 个字符，避免客户端静默截断" end
    if not entry.icon or entry.icon == "" then return false, "图标为空" end
    return true
end

function Macro:Parse(source)
    return Parse(source or TUI_MACRO_SOURCE or "")
end

function Macro:Preview(source)
    local entries, errors = self:Parse(source)
    local valid, invalid, long = 0, 0, 0
    for _, entry in ipairs(entries) do
        local ok, reason = Validate(entry)
        if ok then valid = valid + 1 else invalid = invalid + 1; if reason:find("255", 1, true) then long = long + 1 end end
    end
    Print(string.format("模板 %d 条；可导入 %d 条；无效 %d 条；解析警告 %d 条。", #entries, valid, invalid, #errors))
    if long > 0 then Print("其中 " .. long .. " 条宏正文超过 255 个字符，请先精简。") end
    for _, message in ipairs(errors) do Print(message) end
    return entries, errors
end

function Macro:Load(source, forceUpdate)
    if type(CreateMacro) ~= "function" or type(EditMacro) ~= "function" or type(GetMacroInfo) ~= "function" or type(GetNumMacros) ~= "function" then
        Print("当前客户端未提供完整宏 API，无法导入。")
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        Print("战斗中不能创建或修改宏，请脱离战斗后执行 /tuimacro load。")
        return
    end

    local entries, parseErrors = self:Parse(source)
    local accountCount, characterCount = GetMacroCounts()
    local perCharacter = TUI_DB and TUI_DB.macro and TUI_DB.macro.perCharacter == true
    local currentCount = perCharacter and characterCount or accountCount
    local limit = MacroLimit(perCharacter)
    local created, updated, skipped, failed = 0, 0, 0, 0

    TUI_DB = TUI_DB or {}
    TUI_DB.macro = TUI_DB.macro or {}
    TUI_DB.macro.managed = TUI_DB.macro.managed or {}
    local managed = TUI_DB.macro.managed

    for _, entry in ipairs(entries) do
        local valid, reason = Validate(entry)
        if not valid then
            failed = failed + 1
            Print("跳过「" .. entry.name .. "」：" .. reason)
        else
            local saved = managed[entry.sourceID]
            local index = saved and FindSnapshot(saved)
            local ambiguous = false

            -- If the old managed snapshot disappeared, update by name only when unambiguous.
            if not index and saved then
                index, ambiguous = FindUniqueName(saved.name or entry.name)
            end
            -- First import: exact match detection avoids duplicating an existing macro.
            if not index and not saved then
                index = FindSnapshot({ name = entry.name, icon = entry.icon, body = entry.body })
            end

            if ambiguous and not index then
                skipped = skipped + 1
                Print("跳过「" .. entry.name .. "」：存在同名宏，无法安全判断对应来源；请在宏界面手动处理后重试。")
            elseif index then
                local current = GetMacroSnapshot(index)
                local alreadyCurrent = current and current.name == entry.name and current.body == entry.body and SameIcon(current.icon, entry.icon)
                if alreadyCurrent then
                    skipped = skipped + 1
                elseif forceUpdate or saved then
                    local ok, result = pcall(EditMacro, index, entry.name, entry.icon, entry.body)
                    if ok and result then
                        updated = updated + 1
                    else
                        failed = failed + 1
                        Print("更新「" .. entry.name .. "」失败：" .. tostring(result))
                    end
                else
                    skipped = skipped + 1
                end
                if not ambiguous then
                    managed[entry.sourceID] = { name = entry.name, icon = entry.icon, body = entry.body }
                end
            else
                if currentCount >= limit then
                    Print((perCharacter and "角色专用" or "账号通用") .. "宏已达到上限 " .. limit .. "，停止创建。")
                    break
                end
                local ok, result = pcall(CreateMacro, entry.name, entry.icon, entry.body, perCharacter and true or nil)
                if ok and result then
                    created = created + 1
                    currentCount = currentCount + 1
                    managed[entry.sourceID] = { name = entry.name, icon = entry.icon, body = entry.body }
                else
                    failed = failed + 1
                    Print("创建「" .. entry.name .. "」失败：" .. tostring(result))
                end
            end
        end
    end

    for _, message in ipairs(parseErrors) do Print(message) end
    Print(string.format("导入完成：新建 %d，更新 %d，已存在/跳过 %d，失败 %d。", created, updated, skipped, failed))
    Print("宏范围：" .. (perCharacter and "当前角色" or "账号通用") .. "。可用 /tuimacro scope account|character 切换。")
end

local function HandleCommand(message)
    local command = Trim(message):lower()
    if command == "" or command == "help" then
        Print("/tuimacro preview：预览模板与检查长度")
        Print("/tuimacro load：创建缺失宏，并更新本插件管理的宏")
        Print("/tuimacro scope account：创建账号通用宏（默认）")
        Print("/tuimacro scope character：创建当前角色专用宏")
        Print("/tuimacro update：强制更新已识别的同名宏")
    elseif command == "preview" then
        Macro:Preview()
    elseif command == "load" then
        Macro:Load()
    elseif command == "update" then
        Macro:Load(nil, true)
    elseif command == "scope account" or command == "scope character" then
        TUI_DB = TUI_DB or {}
        TUI_DB.macro = TUI_DB.macro or {}
        TUI_DB.macro.perCharacter = command == "scope character"
        Print("后续新建宏将保存为" .. (TUI_DB.macro.perCharacter and "当前角色专用" or "账号通用") .. "。")
    else
        Print("未知参数。输入 /tuimacro help 查看用法。")
    end
end

SLASH_TUIMACRO1 = "/tuimacro"
SLASH_TUIMACRO2 = "/tuimacros"
SlashCmdList = SlashCmdList or {}
SlashCmdList.TUIMACRO = HandleCommand

-- Expose parser for future UI/import-file support.
TUI.ParseMacroTemplates = function(source) return Macro:Parse(source) end
