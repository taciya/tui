-- Mail helper: each mail is collected only from a direct user click.
-- Do not chain protected mail actions from MAIL_INBOX_UPDATE / ITEM_PUSH events.
local L = TUI_LOCALE or {}
local TAKE_TEXT = L["take attachments"] or "领取下一封"
local EMPTY_TEXT = L["no attachments"] or "没有可领取的邮件"
local BUSY_TEXT = L.collecting or "领取中…"

local button
local pendingMail

local function getMail(index)
    if not GetInboxHeaderInfo then return nil end
    local _, _, sender, subject, money, cod, _, hasItem = GetInboxHeaderInfo(index)
    if not sender then return nil end

    money = tonumber(money) or 0
    cod = tonumber(cod) or 0
    local itemCount = 0
    if hasItem and GetInboxItem then
        for attachmentIndex = 1, 12 do
            local itemName = GetInboxItem(index, attachmentIndex)
            if not itemName then break end
            itemCount = itemCount + 1
        end
    end

    return {
        index = index,
        sender = sender,
        subject = subject or "",
        money = money,
        cod = cod,
        items = itemCount,
    }
end

local function findNextMail()
    local count = (GetInboxNumItems and GetInboxNumItems()) or 0
    for index = 1, count do
        local mail = getMail(index)
        if mail and mail.cod == 0 and (mail.money > 0 or mail.items > 0) then
            return mail
        end
    end
end

local function pendingStillExists()
    if not pendingMail then return false end
    local mail = getMail(pendingMail.index)
    if not mail then return false end
    return mail.sender == pendingMail.sender
        and mail.subject == pendingMail.subject
        and (mail.money > 0 or mail.items > 0)
end

local function updateButton()
    if not button then return end
    if pendingMail and pendingStillExists() then
        button:SetText(BUSY_TEXT)
        button:Disable()
        return
    end

    pendingMail = nil
    if findNextMail() then
        button:SetText(TAKE_TEXT)
        button:Enable()
    else
        button:SetText(EMPTY_TEXT)
        button:Disable()
    end
end

local function collectOneMail()
    if InCombatLockdown and InCombatLockdown() then
        if TUI and TUI.Print then TUI:Print("战斗中不能领取邮件") end
        return
    end

    local mail = findNextMail()
    if not mail then
        updateButton()
        return
    end

    pendingMail = mail
    local attempted, failed = 0, false

    -- These protected actions are intentionally called only from the button's
    -- hardware-click handler, never from an event callback.
    if mail.money > 0 then
        if TakeInboxMoney then
            local ok, err = pcall(TakeInboxMoney, mail.index)
            if ok then attempted = attempted + 1
            else
                failed = true
                if TUI and TUI.Print then TUI:Print("领取邮件金币失败：" .. tostring(err)) end
            end
        else
            failed = true
            if TUI and TUI.Print then TUI:Print("当前客户端不支持 TakeInboxMoney") end
        end
    end

    if mail.items > 0 then
        if AutoLootMailItem then
            local ok, err = pcall(AutoLootMailItem, mail.index)
            if ok then attempted = attempted + 1
            else
                failed = true
                if TUI and TUI.Print then TUI:Print("领取邮件附件失败：" .. tostring(err)) end
            end
        else
            failed = true
            if TUI and TUI.Print then TUI:Print("当前客户端不支持 AutoLootMailItem") end
        end
    end

    -- If only part of a message was collected, let the user retry the remainder.
    if attempted == 0 or failed then pendingMail = nil end
    updateButton()
end

local function createButton()
    if button then return end
    local parent = InboxFrame or MailFrame
    if not parent then return end

    button = CreateFrame("Button", "TUIAttachmentsButton", parent, "UIPanelButtonTemplate")
    button:SetSize(128, 24)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 72, -41)
    button:SetScript("OnClick", collectOneMail)
    updateButton()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "MAIL_SHOW" then
        createButton()
        updateButton()
    elseif event == "MAIL_INBOX_UPDATE" then
        if not button then createButton() end
        updateButton()
    elseif event == "PLAYER_MONEY" then
        updateButton()
    elseif event == "MAIL_CLOSED" then
        pendingMail = nil
        if button then button:Disable() end
    end
end)
