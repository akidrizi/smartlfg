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
local pendingActivityLabel  -- activity name captured from the row frame at click time

--- Maps resultID -> activity name read directly from visible row frames.
--- Populated by FrameHook on every ScrollBox layout so it is always current
--- before any sign-up event fires, regardless of who triggered the invite.
local activityNameCache = {}

--- Called from FrameHook whenever a Premade result row is displayed.
--- Caches the activity label so GetPremadeActivityLabel can find it for any
--- sign-up path: SmartLFG double-click, manual button click, or leader invite.
--- @param resultID number
--- @param name string
function RM.CacheActivityName(resultID, name)
    if resultID and name and name ~= "" then
        activityNameCache[resultID] = name
    end
end

--- Called by FrameHook from the LFGListApplicationDialog:OnShow hook.
--- The dialog's ActivityName FontString is the most reliable capture point
--- because Blizzard populates it with the properly formatted dropdown-selected
--- activity (e.g. "Deadmines (Mythic Keystone)") for every player — solo,
--- leader, and non-leader member receiving an invite.
--- Also updates pendingListingJoin.activity directly, because the dialog may
--- fire AFTER LFG_LIST_APPLICATION_STATUS_UPDATED has already armed the join
--- with a stale fallback name (e.g. when a group leader signs up the group).
--- @param name string
function RM.SetPendingActivityLabel(name)
    if name and name ~= "" then
        pendingActivityLabel = name
        if pendingListingJoin then
            pendingListingJoin.activity = name
        end
    end
end

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

--- Resolves an activity name from an activityID using the available C_LFGList APIs.
--- Handles both the table-return variant (WoW 10.x+) and the legacy plain-string
--- first-return-value variant present in older WoW versions.
--- @param activityID number
--- @return string|nil
local function ResolveActivityName(activityID)
    if not activityID or activityID == 0 then return nil end

    local function tryAPI(fn)
        if not fn then return nil end
        local act = fn(activityID)
        if type(act) == "table" then
            return act.activityName
                or act.fullName
                or act.shortName
                or act.groupFinderActivityGroupName
        elseif type(act) == "string" and act ~= "" then
            return act
        end
    end

    return tryAPI(C_LFGList and C_LFGList.GetActivityInfoTable)
        or tryAPI(C_LFGList and C_LFGList.GetActivityInfo)
end

--- Returns a readable Premade activity label for the given result.
---
--- Priority:
---   1. activityNameCache[resultID] — populated from the row frame's displayed
---      text by FrameHook on every ScrollBox layout.
---   2. info.activityName   — newer WoW exposes this directly on the search result.
---   3. GetActivityInfoTable / GetActivityInfo resolved from info.activityIDs (array,
---      WoW 10.x+) or info.activityID (scalar, legacy) — the dropdown selection.
---   4. info.name           — the player-typed listing title (last resort).
---
--- @param resultID number|nil
--- @return string|nil
local function GetPremadeActivityLabel(resultID)
    if not resultID then return nil end

    -- 1. Frame-text cache (most reliable — independent of C_LFGList API shape).
    if activityNameCache[resultID] then
        return activityNameCache[resultID]
    end

    if not (C_LFGList and C_LFGList.GetSearchResultInfo) then return nil end
    local info = C_LFGList.GetSearchResultInfo(resultID)
    if not info then return nil end

    -- 2. Some WoW versions embed activityName directly on the search result.
    if info.activityName and info.activityName ~= "" then
        return info.activityName
    end

    -- 3. Resolve via activity ID(s).
    -- WoW 10.x+ returns activityIDs as an array; older versions use a scalar activityID.
    -- Build a unified list to try both, without duplicates.
    local tried = {}
    local function tryActivityID(aid)
        if not aid or aid == 0 or tried[aid] then return nil end
        tried[aid] = true
        local label = ResolveActivityName(aid)
        return (label and label ~= "") and label or nil
    end

    if type(info.activityIDs) == "table" then
        for _, aid in ipairs(info.activityIDs) do
            local label = tryActivityID(aid)
            if label then return label end
        end
    end
    local label = tryActivityID(info.activityID)
    if label then return label end

    -- 4. Last resort: the player-typed listing title.
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
    if not SmartLFG.IsPlayerSoloOrLeader() then return end
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
---
--- activityNameHint is captured from the row frame's displayed text at click
--- time by FrameHook (frame.ActivityName FontString). It is the most reliable
--- source because it reflects what the player sees regardless of WoW API changes.
function RM.ApplyToGroup(resultID, activityNameHint)
    if not SmartLFG.IsPlayerSoloOrLeader() then return end
    if not HasRoleSelected() then return end

    resultID = resultID or GetSelectedPremadeResultID()

    -- Store the activity label now, while the UI context is fresh.
    -- The frame-captured hint is preferred; API lookup is the fallback.
    pendingActivityLabel = (activityNameHint and activityNameHint ~= "" and activityNameHint)
                        or GetPremadeActivityLabel(resultID)

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

