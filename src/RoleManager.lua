-- src/RoleManager.lua
-- Interacts with the native WoW LFG/LFGList systems to queue the player.
--
-- Role source (WoW 12.x / Midnight)
-- -----------------------------------------------------------------------
-- Roles are read live from the native Dungeon Finder tick-boxes via
-- GetLFGRoles(). SmartLFG never stores or overrides the player's role
-- preference - it simply reads whatever WoW already knows and acts on it.
--
--   GetLFGRoles() -> leader, tank, healer, dps  (all booleans)
--
-- If the player has not ticked any role box, SmartLFG prints a helpful
-- reminder and does nothing - exactly the fail-safe behaviour the user
-- expects.
--
-- Sign-up paths
-- -----------------------------------------------------------------------
--   LFD (Dungeon Finder):   LFGTeleport(false)
--   Premade Groups:         SearchPanel.SignUpButton:Click()
--                           -> LFGListApplicationDialog auto-confirmed
--                              by FrameHook's OnShow hook
-- -----------------------------------------------------------------------

local addonName, SmartLFG = ...

SmartLFG.RoleManager = {}
local RM = SmartLFG.RoleManager

local LISTING_JOIN_TTL = 180
local pendingListingJoin
local wasInHomeGroup = false

local APPLICATION_STATUS_BY_VALUE = {}
for _, key in ipairs({
    "applied",
    "invited",
    "inviteaccepted",
    "declined",
    "cancelled",
    "invitedeclined",
    "timedout",
    "failed",
}) do
    local value = _G["LFG_LIST_APPLICATION_STATUS_" .. string.upper(key)]
    if value ~= nil then
        APPLICATION_STATUS_BY_VALUE[value] = key
    end
end

--- Normalizes an application status into a lowercase key across string/enum variants.
--- @param status any
--- @return string|nil
local function NormalizeApplicationStatus(status)
    if status == nil then return nil end
    if type(status) == "string" then return status:lower() end
    return APPLICATION_STATUS_BY_VALUE[status] or tostring(status):lower()
end

--- Reads current application status for a specific resultID when available.
--- @param resultID number
--- @return string|nil
local function GetCurrentApplicationStatus(resultID)
    if not (C_LFGList and C_LFGList.GetApplicationInfo) then return nil end

    local info = C_LFGList.GetApplicationInfo(resultID)
    if type(info) == "table" then
        return NormalizeApplicationStatus(
            info.applicationStatus
            or info.status
            or info.appStatus
            or info.pendingStatus
        )
    end

    return NormalizeApplicationStatus(info)
end

-- ---------------------------------------------------------------------------
-- HasRoleSelected  (internal guard shared by all sign-up paths)
-- ---------------------------------------------------------------------------

--- Returns true when the player has ticked at least one role in the native
--- Dungeon Finder panel. Prints a reminder and returns false otherwise.
local function HasRoleSelected()
    if SmartLFG.HasLFDRoleSelected() then return true end
    local key = SmartLFG.COLOR.ROLE .. SmartLFG.GetDungeonFinderKey() .. SmartLFG.COLOR.RESET
    SmartLFG.Warn(string.format(SmartLFG.L.NO_ROLE, key))
    return false
end

--- Returns a readable Premade activity label for the given result.
--- @param resultID number|nil
--- @return string|nil
local function GetPremadeActivityLabel(resultID)
    if not (resultID and C_LFGList and C_LFGList.GetSearchResultInfo) then return nil end

    local info = C_LFGList.GetSearchResultInfo(resultID)
    if not info then return nil end

    if info.activityID and C_LFGList.GetActivityInfoTable then
        local activityInfo = C_LFGList.GetActivityInfoTable(info.activityID)
        if activityInfo then
            if activityInfo.fullName and activityInfo.fullName ~= "" then return activityInfo.fullName end
            if activityInfo.shortName and activityInfo.shortName ~= "" then return activityInfo.shortName end
            if activityInfo.groupFinderActivityGroupName and activityInfo.groupFinderActivityGroupName ~= "" then
                return activityInfo.groupFinderActivityGroupName
            end
        end
    end

    if info.name and info.name ~= "" then return info.name end
    return nil
end

--- Tries to read the currently selected Premade result ID from the SearchPanel.
--- @return number|nil
local function GetSelectedPremadeResultID()
    local panel = LFGListFrame and LFGListFrame.SearchPanel
    if not panel then return nil end

    return panel.selectedResultID
        or panel.selectedResult
        or panel.selectedIndex
        or panel.resultID
