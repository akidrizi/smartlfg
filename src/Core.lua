local addonName, SmartLFG = ...

local frame = CreateFrame("Frame", "SmartLFGCoreFrame", UIParent)

-- Set once our own ADDON_LOADED has run (DB + UI ready), so the frame-hooking
-- attempts below never fire against an uninitialized DB.
local ready = false

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
            SmartLFG.Minimap.Create()
            SmartLFG.Print(string.format(SmartLFG.L.WELCOME, SmartLFG.GetAddonVersion()))
            ready = true
        end

        -- Hook the LFG frames as soon as they exist, whichever addon supplied
        -- them. Matching on a fixed addon name is a trap: Blizzard renames these
        -- across expansions (the Premade Groups UI moved from `Blizzard_LFGList`
        -- to `Blizzard_GroupFinder`), and a stale name fails *silently* — the
        -- hooks simply never install. Both calls are idempotent (guarded by
        -- FrameHook's `hookedFrames`/`onShowHooked` tables) and no-op while their
        -- frames don't exist yet, so retrying on every ADDON_LOADED is cheap and
        -- name-proof.
        if ready then
            SmartLFG.FrameHook.HookLFGList()
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
