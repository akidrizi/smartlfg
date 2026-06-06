local addonName, SmartLFG = ...

local Settings                     = _G.Settings
local InterfaceOptions_AddCategory = _G.InterfaceOptions_AddCategory

SmartLFG.Options = {}
local O = SmartLFG.Options

local panel            -- the standalone dialog frame (the real UI)
local stub             -- tiny Settings → AddOns placeholder that opens the dialog
local enabledCheck     -- the master enable checkbox
local quickSignUpCheck -- toggles double-click sign-up + tooltip hint
local autoAcceptCheck  -- toggles auto-accept of role checks
local noteTip          -- bottom "Tip: …" line (greyed unless double-click sign-up is on)
local tipDiamond       -- the gold diamond preceding the tip
local roleButtons = {} -- role token -> button

-- ── Layout ──────────────────────────────────────────────────────────────────
local PANEL_W      = 380
local PANEL_H      = 260
local PAD          = 16     -- content margin from the panel edges
local ICON_SIZE    = 56     -- role button (ring) edge, in pixels
local ICON_INNER   = 32     -- role icon inside the ring
local ROLE_SPACING = 92     -- centre-to-centre distance between role buttons

-- Vertical layout: offsets from the dialog's top edge (negative = downward).
local ROLE_HEADER_Y = -62
local ROLE_Y        = -82
local OPT_HEADER_Y  = -170
local OPT_Y         = -188
local TIP_Y         = -230

-- ── Shared helpers ──────────────────────────────────────────────────────────
-- Show a title + wrapped description in a tooltip while hovering a frame.
local function WireTooltip(frame, title, text)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if text then GameTooltip:AddLine(text, nil, nil, nil, true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- A white small-caps section header, left-aligned at the given Y.
local function CreateSectionHeader(text, yOffset)
    local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, yOffset)
    fs:SetText(text:upper())
    fs:SetTextColor(1, 1, 1)
    return fs
end

-- ── One labelled checkbox bound to a DB key ─────────────────────────────────
-- Help text lives in a hover tooltip (no inline description). Returns the
-- check (with its label on `check.label`); the caller positions it.
local function CreateCheck(parent, name, dbKey, labelText, tipTitle, tipText)
    local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)

    local label = check:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    label:SetText(labelText)
    check.label = label

    -- Extend the hover/click area over the label text too.
    check:SetHitRectInsets(0, -(label:GetStringWidth() + 8), 0, 0)

    check:SetScript("OnClick", function(self)
        SmartLFG.DB.Set(dbKey, self:GetChecked() and true or false)
        O.Refresh()
    end)
    WireTooltip(check, tipTitle, tipText)

    return check, label
end

-- ── One role icon button ────────────────────────────────────────────────────
-- A circular role icon inside a ring, with a label beneath. Selecting it stores
-- the role; invalid-for-class roles are desaturated and non-interactive.
local function CreateRoleButton(parent, role)
    local btn = CreateFrame("Button", "SmartLFGRole" .. role, parent)
    btn:SetSize(ICON_SIZE, ICON_SIZE)
    btn.role = role

    -- Round metal ring framing the icon.
    local ring = btn:CreateTexture(nil, "BACKGROUND")
    ring:SetAllPoints()
    ring:SetTexture("Interface\\Buttons\\UI-EmptySlot")
    btn.ring = ring

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_INNER, ICON_INNER)
    icon:SetPoint("CENTER")
    icon:SetAtlas(SmartLFG.ROLE_ATLAS[role], false)
    icon:SetSnapToPixelGrid(false)
    icon:SetTexelSnappingBias(0)
    btn.icon = icon

    -- Selection glow, shown only for the active role.
    local check = btn:CreateTexture(nil, "OVERLAY")
    check:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    check:SetBlendMode("ADD")
    check:SetPoint("TOPLEFT", -3, 3)
    check:SetPoint("BOTTOMRIGHT", 3, -3)
    check:Hide()
    btn.check = check

    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOP", btn, "BOTTOM", 0, -5)
    label:SetText(SmartLFG.GetRoleName(role):upper())
    btn.label = label

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

