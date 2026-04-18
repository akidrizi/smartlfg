local addonName, SmartLFG = ...

local Settings = _G.Settings
local InterfaceOptions_AddCategory = _G.InterfaceOptions_AddCategory

local frame = CreateFrame("Frame", "SmartLFGCoreFrame", UIParent)
local optionsRegistered = false

local function RegisterOptionsPanel()
    if optionsRegistered then return end

    local panel = CreateFrame("Frame", "SmartLFGOptionsPanel", UIParent)
    panel.name = addonName
    panel:SetSize(900, 700)

    local face, _, flags = GameFontNormal:GetFont()
    local C = SmartLFG.COLOR

    local title = panel:CreateFontString(nil, "ARTWORK")
    title:SetFont(face, 72, flags)
    title:SetPoint("CENTER", panel, "CENTER", 0, 60)
    title:SetJustifyH("CENTER")
    title:SetText(C.ADDON .. addonName .. C.RESET)

    local version = panel:CreateFontString(nil, "ARTWORK")
    version:SetFont(face, 32, flags)
    version:SetPoint("CENTER", panel, "CENTER", 0, -10)
    version:SetJustifyH("CENTER")
    version:SetText(string.format(SmartLFG.L.OPTIONS_VERSION, SmartLFG.GetAddonVersion()))

    local hint = panel:CreateFontString(nil, "ARTWORK")
    hint:SetFont(face, 62, flags)
    hint:SetPoint("CENTER", panel, "CENTER", 0, -90)
    hint:SetJustifyH("CENTER")
    hint:SetText(C.ADDON .. "/slfg" .. C.RESET)

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
