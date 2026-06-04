local addonName, SmartLFG = ...

local Settings                          = _G.Settings
local InterfaceOptions_AddCategory      = _G.InterfaceOptions_AddCategory
local InterfaceOptionsFrame_OpenToCategory = _G.InterfaceOptionsFrame_OpenToCategory

SmartLFG.Options = {}
local O = SmartLFG.Options

local panel          -- the canvas frame
local categoryID     -- modern Settings category id (for OpenToCategory)
local enabledCheck   -- the enable checkbox
local roleButtons = {}  -- role token -> button

-- ── One role icon button ────────────────────────────────────────────────────
-- A single building block: a clickable native role icon. Selecting it stores
-- the role; invalid-for-class roles are desaturated and non-interactive.
local function CreateRoleButton(parent, role)
    local btn = CreateFrame("Button", "SmartLFGRole" .. role, parent)
    btn:SetSize(40, 40)
    btn.role = role

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetAtlas(SmartLFG.ROLE_ATLAS[role], false)
    btn.icon = icon

    -- Selection glow, shown only for the active role (managed in Refresh).
    local check = btn:CreateTexture(nil, "OVERLAY")
    check:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    check:SetBlendMode("ADD")
    check:SetPoint("TOPLEFT", -3, 3)
    check:SetPoint("BOTTOMRIGHT", 3, -3)
    check:Hide()
    btn.check = check

    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    btn:SetScript("OnClick", function(self)
        if not SmartLFG.GetAvailableRoles()[self.role] then return end
        SmartLFG.ToggleRole(self.role)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        O.Refresh()
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(SmartLFG.GetRoleName(self.role))
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return btn
end

-- ── Build the panel once ────────────────────────────────────────────────────
local function BuildPanel()
    local C, L = SmartLFG.COLOR, SmartLFG.L

    panel = CreateFrame("Frame", "SmartLFGOptionsPanel", UIParent)
    panel.name = addonName

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(C.ADDON .. addonName .. C.RESET)

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    version:SetText(string.format(L.OPTIONS_VERSION, SmartLFG.GetAddonVersion()))

    -- Enable checkbox + description
    enabledCheck = CreateFrame("CheckButton", "SmartLFGEnabledCheck", panel, "UICheckButtonTemplate")
    enabledCheck:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -24)

    local enabledLabel = enabledCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    enabledLabel:SetPoint("LEFT", enabledCheck, "RIGHT", 4, 0)
    enabledLabel:SetText(L.OPTIONS_ENABLE)

    local enabledDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    enabledDesc:SetPoint("TOPLEFT", enabledCheck, "BOTTOMLEFT", 4, -4)
    enabledDesc:SetWidth(520)
    enabledDesc:SetJustifyH("LEFT")
    enabledDesc:SetText(L.OPTIONS_ENABLE_DESC)

    enabledCheck:SetScript("OnClick", function(self)
        SmartLFG.DB.Set("enabled", self:GetChecked() and true or false)
        O.Refresh()
    end)

    -- Role section
    local roleHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    roleHeader:SetPoint("TOPLEFT", enabledDesc, "BOTTOMLEFT", -4, -28)
    roleHeader:SetText(L.OPTIONS_ROLE)

    local prev
    for _, role in ipairs(SmartLFG.ROLES) do
        local btn = CreateRoleButton(panel, role)
        if prev then
            btn:SetPoint("LEFT", prev, "RIGHT", 14, 0)
        else
            btn:SetPoint("TOPLEFT", roleHeader, "BOTTOMLEFT", 0, -10)
        end
        prev = btn
        roleButtons[role] = btn
    end

    local roleDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    roleDesc:SetPoint("TOPLEFT", roleButtons[SmartLFG.ROLES[1]], "BOTTOMLEFT", 0, -10)
    roleDesc:SetWidth(520)
    roleDesc:SetJustifyH("LEFT")
    roleDesc:SetText(L.OPTIONS_ROLE_DESC)

    panel:SetScript("OnShow", O.Refresh)
end

-- ── Sync widgets to current state ───────────────────────────────────────────
function O.Refresh()
    if not panel then return end

    enabledCheck:SetChecked(SmartLFG.DB.Get("enabled") and true or false)

    local available = SmartLFG.GetAvailableRoles()
    local selected  = SmartLFG.GetSelectedRoles()
    for role, btn in pairs(roleButtons) do
        local valid = available[role] and true or false
        btn.icon:SetDesaturated(not valid)
        btn:SetAlpha(valid and 1 or 0.3)
        btn:EnableMouse(valid)
        btn.check:SetShown(valid and selected[role] and true or false)
    end
end

-- ── Register with the in-game options UI ────────────────────────────────────
function O.Register()
    if panel then return end
    BuildPanel()

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, addonName)
        Settings.RegisterAddOnCategory(category)
        categoryID = category:GetID()
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    O.Refresh()
end

-- ── Open the panel (target of bare /slfg) ───────────────────────────────────
function O.Open()
    if Settings and Settings.OpenToCategory and categoryID then
        Settings.OpenToCategory(categoryID)
    elseif InterfaceOptionsFrame_OpenToCategory and panel then
        InterfaceOptionsFrame_OpenToCategory(panel)  -- legacy double-call bug workaround
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
    O.Refresh()
end