-- ── Build the dialog once ───────────────────────────────────────────────────
local function BuildPanel()
    local C, L = SmartLFG.COLOR, SmartLFG.L

    -- A standalone, movable window with a close (X) button — opened by /slfg
    -- and by the minimap button, not embedded in Blizzard's Settings panel.
    panel = CreateFrame("Frame", "SmartLFGDialog", UIParent, "BackdropTemplate")
    panel:SetSize(PANEL_W, PANEL_H)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("HIGH")
    panel:SetToplevel(true)
    panel:SetClampedToScreen(true)
    panel:Hide()
    panel:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",  -- plain, no corner ornaments
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    panel:SetBackdropColor(1, 1, 1, 0.75)  -- ~25% more transparent than opaque

    -- Drag the window by grabbing anywhere on it.
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)

    -- ESC closes the dialog like any other Blizzard window.
    table.insert(UISpecialFrames, "SmartLFGDialog")

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", -5, -5)

    -- Header: branded icon + name, with version beneath the name (top-left).
    -- Easter egg: the icon is a button — clicking it toggles the Group Finder,
    -- exactly like the micro-menu button or the default "I" keybind.
    local logoButton = CreateFrame("Button", nil, panel)
    logoButton:SetSize(36, 36)
    logoButton:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -12)
    logoButton:RegisterForClicks("LeftButtonUp")
    logoButton:SetScript("OnClick", function()
        if ToggleLFDParentFrame then ToggleLFDParentFrame() end
    end)
    logoButton:SetScript("OnEnter", function(self) self:SetAlpha(0.8) end)
    logoButton:SetScript("OnLeave", function(self) self:SetAlpha(1) end)

    local logo = logoButton:CreateTexture(nil, "ARTWORK")
    logo:SetAllPoints()
    logo:SetTexture("Interface\\AddOns\\SmartLFG\\media\\minimap_64.png")
    logo:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", logoButton, "TOPRIGHT", 8, -3)
    title:SetText(C.ADDON .. addonName .. C.RESET)

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    version:SetText(string.format(L.OPTIONS_VERSION, SmartLFG.GetAddonVersion()))
    version:SetTextColor(0.6, 0.6, 0.6)

    -- Master enable switch on the version row, top-right: "[ ] Enable".
    -- The chat commands in the tooltip are highlighted in the addon's cyan.
    local enableDesc = string.format(L.OPTIONS_ENABLE_DESC,
        C.ADDON .. "/slfg on" .. C.RESET, C.ADDON .. "/slfg off" .. C.RESET)
    enabledCheck = CreateCheck(panel, "SmartLFGEnabledCheck",
        "enabled", L.OPTIONS_ENABLE_SHORT, L.OPTIONS_ENABLE, enableDesc)
    -- +2 extra right margin so the label doesn't crowd the border.
    enabledCheck:SetPoint("TOPRIGHT", panel, "TOPRIGHT",
        -(PAD + 2 + enabledCheck.label:GetStringWidth() + 4), -28)

    -- Roles section. A turn-in icon beside the header explains the
    -- nothing-selected fallback on hover (uses the current spec's role).
    local roleHeader = CreateSectionHeader(L.OPTIONS_ROLE, ROLE_HEADER_Y)

    local roleInfo = CreateFrame("Button", nil, panel)
    roleInfo:SetSize(13, 13)
    roleInfo:SetPoint("LEFT", roleHeader, "RIGHT", 2, 0)
    local roleInfoIcon = roleInfo:CreateTexture(nil, "ARTWORK")
    roleInfoIcon:SetAllPoints()
    roleInfoIcon:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon")
    roleInfo:SetScript("OnEnter", function(self)
        local role     = SmartLFG.GetCurrentSpecRole()
        local atlas    = role and SmartLFG.ROLE_ATLAS[role]
        local icon     = atlas and CreateAtlasMarkup(atlas, 16, 16) or ""
        local specName = SmartLFG.GetCurrentSpecName() or ""

        -- Tint the spec name with the player's class color.
        local _, classFile = UnitClass("player")
        local color = (classFile and C_ClassColor and C_ClassColor.GetClassColor(classFile))
            or (classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile])
        local coloredName = color and color:WrapTextInColorCode(specName) or specName

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L.OPTIONS_ROLE_INFO_TITLE, 1, 1, 1)
        -- Classic tooltip yellow; the spec name keeps its class color (|c…|r).
        GameTooltip:AddLine(string.format(L.OPTIONS_ROLE_INFO, icon, coloredName), 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    roleInfo:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local offset = { -ROLE_SPACING, 0, ROLE_SPACING }
    for i, role in ipairs(SmartLFG.ROLES) do
        local btn = CreateRoleButton(panel, role)
        btn:SetPoint("TOP", panel, "TOP", offset[i], ROLE_Y)
        roleButtons[role] = btn
    end

    -- Options section: two columns of toggles.
    CreateSectionHeader(L.OPTIONS_SECTION, OPT_HEADER_Y)

    quickSignUpCheck = CreateCheck(panel, "SmartLFGQuickSignUpCheck",
        "quickSignUp", L.OPTIONS_QUICKSIGNUP, L.OPTIONS_QUICKSIGNUP, L.OPTIONS_QUICKSIGNUP_DESC)
    autoAcceptCheck = CreateCheck(panel, "SmartLFGAutoAcceptCheck",
        "autoAccept", L.OPTIONS_AUTOACCEPT, L.OPTIONS_AUTOACCEPT, L.OPTIONS_AUTOACCEPT_DESC)

    -- Center each toggle (checkbox + label) within its half of the content area,
    -- so the pair reads as balanced rather than pinned to fixed columns.
    local halfW = (PANEL_W - 2 * PAD) / 2
    local function PlaceToggle(check, column)
        local centerX = PAD + halfW * (column - 0.5)
        local blockW  = check:GetWidth() + 4 + check.label:GetStringWidth()
        check:SetPoint("TOPLEFT", panel, "TOPLEFT", centerX - blockW / 2, OPT_Y)
    end
    PlaceToggle(quickSignUpCheck, 1)
    PlaceToggle(autoAcceptCheck, 2)

    -- Bottom tip (reuses the tooltip-hint string), prefixed with a small gold
    -- diamond. Greyed unless double-click sign-up is active — see O.Refresh.
    noteTip = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    noteTip:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD + 12, TIP_Y)
    noteTip:SetText(string.format(L.OPTIONS_TIP, L.OPTIONS_TIP_NOTE))

    tipDiamond = panel:CreateTexture(nil, "ARTWORK")
    tipDiamond:SetColorTexture(1, 1, 1)
    tipDiamond:SetSize(7, 7)
    tipDiamond:SetRotation(math.rad(45))  -- a rotated square reads as a diamond
    tipDiamond:SetPoint("RIGHT", noteTip, "LEFT", -5, 0)

    panel:SetScript("OnShow", O.Refresh)
