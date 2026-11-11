-- Keep Blizzard's raid-style party header visible while playing solo.
-- The party header is distinct from CompactRaidFrameContainer.
local function isSolo()
    if IsInRaid and IsInRaid() then return false end
    if IsInGroup then return not IsInGroup() end
    return not (UnitExists and UnitExists("party1"))
end

local function showFrame(frame)
    if frame and frame.Show then
        pcall(frame.Show, frame)
    end
end

local function applySoloRaidFrame()
    if not isSolo() then return end

    if SetCVar then
        pcall(SetCVar, "raidOptionIsShown", "1")
    end

    if CompactRaidFrameManager_SetSetting then
        pcall(CompactRaidFrameManager_SetSetting, "IsShown", "1")
    end

    -- In raid-style party mode the solo player is hosted by the Party Header.
    -- Showing only CompactRaidFrameContainer does not make this header visible.
    showFrame(_G.CompactPartyFrame)
    showFrame(_G.CompactPartyFrameMember1)

    -- Keep the raid container available for the native raid-style layout.
    showFrame(_G.CompactRaidFrameContainer)

    local manager = _G.CompactRaidFrameManager
    if manager and CompactRaidFrameManager_UpdateShown then
        pcall(CompactRaidFrameManager_UpdateShown, manager)
    end

    -- Blizzard's visibility refresh can hide the Party Header again.
    -- Re-show it after the refresh has completed.
    showFrame(_G.CompactPartyFrame)
    showFrame(_G.CompactPartyFrameMember1)
    showFrame(_G.CompactRaidFrameContainer)
end

TUI:RegisterModule("SoloRaidFrame", function()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", applySoloRaidFrame)

    if hooksecurefunc and CompactRaidFrameManager_UpdateContainerVisibility then
        hooksecurefunc("CompactRaidFrameManager_UpdateContainerVisibility", function()
            if isSolo() then
                showFrame(_G.CompactPartyFrame)
                showFrame(_G.CompactPartyFrameMember1)
                showFrame(_G.CompactRaidFrameContainer)
            end
        end)
    end

    if hooksecurefunc and CompactRaidFrameManager_UpdateShown then
        hooksecurefunc("CompactRaidFrameManager_UpdateShown", function()
            if isSolo() then
                showFrame(_G.CompactPartyFrame)
                showFrame(_G.CompactPartyFrameMember1)
            end
        end)
    end

    applySoloRaidFrame()
end)