-- ---------------------------------------------------------------------------
-- OnActiveEntryUpdate  - active listing state change
-- ---------------------------------------------------------------------------

--- Called when LFG_LIST_ACTIVE_ENTRY_UPDATE fires.
---
--- This event fires for everyone in the group (leader AND members) whenever the
--- active listing state changes — including the moment the group is formed or a
--- member joins. At that point C_LFGList.GetActiveEntryInfo() holds the full
--- entry data, making it the most reliable place to capture the activity name
--- regardless of whether the player ever opened the search results panel.
---
--- For the leader  : fires when the listing fills or the group leaves.
--- For members     : fires when they join the group via the listing — the
---                   WoW dialog is suppressed for members but the event still
---                   arrives, so we can read the entry info silently.
function RM.OnActiveEntryUpdate()
    if not (C_LFGList and C_LFGList.GetActiveEntryInfo) then return end

    local entry = C_LFGList.GetActiveEntryInfo()
    if not entry then return end

    -- Try activityName directly (WoW 12.x may expose it on the entry).
    -- Otherwise resolve from activity IDs: WoW 10.x+ returns activityIDs (array),
    -- older versions return activityID (scalar).
    local activityName = (type(entry.activityName) == "string" and entry.activityName ~= "" and entry.activityName)

    if not activityName then
        local function tryID(aid)
            if not aid or aid == 0 then return nil end
            local n = ResolveActivityName(aid)
            return (n and n ~= "") and n or nil
        end
        if type(entry.activityIDs) == "table" then
            for _, aid in ipairs(entry.activityIDs) do
                activityName = tryID(aid)
                if activityName then break end
            end
        end
        if not activityName then
            activityName = tryID(entry.activityID)
        end
    end

    if activityName and activityName ~= "" then
        pendingActivityLabel = activityName
        -- Update pendingListingJoin if it was already armed with fallback/stale data.
        if pendingListingJoin then
            pendingListingJoin.activity = activityName
        end
    end
end

--- Tracks listing application status changes reported by WoW.
--- This is action-agnostic: manual clicks and SmartLFG clicks both flow here.
--- @param resultID number|nil
--- @param ... any
function RM.OnLFGListApplicationStatusUpdated(resultID, ...)
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
            resultID  = resultID,
            activity  = pendingActivityLabel or GetPremadeActivityLabel(resultID),
            expiresAt = GetTime() + LISTING_JOIN_TTL,
        }
        pendingActivityLabel = nil  -- consumed
    end
end

--- Prints a join message only when the player enters a group via a listing source.
--- Called from GROUP_ROSTER_UPDATE.
---
--- pendingListingJoin is the sole guard against duplicate prints — it is cleared
--- immediately after printing, so repeated GROUP_ROSTER_UPDATE fires (which WoW
--- sends for every roster change while grouped) will find it nil and return early.
---
--- wasInHomeGroup was previously used to detect solo→grouped transitions, but it
--- blocked the message when the player was already in a group (e.g. the party
--- leader signs up the whole group for a Premade listing). It is no longer needed.
function RM.MaybePrintJoinedListingGroup()
    if not pendingListingJoin then return end

    -- Wait until the player is actually in a home group before printing.
    local inHomeGroup = IsInGroup(LE_PARTY_CATEGORY_HOME) or IsInRaid(LE_PARTY_CATEGORY_HOME)
    if not inHomeGroup then return end

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