end

-- ---------------------------------------------------------------------------
-- SignUp  - LFD / Dungeon Finder path
-- ---------------------------------------------------------------------------

--- Signs the player into the LFD queue using the roles currently ticked in
--- the native Dungeon Finder panel. Called from the double-click hook or
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

    -- Roles are already set in the native UI - just commit the queue.
    LFGTeleport(false)
    SmartLFG.Print(string.format(SmartLFG.L.SIGNED_UP, SmartLFG.GetLFDRoleDisplay() or "?"))
end

-- ---------------------------------------------------------------------------
-- ApplyToGroup  - Premade Groups path
-- ---------------------------------------------------------------------------

--- Applies to a Premade Group from the LFG List browser.
--- Called from the double-click hook on a result row frame.
---
--- Flow (non-invasive - mirrors what a player clicks manually):
---   1. Click SearchPanel.SignUpButton -> LFGListApplicationDialog opens.
---   2. FrameHook's OnShow hook on LFGListApplicationDialog auto-clicks
---      ApplicationDialog.SignUpButton to confirm.
function RM.ApplyToGroup(resultID)
    if not SmartLFG.DB.Get("enabled") then return end
    if not HasRoleSelected() then return end

    resultID = resultID or GetSelectedPremadeResultID()

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
-- AutoAcceptRoleCheck  - friend auto-accept path
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

    -- ConfirmLFGRoles() was removed in WoW 12.x - click the native popup button.
    local btn = LFDRoleCheckPopupAcceptButton
    if not (btn and btn:IsVisible()) then return end
    btn:Click()

    local C = SmartLFG.COLOR
    SmartLFG.Print(string.format(SmartLFG.L.AUTO_ACCEPTED,
        SmartLFG.GetLFDRoleDisplay() or "?",
        C.OK .. tostring(leader) .. C.RESET
    ))
end

--- Tracks listing application status changes reported by WoW.
--- This is action-agnostic: manual clicks and SmartLFG clicks both flow here.
--- @param resultID number|nil
--- @param ... any
function RM.OnLFGListApplicationStatusUpdated(resultID, ...)
    if not SmartLFG.DB.Get("enabled") then return end
    if not resultID then return end

    local newStatusRaw, oldStatusRaw = ...
    local newStatus = NormalizeApplicationStatus(newStatusRaw) or GetCurrentApplicationStatus(resultID)
    local oldStatus = NormalizeApplicationStatus(oldStatusRaw)

    if newStatus == "declined"
        or newStatus == "cancelled"
        or newStatus == "invitedeclined"
        or newStatus == "timedout"
        or newStatus == "failed"
    then
        if pendingListingJoin and pendingListingJoin.resultID == resultID then
            pendingListingJoin = nil
        end
        return
    end

    -- Arm on any non-terminal listing application signal; this keeps detection
    -- independent from whether the sign-up was manual or SmartLFG-triggered.
    if newStatus == "applied"
        or newStatus == "invited"
        or newStatus == "inviteaccepted"
        or oldStatus == "applied"
        or oldStatus == "invited"
        or oldStatus == "inviteaccepted"
        or newStatus ~= nil
    then
        pendingListingJoin = {
            resultID = resultID,
            activity = GetPremadeActivityLabel(resultID),
            expiresAt = GetTime() + LISTING_JOIN_TTL,
        }
    end
end

--- Prints a join message only when the player enters a group via a listing source.
--- Called from GROUP_ROSTER_UPDATE.
function RM.MaybePrintJoinedListingGroup()
    local inHomeGroup = IsInGroup(LE_PARTY_CATEGORY_HOME) or IsInRaid(LE_PARTY_CATEGORY_HOME)
    if not inHomeGroup then
        wasInHomeGroup = false
        return
    end

    if wasInHomeGroup then return end
    wasInHomeGroup = true

    if not SmartLFG.DB.Get("enabled") then return end
    if not pendingListingJoin then return end

    if pendingListingJoin.expiresAt <= GetTime() then
        pendingListingJoin = nil
        return
    end

    if not pendingListingJoin.activity then
        pendingListingJoin.activity = GetPremadeActivityLabel(pendingListingJoin.resultID)
    end

    local activity = pendingListingJoin.activity or SmartLFG.L.GROUP_TYPE_UNKNOWN
    SmartLFG.Print(string.format(SmartLFG.L.JOINED_GROUP_FOR, activity))
    pendingListingJoin = nil
end
