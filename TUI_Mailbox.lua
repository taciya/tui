-- TUI Mailbox: saved whisper recipients and sequential message sending.
-- Recipient data is stored in the account-wide TUI_Mail_List SavedVariable.

TUI_Mail_List = TUI_Mail_List or {}

local selected = {}
local rows = {}
local sendQueue
local sendIndex = 0
local sendStats = { sent = 0, failed = {}, stopped = false }

local function mailPrint(message)
    if TUI_Print then TUI_Print(message)
    elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(message) end
end

local function trimName(value)
    return (string.gsub(value or "", "^%s*(.-)%s*$", "%1"))
end

local function normalizeList()
    local clean, seen = {}, {}
    for _, value in ipairs(TUI_Mail_List) do
        local name = trimName(type(value) == "table" and (value.name or value[1]) or value)
        local key = string.lower(name)
        if name ~= "" and not seen[key] then
            clean[#clean + 1] = name
            seen[key] = true
        end
    end
    TUI_Mail_List = clean
end

normalizeList()

local function createText(parent, text, size, justify)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetText(text or "")
    fs:SetJustifyH(justify or "LEFT")
    if size then fs:SetWidth(size) end
    return fs
end

local function createButton(parent, label, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

local function updateStatus()
    if TUI_MailboxStatus then
        if sendQueue then
            TUI_MailboxStatus:SetText(string.format("正在发送：%d / %d（成功 %d）",
                math.min(sendIndex - 1, #sendQueue), #sendQueue, sendStats.sent))
        else
            TUI_MailboxStatus:SetText("通讯录：" .. #TUI_Mail_List .. " 人")
        end
    end
end

local function refreshRows()
    if not TUI_MailboxRows then return end
    for _, row in ipairs(rows) do row:Hide() end
    wipe(rows)
    for index, name in ipairs(TUI_Mail_List) do
        local row = CreateFrame("Frame", nil, TUI_MailboxRows)
        row:SetSize(350, 24)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 26)

        local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        check:SetSize(22, 22)
        check:SetPoint("LEFT", 0, 0)
        check:SetChecked(selected[name] == true)
        check:SetScript("OnClick", function(self)
            selected[name] = self:GetChecked() and true or nil
        end)

        local label = createText(row, name, 235)
        label:SetPoint("LEFT", check, "RIGHT", 4, 0)

        local remove = createButton(row, "删除", 54, function()
            selected[name] = nil
            table.remove(TUI_Mail_List, index)
            refreshRows()
            updateStatus()
        end)
        remove:SetPoint("RIGHT", 0, 0)
        rows[#rows + 1] = row
        row:Show()
    end
    TUI_MailboxRows:SetHeight(math.max(1, #TUI_Mail_List * 26))
    updateStatus()
end

local function addRecipient()
    local name = trimName(TUI_MailboxRecipient:GetText())
    if name == "" then
        mailPrint("请输入收件人角色名")
        return
    end
    if string.find(name, "[,;|%c]") then
        mailPrint("收件人名称格式无效")
        return
    end
    for _, existing in ipairs(TUI_Mail_List) do
        if string.lower(existing) == string.lower(name) then
            mailPrint(name .. " 已在通讯录中")
            return
        end
    end
    TUI_Mail_List[#TUI_Mail_List + 1] = name
    TUI_MailboxRecipient:SetText("")
    refreshRows()
end

local function finishSending()
    local summary = string.format("发件箱发送结束：成功 %d 人，失败 %d 人",
        sendStats.sent, #sendStats.failed)
    if sendStats.stopped then summary = summary .. "（已手动停止）" end
    mailPrint(summary)
    for _, name in ipairs(sendStats.failed) do
        mailPrint("发送失败：" .. name)
    end
    sendQueue = nil
    updateStatus()
end

local function sendNext()
    if not sendQueue then return end
    if sendIndex > #sendQueue then
        finishSending()
        return
    end

    local recipient = sendQueue[sendIndex]
    sendIndex = sendIndex + 1
    local sendChat = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    local ok, err = pcall(function()
        if not sendChat then error("当前客户端没有聊天发送 API") end
        sendChat(sendQueue.message, "WHISPER", nil, recipient)
    end)

    if ok then
        sendStats.sent = sendStats.sent + 1
    else
        sendStats.failed[#sendStats.failed + 1] = recipient
        mailPrint("发送给 " .. recipient .. " 时发生错误：" .. tostring(err))
    end
    updateStatus()

    if C_Timer and C_Timer.After then
        C_Timer.After(1.5, sendNext)
    else
        finishSending()
        mailPrint("当前客户端缺少 C_Timer，无法继续逐个发送")
    end
end

local function beginSending()
    if sendQueue then
        mailPrint("当前正在发送，请等待完成或点击停止")
        return
    end
    local message = trimName(TUI_MailboxMessage:GetText())
    if message == "" then
        mailPrint("请先输入要发送的消息")
        return
    end
    if string.len(message) > 255 then
        mailPrint("消息超过 255 字节，请缩短内容")
        return
    end
    local recipients = {}
    for _, name in ipairs(TUI_Mail_List) do
        if selected[name] then recipients[#recipients + 1] = name end
    end
    if #recipients == 0 then
        mailPrint("请至少勾选一位收件人")
        return
    end
    if not (C_Timer and C_Timer.After) then
        mailPrint("当前客户端缺少 C_Timer，无法安全地逐个发送")
        return
    end

    sendQueue = recipients
    sendQueue.message = message
    sendIndex = 1
    sendStats = { sent = 0, failed = {}, stopped = false }
    updateStatus()
    sendNext()
end

local function stopSending()
    if not sendQueue then return end
    sendStats.stopped = true
    -- The next scheduled callback sees this flag and ends without sending more.
    sendQueue = nil
    finishSending()
end

local function createMailbox()
    if TUI_MailboxFrame then return end
    local frame = CreateFrame("Frame", "TUI_MailboxFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(440, 570)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    frame.TitleText:SetText("TUI 发件箱")

    local recipientLabel = createText(frame, "添加收件人")
    recipientLabel:SetPoint("TOPLEFT", 18, -42)

    local recipient = CreateFrame("EditBox", "TUI_MailboxRecipient", frame, "InputBoxTemplate")
    recipient:SetSize(270, 24)
    recipient:SetPoint("TOPLEFT", 22, -62)
    recipient:SetAutoFocus(false)
    recipient:SetMaxLetters(64)
    recipient:SetScript("OnEnterPressed", function(self) addRecipient(); self:ClearFocus() end)

    local add = createButton(frame, "添加", 70, addRecipient)
    add:SetPoint("LEFT", recipient, "RIGHT", 12, 0)

    local listLabel = createText(frame, "收件人通讯录（勾选要发送的对象）")
    listLabel:SetPoint("TOPLEFT", 18, -100)

    local scroll = CreateFrame("ScrollFrame", "TUI_MailboxScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -122)
    scroll:SetPoint("TOPRIGHT", -38, -122)
    scroll:SetHeight(205)

    local rowsFrame = CreateFrame("Frame", "TUI_MailboxRows", scroll)
    rowsFrame:SetSize(350, 1)
    scroll:SetScrollChild(rowsFrame)

    local messageLabel = createText(frame, "消息正文（游戏密语，无邮件标题）")
    messageLabel:SetPoint("TOPLEFT", 18, -340)

    local message = CreateFrame("EditBox", "TUI_MailboxMessage", frame, "InputBoxTemplate")
    message:SetSize(385, 70)
    message:SetPoint("TOPLEFT", 22, -362)
    message:SetMultiLine(true)
    message:SetAutoFocus(false)
    message:SetMaxLetters(255)
    message:SetTextInsets(6, 6, 6, 6)

    local status = createText(frame, "")
    status:SetPoint("BOTTOMLEFT", 20, 52)
    status:SetWidth(390)

    local send = createButton(frame, "发送给勾选对象", 150, function()
        StaticPopup_Show("TUI_MAILBOX_CONFIRM")
    end)
    send:SetPoint("BOTTOMLEFT", 20, 18)

    local stop = createButton(frame, "停止发送", 90, stopSending)
    stop:SetPoint("LEFT", send, "RIGHT", 10, 0)

    local close = createButton(frame, "关闭", 70, function() frame:Hide() end)
    close:SetPoint("RIGHT", -18, 18)

    TUI_MailboxRows = rowsFrame
    TUI_MailboxStatus = status
    refreshRows()
end

StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs.TUI_MAILBOX_CONFIRM = {
    text = "确定向所有已勾选的收件人发送这条密语？",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        if TUI_MailboxFrame and TUI_MailboxFrame:IsShown() then beginSending() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

SLASH_TUIMAIL1 = "/mail"
SLASH_TUIMAIL2 = "/tmail"
SlashCmdList["TUIMAIL"] = function()
    createMailbox()
    refreshRows()
    TUI_MailboxFrame:Show()
end
