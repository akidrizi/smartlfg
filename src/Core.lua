-- src/Core.lua
-- Entry point. Registers WoW events and wires up subsystems.
-- Load order: Constants → Locale → Database → Util → RoleManager → FrameHook → Commands → Core

local addonName, SmartLFG = ...

local Settings = _G.Settings
local InterfaceOptions_AddCategory = _G.InterfaceOptions_AddCategory

local frame = CreateFrame("Frame", "SmartLFGCoreFrame", UIParent)
local optionsRegistered = false

local function RegisterOptionsPanel()
    if optionsRegistered then return end

    local panel = CreateFrame("Frame", "SmartLFGOptionsPanel", UIParent)
    panel.name = addonName

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("CENTER", panel, "CENTER", 0, 50)
    title:SetText(addonName)

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOP", title, "BOTTOM", 0, -10)
    version:SetText(string.format(SmartLFG.L.OPTIONS_VERSION, SmartLFG.GetAddonVersion()))

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hint:SetPoint("TOP", version, "BOTTOM", 0, -16)
    hint:SetText(SmartLFG.L.OPTIONS_HINT)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, addonName, addonName)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    optionsRegistered = true
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
frame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
frame:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
frame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded == addonName then
            SmartLFG.DB.Init()
            RegisterOptionsPanel()
            SmartLFG.Print(string.format(SmartLFG.L.WELCOME, SmartLFG.GetAddonVersion()))
        elseif loaded == "Blizzard_LFGList" then
            SmartLFG.FrameHook.HookLFGList()
        elseif loaded == "Blizzard_LookingForGroup" then
            SmartLFG.FrameHook.HookLFD()
        end

    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        -- Results are now visible in the ScrollBox — hook any new row frames.
        -- This runs regardless of enabled state so hooks are in place when the
        -- player later enables the addon without reloading.
        SmartLFG.FrameHook.HookLFGList()

    elseif not SmartLFG.DB.Get("enabled") then
        -- Central enabled gate: all feature events below this line are suppressed
        -- when the addon is disabled. MakeOnClick carries the equivalent gate for
        -- all click-driven paths. Frame-script OnShow hooks have their own checks.
        return

    elseif event == "LFG_ROLE_CHECK_SHOW" then
        -- Fires when a group leader queues for LFD and all members get a role-check popup.
        SmartLFG.RoleManager.AutoAcceptRoleCheck()

    elseif event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
        -- Tracks listing invitation/acceptance state from WoW, independent of click source.
        local resultID, newStatus, oldStatus = ...
        SmartLFG.RoleManager.OnLFGListApplicationStatusUpdated(resultID, newStatus, oldStatus)

    elseif event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        -- Fires for both the group leader and all members whenever the listing state
        -- changes (group fills, member joins, listing ends). This is the most reliable
        -- point to capture the activity name because C_LFGList.GetActiveEntryInfo()
        -- is fully populated at this moment for everyone involved.
        SmartLFG.RoleManager.OnActiveEntryUpdate()

    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Fires on party/raid roster changes; used to confirm actual listing-source joins.
        SmartLFG.RoleManager.MaybePrintJoinedListingGroup()
    end
end)
