-- TUI in-game mail address book.
-- Selecting a contact fills the native mail recipient field; it does not send mail.
TUI_Mail_Contacts = TUI_Mail_Contacts or {}

local button
local panel
local rows = {}

local function trim(value)
    return (string.gsub(value or "", "^%s*(.-)%s*$", "%1"))
end

local function printMessage(message)
    if TUI and TUI.Print then
        TUI:Print(message)
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    end
end

local function getRecipientBox()
    return _G.SendMailNameEditBox
end

local function normalizeContacts()
    if type(TUI_Mail_Contacts) ~= "table" then
        TUI_Mail_Contacts = {}
        return
    end

    local clean, seen = {}, {}
    for _, value in ipairs(TUI_Mail_Contacts) do
        local name = trim(type(value) == "string" and value or "")
        local key = string.lower(name)
        if name ~= "" and not seen[key] then
            clean[#clean + 1] = name
            seen[key] = true
        end
    end
    TUI_Mail_Contacts = clean
end

local function refreshRows()
    if not panel then return end

    for _, row in ipairs(rows) do
        row:Hide()
    end
    wipe(rows)

    for index, name in ipairs(TUI_Mail_Contacts) do
        local row = CreateFrame("Frame", nil, panel)
        row:SetSize(230, 24)
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -42 - (index - 1) * 27)

        local selectButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        selectButton:SetSize(165, 22)
        selectButton:SetPoint("LEFT", row, "LEFT", 0, 0)
        selectButton:SetText(name)
        selectButton:SetScript("OnClick", function()
            local recipientBox = getRecipientBox()
            if recipientBox then
                recipientBox:SetText(name)
                recipientBox:SetCursorPosition(string.len(name))
                panel:Hide()
            else
                printMessage("找不到游戏邮箱的收件人输入框")
            end
        end)

        local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        deleteButton:SetSize(52, 22)
        deleteButton:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        deleteButton:SetText("删除")
        deleteButton:SetScript("OnClick", function()
            table.remove(TUI_Mail_Contacts, index)
            refreshRows()
        end)

        rows[#rows + 1] = row
        row:Show()
    end

    panel:SetHeight(math.max(78, 52 + #TUI_Mail_Contacts * 27))
end

local function addCurrentRecipient()
    local recipientBox = getRecipientBox()
    if not recipientBox then
        printMessage("找不到游戏邮箱的收件人输入框")
        return
    end

    local name = trim(recipientBox:GetText())
    if name == "" then
        printMessage("请先在游戏邮箱的收件人栏输入角色名")
        return
    end
    if string.find(name, "[,;|%c]") then
        printMessage("收件人名称格式无效")
        return
    end

    for _, existing in ipairs(TUI_Mail_Contacts) do
        if string.lower(existing) == string.lower(name) then
            printMessage(name .. " 已在通讯录中")
            return
        end
    end

    TUI_Mail_Contacts[#TUI_Mail_Contacts + 1] = name
    refreshRows()
    printMessage("已将 " .. name .. " 添加到邮箱通讯录")
end

local function createAddressBook()
    if button then return end

    local recipientBox = getRecipientBox()
    if not recipientBox then return end

    local parent = _G.SendMailFrame or recipientBox:GetParent()
    if not parent then return end

    button = CreateFrame("Button", "TUI_MailAddressBookButton", parent, "UIPanelButtonTemplate")
    button:SetSize(76, 22)
    button:SetPoint("LEFT", recipientBox, "RIGHT", 8, 0)
    button:SetText("通讯录")

    panel = CreateFrame("Frame", "TUI_MailAddressBookPanel", parent)
    panel:SetSize(250, 78)
    panel:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -4)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    panel:Hide()

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
    title:SetText("邮箱收件人通讯录")

    local addButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addButton:SetSize(76, 22)
    addButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -6)
    addButton:SetText("保存当前")
    addButton:SetScript("OnClick", addCurrentRecipient)

    button:SetScript("OnClick", function()
        if panel:IsShown() then
            panel:Hide()
        else
            refreshRows()
            panel:Show()
        end
    end)

    refreshRows()
end

normalizeContacts()

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    createAddressBook()
end)