end

-- ── Sync widgets to current state ───────────────────────────────────────────
function O.Refresh()
    if not panel then return end

    local enabled = SmartLFG.DB.Get("enabled") and true or false
    enabledCheck:SetChecked(enabled)

    -- Sub-toggles reflect their own DB value but are disabled while the master
    -- switch is off, so it's clear they have no effect.
    quickSignUpCheck:SetChecked(SmartLFG.DB.Get("quickSignUp") and true or false)
    autoAcceptCheck:SetChecked(SmartLFG.DB.Get("autoAccept") and true or false)
    quickSignUpCheck:SetEnabled(enabled)
    autoAcceptCheck:SetEnabled(enabled)

    -- Grey the option labels while the master switch is off.
    local r, g, b = 0.5, 0.5, 0.5
    if enabled then r, g, b = 1, 0.82, 0 end
    quickSignUpCheck.label:SetTextColor(r, g, b)
    autoAcceptCheck.label:SetTextColor(r, g, b)

    -- The note tip only applies when double-click sign-up is actually running.
    if enabled and SmartLFG.DB.Get("quickSignUp") then
        noteTip:SetTextColor(0, 0.8, 1)
        tipDiamond:SetVertexColor(1, 0.84, 0)
    else
        noteTip:SetTextColor(0.5, 0.5, 0.5)
        tipDiamond:SetVertexColor(0.5, 0.5, 0.5)
    end

    local available = SmartLFG.GetAvailableRoles()
    local selected  = SmartLFG.GetSelectedRoles()
    for role, btn in pairs(roleButtons) do
        -- A role is interactive only when the addon is enabled and the class
        -- can perform it; otherwise it's desaturated and dimmed.
        local active = enabled and (available[role] and true or false)
        local isSel  = selected[role] and true or false
        btn.icon:SetDesaturated(not active)
        btn.ring:SetDesaturated(not active)
        btn:SetAlpha(active and 1 or 0.4)
        btn:EnableMouse(active)
        btn.check:SetShown(active and isSel)
        if not active then
            btn.label:SetTextColor(0.5, 0.5, 0.5)
        elseif isSel then
            btn.label:SetTextColor(1, 0.82, 0)
        else
            btn.label:SetTextColor(0.8, 0.8, 0.8)
        end
    end
end

-- ── Tiny Settings → AddOns placeholder ──────────────────────────────────────
-- The real UI is the standalone dialog; the Blizzard Settings entry is just a
-- centered name/version and a clickable "/slfg" that opens that dialog.
local function BuildStub()
    local C, L = SmartLFG.COLOR, SmartLFG.L

    stub = CreateFrame("Frame", "SmartLFGStubPanel", UIParent)
    stub.name = addonName

    local title = stub:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("CENTER", stub, "CENTER", 0, 40)
    title:SetText(C.ADDON .. addonName .. C.RESET)

    local version = stub:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    version:SetPoint("TOP", title, "BOTTOM", 0, -8)
    version:SetText(string.format(L.OPTIONS_VERSION, SmartLFG.GetAddonVersion()))

    -- Clickable "/slfg" that opens the dialog.
    local open = CreateFrame("Button", nil, stub)
    open:SetPoint("TOP", version, "BOTTOM", 0, -20)
    local openText = open:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    openText:SetText("/slfg")
    open:SetFontString(openText)
    open:SetSize(openText:GetStringWidth() + 8, 28)
    openText:SetPoint("CENTER")

    open:SetScript("OnEnter", function() openText:SetTextColor(0, 0.8, 1) end)
    open:SetScript("OnLeave", function() openText:SetTextColor(1, 0.82, 0) end)
    open:SetScript("OnClick", function() O.Open() end)
end

-- ── Register with the in-game options UI ────────────────────────────────────
function O.Register()
    if panel then return end
    BuildPanel()
    BuildStub()

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(stub, addonName)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(stub)
    end

    O.Refresh()
end

-- ── Open / toggle the dialog (target of bare /slfg and the minimap button) ───
function O.Open()
    if not panel then return end
    panel:Show()
    panel:Raise()
    O.Refresh()
end

function O.Toggle()
    if not panel then return end
    if panel:IsShown() then
        panel:Hide()
    else
        O.Open()
    end
end
