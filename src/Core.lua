local addonName, SmartLFG = ...

local Settings = _G.Settings
local InterfaceOptions_AddCategory = _G.InterfaceOptions_AddCategory

local frame = CreateFrame("Frame", "SmartLFGCoreFrame", UIParent)
local optionsRegistered = false

--- Creates and registers the in-game options panel under Interface → AddOns.
--- Supports both the modern Settings API (WoW 10.x+) and the legacy
--- InterfaceOptions_AddCategory fallback. Runs once; subsequent calls are no-ops.
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

--- Central event dispatcher. Handles addon lifecycle, frame hooking, and all
--- feature events. LFG_LIST_SEARCH_RESULTS_RECEIVED and ADDON_LOADED bypass
--- the enabled gate so hooks are always in place. All other feature events
--- return early when the addon is disabled.
--- @param event string  WoW event name.
--- @param ...   any     Event payload arguments.
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
        SmartLFG.FrameHook.HookLFGList()

    elseif not SmartLFG.DB.Get("enabled") then
        return

    elseif event == "LFG_ROLE_CHECK_SHOW" then
        SmartLFG.RoleManager.AutoAcceptRoleCheck()

    elseif event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
        local resultID, newStatus, oldStatus = ...
        SmartLFG.RoleManager.OnLFGListApplicationStatusUpdated(resultID, newStatus, oldStatus)

    elseif event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        SmartLFG.RoleManager.OnActiveEntryUpdate()

    elseif event == "GROUP_ROSTER_UPDATE" then
        SmartLFG.RoleManager.MaybePrintJoinedListingGroup()
    end
end)
