-- Shared command/help registry. Existing slash commands remain untouched.
TUI = TUI or {}
TUI.Commands = TUI.Commands or {}
local Commands = TUI.Commands
Commands.items = Commands.items or {}

function Commands:Register(definition)
    if type(definition) ~= "table" or type(definition.command) ~= "string" then return false end
    self.items[string.lower(definition.command)] = definition
    return true
end

function Commands:GetAll()
    local result, seen = {}, {}
    for _, item in pairs(self.items) do
        result[#result + 1] = item
        seen[string.lower(item.command)] = true
    end
    for globalName, value in pairs(_G) do
        if type(globalName) == "string" and string.match(globalName, "^SLASH_[%w_]+%d+$") and type(value) == "string" then
            local token = string.match(globalName, "^SLASH_([%w_]+)%d+$")
            local handler = token and SlashCmdList and SlashCmdList[token]
            local key = string.lower(value)
            if handler and not seen[key] then
                seen[key] = true
                result[#result + 1] = { command=value, name=value, category="其他命令",
                    description="已注册的旧版命令；详细参数请参考对应功能模块。", status="已注册" }
            end
        end
    end
    table.sort(result, function(a,b)
        if (a.category or "") == (b.category or "") then return (a.command or "") < (b.command or "") end
        return (a.category or "") < (b.category or "")
    end)
    return result
end

Commands:Register({command="/tuihelp",name="TUI 使用说明",category="基础与帮助",description="打开 TUI 使用说明中心。",usage="/tuihelp"})
Commands:Register({command="/tuidebug",name="TUI 调试中心",category="开发与诊断",description="查看模块状态、调试日志并生成可复制报告。",usage="/tuidebug"})
Commands:Register({command="/tuibuff",name="Buff 提醒",category="Buff 与状态提醒",description="管理 Buff 提醒；debug 子命令可查看诊断输出。",usage="/tuibuff debug"})
Commands:Register({command="/tuiinspect",name="TUI Inspector",category="开发与诊断",description="打开技能、物品、状态、API 和宏条件探查窗口。",usage="/tuiinspect [spell|item|state|api|macro]"})
