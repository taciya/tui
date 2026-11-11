-- Keep Blizzard's raid-style party frame visible while playing solo.
-- Inspired by the lightweight approach used by Solo Raid Frame NV.
local function isSolo()
    if IsInGroup then return not IsInGroup() end
    if IsInRaid and IsInRaid() then return false end
    return not (UnitExists and UnitExists("party1"))
end

local function applySoloRaidFrame()
    if not isSolo() then return end
    if InCombatLockdown and InCombatLockdown() then return end

    -- Use Blizzard's compact raid-style party frames.
    if GetCVar and SetCVar and GetCVar("useCompactPartyFrames") ~= "1" then
        SetCVar("useCompactPartyFrames", "1")
    end

    if CompactRaidFrameManager_SetSetting then
        CompactRaidFrameManager_SetSetting("IsShown", true)
    end

    local manager = _G.CompactRaidFrameManager
    if manager and CompactRaidFrameManager_UpdateShown then
        CompactRaidFrameManager_UpdateShown(manager)
    end

    if CompactRaidFrameManager_UpdateContainerVisibility then
        CompactRaidFrameManager_UpdateContainerVisibility()
    end

    -- Some client builds hide the container again when refreshing the
    -- manager in solo mode. Show it after the Blizzard visibility update.
    local container = _G.CompactRaidFrameContainer
    if container and container.Show then
        container:Show()
    end
end

TUI:RegisterModule("SoloRaidFrame", function()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function()
        applySoloRaidFrame()
    end)

    -- Re-apply after Blizzard's raid-frame manager refreshes its visibility.
    if hooksecurefunc and CompactRaidFrameManager_UpdateContainerVisibility then
        hooksecurefunc("CompactRaidFrameManager_UpdateContainerVisibility", function()
            if isSolo() and not (InCombatLockdown and InCombatLockdown()) then
                local container = _G.CompactRaidFrameContainer
                if container and container.Show then container:Show() end
            end
        end)
    end

    applySoloRaidFrame()
end)
