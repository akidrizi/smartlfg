-- src/RoleManager.lua
-- Interacts with the native WoW LFG/LFGList systems to queue the player.
--
-- Role source (WoW 12.x / Midnight)
-- -----------------------------------------------------------------------
-- Roles are read live from the native Dungeon Finder tick-boxes via
-- GetLFGRoles().  SmartLFG never stores or overrides the player's role
-- preference — it simply reads whatever WoW already knows and acts on it.
--
--   GetLFGRoles() → leader, tank, healer, dps  (all booleans)
--
-- If the player has not ticked any role box, SmartLFG prints a helpful
-- reminder and does nothing — exactly the fail-safe behaviour the user
-- expects.
--
-- Sign-up paths
-- -----------------------------------------------------------------------
--   LFD (Dungeon Finder):   LFGTeleport(false)
--   Premade Groups:         SearchPanel.SignUpButton:Click()
--                           → LFGListApplicationDialog auto-confirmed
--                             by FrameHook's OnShow hook
-- -----------------------------------------------------------------------

local addonName, SmartLFG = ...

SmartLFG.RoleManager = {}
local RM = SmartLFG.RoleManager

-- ---------------------------------------------------------------------------
-- HasRoleSelected  (internal guard shared by all sign-up paths)
-- ---------------------------------------------------------------------------

--- Returns true when the player has ticked at least one role in the native
--- Dungeon Finder panel.  Prints a reminder and returns false otherwise.
local function HasRoleSelected()
    if SmartLFG.HasLFDRoleSelected() then return true end
    local key = SmartLFG.COLOR.ROLE .. SmartLFG.GetDungeonFinderKey() .. SmartLFG.COLOR.RESET
    SmartLFG.Warn(string.format(SmartLFG.L.NO_ROLE, key))
    return false
end

-- ---------------------------------------------------------------------------
-- SignUp  —  LFD / Dungeon Finder path
-- ---------------------------------------------------------------------------

--- Signs the player into the LFD queue using the roles currently ticked in
--- the native Dungeon Finder panel.  Called from the double-click hook or
--- the /slfg signup command.
function RM.SignUp()
    if not SmartLFG.DB.Get("enabled") then return end
    if not HasRoleSelected() then return end

    -- Guard: already queued?
    local mode = GetLFGMode(LE_LFG_CATEGORY_LFD)
    if mode then
        local C = SmartLFG.COLOR
        SmartLFG.Print(string.format(SmartLFG.L.ALREADY_QUEUED, C.ROLE .. tostring(mode) .. C.RESET))
        return
    end

    -- Roles are already set in the native UI — just commit the queue.
    LFGTeleport(false)
    SmartLFG.Print(string.format(SmartLFG.L.SIGNED_UP, SmartLFG.GetLFDRoleDisplay() or "?"))
end

-- ---------------------------------------------------------------------------
-- ApplyToGroup  —  Premade Groups path
-- ---------------------------------------------------------------------------

--- Applies to a Premade Group from the LFG List browser.
--- Called from the double-click hook on a result row frame.
---
--- Flow (non-invasive — mirrors what a player clicks manually):
---   1. Click SearchPanel.SignUpButton → LFGListApplicationDialog opens.
---   2. FrameHook's OnShow hook on LFGListApplicationDialog auto-clicks
---      ApplicationDialog.SignUpButton to confirm.
function RM.ApplyToGroup()
    if not SmartLFG.DB.Get("enabled") then return end
    if not HasRoleSelected() then return end

    local signUpBtn = LFGListFrame
        and LFGListFrame.SearchPanel
        and LFGListFrame.SearchPanel.SignUpButton

    if signUpBtn then
        if signUpBtn:IsEnabled() then
            signUpBtn:Click()
            SmartLFG.Print(string.format(SmartLFG.L.APPLYING, SmartLFG.GetLFDRoleDisplay() or "?"))
        else
            SmartLFG.Print(SmartLFG.L.ALREADY_APPLIED)
        end
    elseif LFGListSearchPanel_SignUp and LFGListFrame and LFGListFrame.SearchPanel then
        -- Fallback: LFGListSearchPanel_SignUp is a method on the SearchPanel.
        LFGListSearchPanel_SignUp(LFGListFrame.SearchPanel)
        SmartLFG.Print(string.format(SmartLFG.L.APPLYING, SmartLFG.GetLFDRoleDisplay() or "?"))
    else
        SmartLFG.Warn(SmartLFG.L.NO_SIGNUP_BTN)
    end
end

-- ---------------------------------------------------------------------------
-- AutoAcceptRoleCheck  —  friend auto-accept path
-- ---------------------------------------------------------------------------

--- Called when LFG_ROLE_CHECK_SHOW fires.
--- If auto-accept is enabled AND the group leader is a friend, confirms the
--- role-check popup on the player's behalf using whatever roles WoW already
--- has ticked in the Dungeon Finder panel.
function RM.AutoAcceptRoleCheck()
    if not SmartLFG.DB.Get("enabled") then return end
    if not SmartLFG.DB.Get("autoAcceptFriends") then return end

    local leader = SmartLFG.GetGroupLeader()
    if not SmartLFG.IsFriend(leader) then return end

    if not HasRoleSelected() then return end

    -- ConfirmLFGRoles() was removed in WoW 12.x — click the native popup button.
    local btn = LFDRoleCheckPopupAcceptButton
    if not (btn and btn:IsVisible()) then return end
    btn:Click()

    local C = SmartLFG.COLOR
    SmartLFG.Print(string.format(SmartLFG.L.AUTO_ACCEPTED,
        SmartLFG.GetLFDRoleDisplay() or "?",
        C.OK .. tostring(leader) .. C.RESET
    ))
end
