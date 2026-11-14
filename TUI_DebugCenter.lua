-- TUI Debug Center UI. Uses the shared TUI.Debug service.
TUI_DebugCenter = TUI_DebugCenter or {}
local Center = TUI_DebugCenter
local function button(parent,label,width,callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,24); b:SetText(label); b:SetScript("OnClick",callback); return b
end
function Center:Create()
    if self.frame then return end
    local f=CreateFrame("Frame","TUIDebugCenterFrame",UIParent,"BasicFrameTemplateWithInset")
    f:SetSize(760,560); f:SetPoint("CENTER"); f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing); f:Hide()
    if f.TitleText then f.TitleText:SetText("TUI Debug Center") end
    self.frame=f
    local filter=CreateFrame("EditBox","TUIDebugFilter",f,"InputBoxTemplate")
    filter:SetSize(170,24); filter:SetPoint("TOPLEFT",f,"TOPLEFT",20,-42); filter:SetAutoFocus(false); filter:SetText("全部"); self.filter=filter
    local scroll=CreateFrame("ScrollFrame","TUIDebugScroll",f,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",f,"TOPLEFT",18,-78); scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-36,48)
    local output=CreateFrame("EditBox","TUIDebugOutput",scroll)
    output:SetMultiLine(true); output:SetAutoFocus(false); output:SetFontObject(ChatFontNormal); output:SetWidth(690); output:SetHeight(5000); output:SetTextInsets(5,5,5,5)
    output:SetScript("OnEscapePressed",function(e)e:ClearFocus()end); output:SetScript("OnEditFocusGained",function(e)e:HighlightText()end)
    scroll:SetScrollChild(output); self.output=output
    button(f,"刷新日志",78,function()Center:ShowLogs()end):SetPoint("LEFT",filter,"RIGHT",8,0)
    button(f,"状态报告",78,function()Center:ShowReport()end):SetPoint("LEFT",filter,"RIGHT",92,0)
    button(f,"导出报告",78,function()Center:Export()end):SetPoint("LEFT",filter,"RIGHT",176,0)
    button(f,"清空日志",78,function()TUI.Debug:Clear();Center:ShowLogs()end):SetPoint("LEFT",filter,"RIGHT",260,0)
    local hint=f:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); hint:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",22,17)
    hint:SetText("选择文本后 Ctrl+C 复制；日志默认关闭，ERROR 始终保留。")
    self:ShowLogs()
end
function Center:ShowLogs()
    if not self.output then return end
    local moduleName=self.filter:GetText() or "全部"
    local lines={"TUI DEBUG LOG","Filter: "..moduleName,""}
    for _,e in ipairs(TUI.Debug:GetEntries(moduleName)) do lines[#lines+1]=string.format("%s [%s] [%s] %s",e.time,e.module,e.level,e.message) end
    if #lines==3 then lines[#lines+1]="(no log entries)" end
    self.output:SetText(table.concat(lines,"\n")); self.output:SetCursorPosition(0)
end
function Center:ShowReport()
    if not self.output then return end
    self.output:SetText(TUI.Debug:BuildReport(self.filter:GetText())); self.output:SetCursorPosition(0)
end
function Center:Export() self:ShowReport(); self.output:SetFocus(); self.output:HighlightText() end
function Center:Toggle()
    self:Create(); if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end
SLASH_TUIDEBUG1="/tuidebug"
SlashCmdList.TUIDEBUG=function(message)
    local action, state, moduleName=string.match(message or "","^(%S*)%s*(%S*)%s*(.-)%s*$")
    action=string.lower(action or "")
    state=string.lower(state or "")
    if action=="log" and (state=="on" or state=="off") then
        TUI.Debug:SetEnabled(state=="on",moduleName~="" and moduleName or nil)
        TUI:Print("调试日志 "..(state=="on" and "已开启" or "已关闭")..(moduleName~="" and ("： "..moduleName) or "（全局）"))
    else
        Center:Toggle()
    end
end
