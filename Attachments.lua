-- Sequentially loot non-COD mail attachments. The button is created lazily,
-- because the mailbox UI is load-on-demand on current clients.
local L = TUI_LOCALE or { ["take attachments"] = "Take Attachments", stop = "Stop", ["no attachments"] = "No attachments" }
local current = nil
local previousMoney = 0
local button

local function inboxCount()
    return (GetInboxNumItems and GetInboxNumItems()) or 0
end

local function peekInbox()
    for index = 1, inboxCount() do
        local _, _, sender, subject, money, cod, _, hasItem = GetInboxHeaderInfo(index)
        money, cod = money or 0, cod or 0
        local itemCount = 0
        if hasItem and GetInboxItem then
            for attachmentIndex = 1, 12 do
                local itemName = GetInboxItem(index, attachmentIndex)
                if not itemName then break end
                itemCount = itemCount + 1
            end
        end
        if sender and cod == 0 and (money > 0 or itemCount > 0) then
            return { id = index, sender = sender, subject = subject, money = money, items = itemCount }
        end
    end
end

local function moneyText(amount)
    if not amount or amount <= 0 then return nil end
    local gold = math.floor(amount / 10000)
    local silver = math.floor(amount / 100) % 100
    local copper = amount % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. (GOLD_AMOUNT and "g" or "g") end
    if silver > 0 then parts[#parts + 1] = silver .. "s" end
    if copper > 0 then parts[#parts + 1] = copper .. "c" end
    return table.concat(parts, " ")
end

local function updateButton()
    if not button then return end
    local nextMail = peekInbox()
    if current then
        button:SetText(L.stop)
        button:Enable()
    elseif nextMail then
        button:SetText(L["take attachments"])
        button:Enable()
    else
        button:SetText(L["no attachments"])
        button:Disable()
    end
end

local function processNext()
    current = peekInbox()
    if current and AutoLootMailItem then
        button:SetText(L.stop)
        AutoLootMailItem(current.id)
    else
        current = nil
        updateButton()
    end
end

local function createButton()
    if button or not InboxFrame then return end
    button = CreateFrame("Button", "TUIAttachmentsButton", InboxFrame, "UIPanelButtonTemplate")
    button:SetSize(128, 24)
    button:SetPoint("TOPLEFT", InboxFrame, "TOPLEFT", 72, -41)
    button:SetScript("OnClick", function(self)
        if current then
            current = nil
            updateButton()
        else
            processNext()
        end
    end)
    updateButton()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("ITEM_PUSH")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "MAIL_SHOW" then
        createButton()
        updateButton()
    elseif event == "MAIL_INBOX_UPDATE" then
        if not button then createButton() end
        updateButton()
    elseif event == "PLAYER_ENTERING_WORLD" then
        previousMoney = (GetMoney and GetMoney()) or 0
    elseif event == "PLAYER_MONEY" then
        local money = (GetMoney and GetMoney()) or previousMoney
        local gained = money - previousMoney
        previousMoney = money
        if current and current.money > 0 and gained >= current.money then
            local report = moneyText(current.money)
            if report and DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00%s|r %s [%s]", current.sender, report, current.subject or UNKNOWN or ""))
            end
            current.money = 0
        end
        if current and current.money <= 0 and current.items <= 0 then processNext() end
    elseif event == "ITEM_PUSH" then
        if current and current.items > 0 then
            current.items = current.items - 1
            if current.money <= 0 and current.items <= 0 then processNext() end
        end
    elseif event == "MAIL_CLOSED" then
        current = nil
        if MiniMapMailFrame and inboxCount() == 0 then MiniMapMailFrame:Hide() end
    end
end)
