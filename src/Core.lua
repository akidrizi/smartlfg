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
        SmartLFG.FrameHook.HookLFGList()

    elseif event == "LFG_ROLE_CHECK_SHOW" then
        -- Fires when a group leader queues for LFD and all members get a role-check popup.
        SmartLFG.RoleManager.AutoAcceptRoleCheck()
    end
end)
