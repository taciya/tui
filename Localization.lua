-- TUI feature localization (no recipient-list strings remain).
local locale = GetLocale and GetLocale() or "enUS"
TUI_LOCALE = {
    ["take attachments"] = "Take Attachments",
    ["stop"] = "Stop",
    ["no attachments"] = NO_ATTACHMENTS or "No attachments",
}
if locale == "zhCN" then
    TUI_LOCALE["take attachments"] = "拿取附件"
    TUI_LOCALE["stop"] = "停止"
    TUI_LOCALE["no attachments"] = "没有可领取的附件"
elseif locale == "zhTW" then
    TUI_LOCALE["take attachments"] = "領取附件"
    TUI_LOCALE["stop"] = "停止"
    TUI_LOCALE["no attachments"] = "沒有可領取的附件"
end
