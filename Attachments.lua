-- Mail helper: each mail is collected only from a direct user click.
-- Do not chain protected mail actions from MAIL_INBOX_UPDATE / ITEM_PUSH events.
local L = TUI_LOCALE or {
    ["take attachments"] = "领取下一封",
    ["no attachments"] = "没有可领取的邮件",
    ["collecting"] = "领取中…",
}

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
        button:SetText(L.collecting)
        button:Disable()
        return
    end

    pendingMail = nil
    if findNextMail() then
        button:SetText(L["take attachments"])
        button:Enable()
    else
        button:SetText(L["no attachments"])
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
    local didAction = false

    -- These protected actions are intentionally called only in the button's
    -- hardware-click handler, never from an event callback.
    if mail.money > 0 then
        if TakeInboxMoney then
            TakeInboxMoney(mail.index)
            didAction = true
        else
            if TUI and TUI.Print then TUI:Print("当前客户端不支持 TakeInboxMoney") end
        end
    end

    if mail.items > 0 then
        if AutoLootMailItem then
            AutoLootMailItem(mail.index)
            didAction = true
        else
            if TUI and TUI.Print then TUI:Print("当前客户端不支持 AutoLootMailItem") end
        end
    end

    if not didAction then
        pendingMail = nil
    end
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
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "MAIL_SHOW" then
        createButton()
        updateButton()
    elseif event == "MAIL_INBOX_UPDATE" then
        if not button then createButton() end
        updateButton()
    elseif event == "MAIL_CLOSED" then
        pendingMail = nil
        if button then button:Disable() end
    end
end)
