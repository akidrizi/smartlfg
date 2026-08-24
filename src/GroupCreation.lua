local _, SmartLFG = ...

SmartLFG.GroupCreation = {}
local GC = SmartLFG.GroupCreation

-- "Enhanced listing" (the `enhancedListing` DB key) for the Dungeons "Start a
-- Group" creation form. Two behaviors, both on together, both off together:
--
--   1. Trim the dungeon dropdown to the current Mythic+ season.
--   2. Pre-select Mythic+ difficulty and a Competitive playstyle when the form
--      opens, and re-assert Mythic+ whenever the player switches dungeon.
--
-- Every entry point re-reads the DB key, so toggling the option takes effect
-- immediately — GC.Refresh() rebuilds an already-open form, no /reload needed.
--
-- We deliberately never write the listing's Title: on Mythic+ Blizzard derives
-- it from the player's current keystone, and anything we wrote would either be
-- stale or fight that. The title is entirely Blizzard's.
--
-- The widgets and fields here are ordinary (non-secure) — Blizzard's own
-- LFGListEntryCreation_Clear() writes them the exact same way
-- (generalPlaystyle, LFGListEntryCreation_Select). But this form is NOT
-- taint-free:
-- LFGListEntryCreation_Select ends in LFGListEntryCreation_SetTitleFromActivityInfo,
-- which calls the PROTECTED C_LFGList.SetEntryTitle whenever the selected
-- activity is Mythic+ — exactly our case. Driving that from addon code raises
-- ADDON_ACTION_BLOCKED and Blizzard's keystone auto-title is skipped for that
-- call (the player's own clicks still title normally). So: route every activity
-- change through SelectActivity, which suppresses no-op calls, and never call
-- LFGListEntryCreation_OnPlayStyleSelectedInternal — it reaches the same
-- protected path for no benefit (see SetPlaystyle).
--
-- Every call into Blizzard's undocumented internals goes through SafeCall
-- (pcall-guarded) so a naming or signature mismatch on some client degrades that
-- one effect silently instead of aborting the rest of this file.
-- GROUP_FINDER_CATEGORY_ID_DUNGEONS and the LFGListEntryCreation_* globals are
-- only looked up inside the functions below (never cached at file load), since
-- Blizzard_GroupFinder hasn't loaded yet when this file does.

-- ── Helpers ──────────────────────────────────────────────────────────────────

-- Calls an undocumented Blizzard function defensively: a missing function is a
-- silent no-op, and any error it raises (wrong signature on some client build)
-- is swallowed rather than aborting the caller.
local function SafeCall(fn, ...)
    if not fn then return false end
    return pcall(fn, ...)
end

local function IsDungeonsForm(frame)
    return frame and frame.selectedCategory == GROUP_FINDER_CATEGORY_ID_DUNGEONS
end

-- The single gate for everything in this file: the master switch plus the
-- "Enhanced listing" option. Re-read on every entry point rather than cached,
-- so unticking the option stops all of it without a reload.
local function IsEnhanced()
    return SmartLFG.DB.Get("enabled") and SmartLFG.DB.Get("enhancedListing")
end

-- The filter flags Blizzard combines for every availability lookup.
local function CombinedFilters(frame)
    return bit.bor(frame.baseFilters or 0, frame.selectedFilters or 0)
end

-- Finds the first available activity (for the given dungeon) matching `match`.
local function FindActivity(categoryID, groupID, filters, match)
    if not (groupID and C_LFGList and C_LFGList.GetAvailableActivities and C_LFGList.GetActivityInfoTable) then
        return nil
    end
    for _, activityID in ipairs(C_LFGList.GetAvailableActivities(categoryID, groupID, filters or 0)) do
        local info = C_LFGList.GetActivityInfoTable(activityID)
        if info and match(info) then
            return activityID
        end
    end
    return nil
end

local function IsMythicPlus(info) return info.isMythicPlusActivity end

-- A dungeon counts as "current Mythic+ season" exactly when the client still
-- offers a Mythic+ activity for it. This is the same lookup that already drives
-- the difficulty baseline, so it can't drift out of sync with a hardcoded list.
local function HasMythicPlus(categoryID, groupID, filters)
    return FindActivity(categoryID, groupID, filters, IsMythicPlus) ~= nil
end

-- ── Difficulty enforcement ───────────────────────────────────────────────────

-- Selecting an activity re-enters LFGListEntryCreation_Select, which we hook —
-- this keeps that from recursing.
local enforcing = false

-- The one place we call LFGListEntryCreation_Select. That function ends in
-- LFGListEntryCreation_SetTitleFromActivityInfo, which calls the *protected*
-- C_LFGList.SetEntryTitle whenever the activity is Mythic+ — so every call from
-- our (tainted) code raises ADDON_ACTION_BLOCKED. We can't avoid the call
-- entirely without giving up programmatic difficulty selection, so we make it
-- as rare as possible: no activityID, or it's already selected, means no call.
local function SelectActivity(frame, activityID)
    if not activityID or frame.selectedActivity == activityID then return end
    enforcing = true
    SafeCall(LFGListEntryCreation_Select, frame, nil, nil, nil, activityID)
    enforcing = false
end

-- Playstyle is set by writing the field Blizzard itself writes, deliberately
-- NOT via LFGListEntryCreation_OnPlayStyleSelectedInternal: that function also
-- routes into SetTitleFromActivityInfo → protected SetEntryTitle, so calling it
-- would add a second source of blocked-action spam for no benefit. Blizzard's
-- own Clear() assigns this field the same way.
local function SetPlaystyle(frame, playstyle)
    if not playstyle or frame.generalPlaystyle == playstyle then return end
    frame.generalPlaystyle = playstyle
end

-- Selects the Mythic+ activity for whichever dungeon is currently chosen.
-- Returns true if a Mythic+ activity was found (whether or not it needed
-- changing), so callers can tell "not ready yet" from "already correct".
local function EnforceMythicPlus(frame)
    local mplusID = FindActivity(frame.selectedCategory, frame.selectedGroup, CombinedFilters(frame), IsMythicPlus)
    if not mplusID then return false end
    SelectActivity(frame, mplusID)
    return true
end

-- Hooked (hooksecurefunc) to LFGListEntryCreation_Select. Blizzard calls that
-- with a groupID when the *dungeon* changes and with an activityID when the
-- *difficulty* changes; we only react to the former, so picking Heroic by hand
-- from the difficulty dropdown is still respected.
function GC.OnSelect(frame, _, _, groupID)
    if enforcing or not groupID then return end
    if not IsEnhanced() then return end
    if not IsDungeonsForm(frame) then return end
    if not EnforceMythicPlus(frame) then return end
    SafeCall(LFGListEntryCreation_SetupActivityDropdown, frame)
    SafeCall(LFGListEntryCreation_UpdateValidState, frame)
end

-- ── Dungeon dropdown filtering ───────────────────────────────────────────────

-- Latches if our replacement menu ever errors, so we permanently hand the
-- dropdown back to Blizzard rather than risk showing an empty list.
local filterFailed = false

-- Rebuilds the group dropdown exactly the way Blizzard's own
-- LFGListEntryCreation_SetupGroupDropdown does, with one addition: dungeons
-- with no Mythic+ activity are dropped from the list. The "More..." entry is
-- reproduced verbatim (same ActivityFinder call, same arguments), so the full
-- unfiltered list is always one click away.
local function BuildFilteredGroupMenu(frame, rootDescription)
    rootDescription:SetTag("MENU_LFG_FRAME_GROUP")
    if not frame.selectedCategory then return end

    local combined = CombinedFilters(frame)
    local groups     = C_LFGList.GetAvailableActivityGroups(frame.selectedCategory, combined)
    local activities = C_LFGList.GetAvailableActivities(frame.selectedCategory, 0, combined)
    local useMore    = false

    -- Blizzard's own "narrow to Recommended once the list gets long" pass.
    if (frame.selectedFilters or 0) == 0 and (#groups + #activities) > 5 then
        local recFilters    = bit.bor(combined, Enum.LFGListFilter.Recommended)
        local recGroups     = C_LFGList.GetAvailableActivityGroups(frame.selectedCategory, recFilters)
        local recActivities = C_LFGList.GetAvailableActivities(frame.selectedCategory, 0, recFilters)
        if (#recGroups + #recActivities) > 0 then
            useMore = #recGroups ~= #groups or #recActivities ~= #activities
            groups, activities = recGroups, recActivities
        end
    end

    -- Ours: keep only dungeons in the current Mythic+ season. If that leaves
    -- nothing (season data unavailable, or a category that has no Mythic+ at
    -- all) we deliberately fall through to the unfiltered list — an empty
    -- dropdown would be far worse than a long one.
    local seasonGroups = {}
    for _, groupID in ipairs(groups) do
        if HasMythicPlus(frame.selectedCategory, groupID, combined) then
            seasonGroups[#seasonGroups + 1] = groupID
        end
    end
    if #seasonGroups > 0 and #seasonGroups < #groups then
        groups  = seasonGroups
        useMore = true   -- we hid entries; guarantee the escape hatch
    end

    -- Merge groups and standalone activities by their order index, exactly as
    -- Blizzard does (we only ever filtered `groups`; activities are untouched).
    local maxEntries = MAX_LFG_LIST_GROUP_DROPDOWN_ENTRIES or 12
    local groupOrder = groups[1] and select(2, C_LFGList.GetActivityGroupInfo(groups[1]))
    local firstActivityInfo = activities[1] and C_LFGList.GetActivityInfoTable(activities[1])
    local activityOrder = firstActivityInfo and firstActivityInfo.orderIndex
    local groupIndex, activityIndex = 1, 1

    local function IsActivitySelected(activityID) return frame.selectedActivity == activityID end
    local function SetActivitySelected(activityID)
        LFGListEntryCreation_Select(frame, nil, nil, nil, activityID)
    end
    local function IsGroupSelected(groupID) return frame.selectedGroup == groupID end
    local function SetGroupSelected(groupID)
        LFGListEntryCreation_Select(frame, frame.selectedFilters, frame.selectedCategory, groupID)
    end

    for _ = 1, maxEntries do
        if not groupOrder and not activityOrder then break end

        if activityOrder and (not groupOrder or activityOrder < groupOrder) then
            local activityID = activities[activityIndex]
            local info = activityID and C_LFGList.GetActivityInfoTable(activityID)
            rootDescription:CreateRadio(info and info.shortName, IsActivitySelected, SetActivitySelected, activityID)
            activityIndex = activityIndex + 1
            local nextInfo = activities[activityIndex] and C_LFGList.GetActivityInfoTable(activities[activityIndex])
            activityOrder = nextInfo and nextInfo.orderIndex
        else
            local groupID = groups[groupIndex]
            rootDescription:CreateRadio(C_LFGList.GetActivityGroupInfo(groupID),
                IsGroupSelected, SetGroupSelected, groupID)
            groupIndex = groupIndex + 1
            groupOrder = groups[groupIndex] and select(2, C_LFGList.GetActivityGroupInfo(groups[groupIndex]))
        end
    end

    if (#activities + #groups) > maxEntries then
        useMore = true
    end

    -- Untouched from Blizzard: "More..." opens the full activity finder with the
    -- unfiltered category, so nothing we hide is ever unreachable.
    if useMore then
        rootDescription:CreateButton(LFG_LIST_MORE, function()
            LFGListEntryCreationActivityFinder_Show(frame.ActivityFinder, frame.selectedCategory, nil,
                bit.bor(frame.baseFilters or 0, frame.selectedFilters or 0))
        end)
    end
end

-- Hooked (hooksecurefunc) to LFGListEntryCreation_SetupGroupDropdown, so it
-- runs after Blizzard installs its own menu and replaces it with the filtered
-- one. Only ever touches the Dungeons category.
-- When the option is off we return without touching the dropdown, which leaves
-- Blizzard's own (unfiltered) menu in place — it was installed by the function
-- we're hooked to, immediately before this runs.
function GC.OnSetupGroupDropdown(frame)
    if filterFailed or not IsEnhanced() then return end
    if not IsDungeonsForm(frame) then return end

    local dropdown = frame.GroupDropdown
    if not (dropdown and dropdown.SetupMenu) then return end

    SafeCall(dropdown.SetupMenu, dropdown, function(_, rootDescription)
        if pcall(BuildFilteredGroupMenu, frame, rootDescription) then return end
        -- Our menu blew up (a Blizzard signature change, most likely). Give the
        -- dropdown back to Blizzard permanently instead of leaving it empty;
        -- deferred so we're not re-entering the menu system mid-generation.
        filterFailed = true
        C_Timer.After(0, function() SafeCall(LFGListEntryCreation_SetupGroupDropdown, frame) end)
    end)
end

-- ── Reassert on show ─────────────────────────────────────────────────────────

-- How long to keep retrying while the activity list is still empty. OnShow can
-- land before Blizzard has populated the available activities for the
-- preselected dungeon, and a single deferred pass would then find no Mythic+
-- activity and give up. Self-terminating, same shape as RoleManager's
-- role-check poll.
local APPLY_RETRY_INTERVAL = 0.1   -- seconds between attempts
local APPLY_MAX_TRIES      = 10    -- ~1s total

-- Pre-selects Mythic+ difficulty and a Competitive playstyle. The Title is
-- deliberately untouched — see the note at the top of this file.
local function ApplyToEntryCreation(frame, tries)
    if not frame or not frame:IsShown() then return end
    if not IsEnhanced() then return end
    if not IsDungeonsForm(frame) then return end
    if not C_LFGList then return end

    if not EnforceMythicPlus(frame) then
        -- Activity data isn't ready (or this dungeon offers no Mythic+ tier).
        -- Retry briefly rather than silently doing nothing.
        if (tries or 0) < APPLY_MAX_TRIES then
            C_Timer.After(APPLY_RETRY_INTERVAL, function()
                ApplyToEntryCreation(frame, (tries or 0) + 1)
            end)
        end
        return
    end
    SetPlaystyle(frame, Enum and Enum.LFGEntryGeneralPlaystyle and Enum.LFGEntryGeneralPlaystyle.FunSerious)

    -- Refresh the dropdown menus + the "List Group" enabled state to reflect
    -- the above immediately, not just on next open.
    SafeCall(LFGListEntryCreation_SetupActivityDropdown, frame)
    SafeCall(LFGListEntryCreation_SetupPlayStyleDropdown, frame)
    SafeCall(LFGListEntryCreation_UpdateValidState, frame)

    -- Setting `generalPlaystyle` only changes the backing value — the dropdown
    -- keeps painting its default "Select Playstyle (required)" text until the
    -- menu re-evaluates its radios' IsSelected callbacks. Blizzard's own code
    -- never needs this (picking from the menu repaints it inherently), which is
    -- why it only calls GenerateMenu on the Group/Activity dropdowns. Force it
    -- here so the control visibly reads "Competitive".
    local playStyle = frame.PlayStyleDropdown
    if playStyle and playStyle.GenerateMenu then
        SafeCall(playStyle.GenerateMenu, playStyle)
    end
end

-- Deferred one frame so this runs strictly after everything Blizzard's own
-- LFGListEntryCreation_Show → Clear()/Select() (and any same-frame follow-up,
-- e.g. activity data arriving) has settled — the same "defer past Blizzard's
-- own reset" pattern FrameHook uses for the note box. Fires on every show for
-- the Dungeons category, regardless of why Blizzard reset the form (delisting,
-- a fresh "Start a Group", or its own current-area default).
function GC.OnEntryCreationShow(frame)
    if not IsEnhanced() then return end
    if not IsDungeonsForm(frame) then return end
    C_Timer.After(0, function() ApplyToEntryCreation(frame, 0) end)
end

-- Called by Options whenever a setting changes, so ticking/unticking the
-- option takes effect on a form that's already open instead of waiting for a
-- reload. Re-running Blizzard's own SetupGroupDropdown is what does the work:
-- it installs the unfiltered menu, and our hook then either replaces it with
-- the filtered one (option on) or leaves it alone (option off).
--
-- Turning the option off never *undoes* a difficulty/playstyle we already
-- applied — it only stops enforcing, leaving the player free to change them.
function GC.Refresh()
    local frame = LFGListFrame and LFGListFrame.EntryCreation
    if not (frame and frame.IsShown and frame:IsShown()) then return end
    if not IsDungeonsForm(frame) then return end

    SafeCall(LFGListEntryCreation_SetupGroupDropdown, frame)
    ApplyToEntryCreation(frame, 0)
end
