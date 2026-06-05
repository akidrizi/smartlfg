local addonName, SmartLFG = ...

local frame = CreateFrame("Frame", "SmartLFGCoreFrame", UIParent)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
frame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded == addonName then
            SmartLFG.DB.Init()
            SmartLFG.Options.Register()
            SmartLFG.Print(string.format(SmartLFG.L.WELCOME, SmartLFG.GetAddonVersion()))
        elseif loaded == "Blizzard_LFGList" then
            SmartLFG.FrameHook.HookLFGList()
        elseif loaded == "Blizzard_LookingForGroup" then
            SmartLFG.FrameHook.HookLFD()
        end

    elseif event == "PLAYER_LOGIN" then
        -- Spec data is reliably available now; seed the role on first run.
        SmartLFG.RoleManager.PreselectRoleFromSpec()

    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        SmartLFG.FrameHook.HookLFGList()

    elseif not SmartLFG.DB.Get("enabled") then
        return

    elseif event == "LFG_ROLE_CHECK_SHOW" then
        SmartLFG.RoleManager.AutoAcceptRoleCheck()
    end
end)
