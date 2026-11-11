-- Keep Blizzard's raid frame manager/container visible while playing solo.
-- Inspired by Solo Raid Frame NV.
local function isSolo()
    if IsInRaid and IsInRaid() then return false end
    if IsInGroup then return not IsInGroup() end
    return not (UnitExists and UnitExists("party1"))
end

local function applySoloRaidFrame()
    if not isSolo() then return end

    -- "IsShown" is backed by raidOptionIsShown. The manager setting expects
    -- the CVar-style string value ("1"), not a boolean.
    if SetCVar then
        pcall(SetCVar, "raidOptionIsShown", "1")
    end

    if CompactRaidFrameManager_SetSetting then
        pcall(CompactRaidFrameManager_SetSetting, "IsShown", "1")
    end

    local manager = _G.CompactRaidFrameManager
    if manager and CompactRaidFrameManager_UpdateShown then
        pcall(CompactRaidFrameManager_UpdateShown, manager)
    elseif manager and manager.Show then
        pcall(manager.Show, manager)
    end

    if CompactRaidFrameManager_UpdateContainerVisibility then
        pcall(CompactRaidFrameManager_UpdateContainerVisibility)
    end

    local container = _G.CompactRaidFrameContainer
    if container and container.Show then
        pcall(container.Show, container)
    end
end

TUI:RegisterModule("SoloRaidFrame", function()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function()
        -- Try immediately even in combat. Protected frame operations may be
        -- rejected by the client during combat; PLAYER_REGEN_ENABLED retries.
        applySoloRaidFrame()
    end)

    -- Blizzard may refresh visibility after roster/manager updates.
    if hooksecurefunc and CompactRaidFrameManager_UpdateContainerVisibility then
        hooksecurefunc("CompactRaidFrameManager_UpdateContainerVisibility", function()
            if isSolo() then
                local container = _G.CompactRaidFrameContainer
                if container and container.Show then
                    pcall(container.Show, container)
                end
            end
        end)
    end

    applySoloRaidFrame()
end)
