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

    local C = SmartLFG.COLOR
    SmartLFG.Print(
        C.WARN .. "No role selected." .. C.RESET ..
        " Open the Dungeon Finder (" ..
        C.ROLE .. SmartLFG.GetDungeonFinderKey() .. C.RESET ..
        ") and tick at least one role checkbox first."
    )
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
        SmartLFG.Print(
            "Already in queue (state: " ..
            SmartLFG.COLOR.ROLE .. tostring(mode) ..
            SmartLFG.COLOR.RESET .. "). Not re-queuing."
        )
        return
    end

    -- Roles are already set in the native UI — just commit the queue.
    LFGTeleport(false)

    SmartLFG.Print(
        "Signed up as " .. (SmartLFG.GetLFDRoleDisplay() or "?") .. "."
    )
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
            SmartLFG.Print(
                "Applying to group as " ..
                (SmartLFG.GetLFDRoleDisplay() or "?") .. "."
            )
        else
            SmartLFG.Print("Already applied — waiting for the group leader's response.")
        end
    elseif LFGListSearchPanel_SignUp and LFGListFrame and LFGListFrame.SearchPanel then
        -- Fallback: LFGListSearchPanel_SignUp is a method on the SearchPanel.
        LFGListSearchPanel_SignUp(LFGListFrame.SearchPanel)
        SmartLFG.Print(
            "Applying to group as " ..
            (SmartLFG.GetLFDRoleDisplay() or "?") .. "."
        )
    else
        SmartLFG.Warn("Could not find the premade group sign-up button.")
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

    SmartLFG.Print(
        "Auto-accepted role check as " ..
        (SmartLFG.GetLFDRoleDisplay() or "?") ..
        " (leader: " .. SmartLFG.COLOR.OK .. tostring(leader) ..
        SmartLFG.COLOR.RESET .. ")."
    )
end
