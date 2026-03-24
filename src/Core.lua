-- src/Core.lua
-- Entry point. Registers WoW events and wires up subsystems.
-- Load order: Constants → Database → Util → RoleManager → FrameHook → Commands → Core

local addonName, SmartLFG = ...

local frame = CreateFrame("Frame", "SmartLFGCoreFrame", UIParent)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
frame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded == addonName then
            SmartLFG.DB.Init()
            SmartLFG.Print("v" .. SmartLFG.GetAddonVersion() .. "  ·  /slfg help")
        elseif loaded == "Blizzard_LFGList" then
            SmartLFG.FrameHook.HookLFGList()
        elseif loaded == "Blizzard_LookingForGroup" then
            SmartLFG.FrameHook.HookLFD()
        end

    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        -- Results are now visible in the ScrollBox — hook any new row frames.
        SmartLFG.FrameHook.HookLFGList()

    elseif event == "LFG_ROLE_CHECK_SHOW" then
        -- Fires when a group leader queues for LFD and all members get a role-check popup.
        SmartLFG.RoleManager.AutoAcceptRoleCheck()
    end
end)
