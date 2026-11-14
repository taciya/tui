-- TUI Help Center. Lists registered commands and discovers legacy slash commands.
TUI_Help = TUI_Help or {}
local Help=TUI_Help
local function makeButton(parent,label,width,callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,24); b:SetText(label); b:SetScript("OnClick",callback); return b
end
function Help:Create()
    if self.frame then return end
    local f=CreateFrame("Frame","TUIHelpCenterFrame",UIParent,"BasicFrameTemplateWithInset")
    f:SetSize(760,560); f:SetPoint("CENTER"); f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing); f:Hide()
    if f.TitleText then f.TitleText:SetText("TUI 使用说明中心") end
    self.frame=f
    local search=CreateFrame("EditBox","TUIHelpSearch",f,"InputBoxTemplate")
    search:SetSize(260,24); search:SetPoint("TOPLEFT",f,"TOPLEFT",20,-42); search:SetAutoFocus(false); self.search=search
    local categories=CreateFrame("Frame",nil,f); categories:SetPoint("TOPLEFT",f,"TOPLEFT",18,-78); categories:SetSize(170,420); self.categoryFrame=categories
    local scroll=CreateFrame("ScrollFrame","TUIHelpScroll",f,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",f,"TOPLEFT",200,-78); scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-36,48)
    local output=CreateFrame("EditBox","TUIHelpOutput",scroll)
    output:SetMultiLine(true); output:SetAutoFocus(false); output:SetFontObject(ChatFontNormal); output:SetWidth(500); output:SetHeight(5000); output:SetTextInsets(5,5,5,5)
    output:SetScript("OnEscapePressed",function(e)e:ClearFocus()end); output:SetScript("OnEditFocusGained",function(e)e:HighlightText()end)
    scroll:SetScrollChild(output); self.output=output
    makeButton(f,"搜索",64,function()Help:ShowCategory(Help.category or "全部")end):SetPoint("LEFT",search,"RIGHT",8,0)
    makeButton(f,"选择文本复制",110,function()Help.output:SetFocus();Help.output:HighlightText()end):SetPoint("LEFT",search,"RIGHT",80,0)
    local hint=f:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); hint:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",22,17)
    hint:SetText("点击左侧分类查看命令；可选中文本后 Ctrl+C 复制。")
    search:SetScript("OnEnterPressed",function(e)e:ClearFocus();Help:ShowCategory(Help.category or "全部")end)
    self:BuildCategories(); self:ShowCategory("全部")
end
function Help:BuildCategories()
    local categories,seen={"全部"},{["全部"]=true}
    for _,item in ipairs(TUI.Commands:GetAll()) do
        local c=item.category or "其他命令"
        if not seen[c] then seen[c]=true; categories[#categories+1]=c end
    end
    table.sort(categories)
    for _,child in ipairs({self.categoryFrame:GetChildren()}) do child:Hide() end
    local y=-2
    for _,category in ipairs(categories) do
        local name=category
        local b=makeButton(self.categoryFrame,name,158,function()Help:ShowCategory(name)end)
        b:SetPoint("TOPLEFT",self.categoryFrame,"TOPLEFT",0,y); y=y-29
    end
end
function Help:ShowCategory(category)
    if not self.output then return end
    self.category=category
    local query=string.lower(self.search:GetText() or "")
    local lines={"TUI 使用说明中心","分类: "..category,""}
    for _,item in ipairs(TUI.Commands:GetAll()) do
        local usage=type(item.usage)=="table" and table.concat(item.usage," ") or (item.usage or "")
        local hay=string.lower(table.concat({item.command or "",item.name or "",item.description or "",usage}," "))
        if (category=="全部" or (item.category or "其他命令")==category) and (query=="" or string.find(hay,query,1,true)) then
            lines[#lines+1]=(item.name or item.command).." ["..(item.status or "已注册").."]"
            lines[#lines+1]="命令: "..(item.command or "")
            if item.description then lines[#lines+1]="说明: "..item.description end
            if usage~="" then lines[#lines+1]="用法: "..usage end
            if type(item.examples)=="table" then for _,example in ipairs(item.examples) do lines[#lines+1]="示例: "..example end end
            lines[#lines+1]=""
        end
    end
    if #lines==3 then lines[#lines+1]="没有匹配的命令或说明。" end
    self.output:SetText(table.concat(lines,"\n")); self.output:SetCursorPosition(0)
end
function Help:Toggle()
    self:Create(); if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end
SLASH_TUIHELP1="/tuihelp"
SlashCmdList.TUIHELP=function()Help:Toggle()end
