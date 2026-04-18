local _, SmartLFG = ...

SmartLFG.RoleManager = {}
local RM = SmartLFG.RoleManager

local LISTING_JOIN_TTL = 180
local pendingListingJoin
local pendingActivityLabel
local noteMode = false

function RM.SetNoteMode(val)
    noteMode = not not val
end

function RM.IsNoteMode()
    return noteMode
end

local activityNameCache = {}

function RM.CacheActivityName(resultID, name)
    if resultID and name and name ~= "" then
        activityNameCache[resultID] = name
    end
end

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
    "applied", "invited", "inviteaccepted", "declined",
    "cancelled", "invitedeclined", "timedout", "failed",
}) do
    local value = _G["LFG_LIST_APPLICATION_STATUS_" .. string.upper(key)]
    if value ~= nil then
        APPLICATION_STATUS_BY_VALUE[value] = key
    end
end

local function NormalizeApplicationStatus(status)
    if status == nil then return nil end
    if type(status) == "string" then return status:lower() end
    return APPLICATION_STATUS_BY_VALUE[status] or tostring(status):lower()
end

local function GetCurrentApplicationStatus(resultID)
    if not (C_LFGList and C_LFGList.GetApplicationInfo) then return nil end
    local info = C_LFGList.GetApplicationInfo(resultID)
    if type(info) == "table" then
        return NormalizeApplicationStatus(
            info.applicationStatus or info.status or info.appStatus or info.pendingStatus
        )
    end
    return NormalizeApplicationStatus(info)
end

local function HasActiveApplication(resultID)
    if not resultID then return false end
    local status = GetCurrentApplicationStatus(resultID)
    return status == "applied" or status == "invited" or status == "inviteaccepted"
end

local function HasRoleSelected()
    if SmartLFG.HasLFDRoleSelected() then return true end
    local key = SmartLFG.COLOR.ROLE .. SmartLFG.GetGroupFinderKey() .. SmartLFG.COLOR.RESET
    SmartLFG.Warn(string.format(SmartLFG.L.NO_ROLE, key))
    return false
end

local function ResolveActivityName(activityID)
    if not activityID or activityID == 0 then return nil end
    local function tryAPI(fn)
        if not fn then return nil end
        local act = fn(activityID)
        if type(act) == "table" then
            return act.activityName or act.fullName or act.shortName or act.groupFinderActivityGroupName
        elseif type(act) == "string" and act ~= "" then
            return act
        end
    end
    return tryAPI(C_LFGList and C_LFGList.GetActivityInfoTable)
        or tryAPI(C_LFGList and C_LFGList.GetActivityInfo)
end

local function GetPremadeActivityLabel(resultID)
    if not resultID then return nil end
    if activityNameCache[resultID] then return activityNameCache[resultID] end
    if not (C_LFGList and C_LFGList.GetSearchResultInfo) then return nil end
    local info = C_LFGList.GetSearchResultInfo(resultID)
    if not info then return nil end
    if info.activityName and info.activityName ~= "" then return info.activityName end
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
    if info.name and info.name ~= "" then return info.name end
    return nil
end

local function GetSelectedPremadeResultID()
    local panel = LFGListFrame and LFGListFrame.SearchPanel
    if not panel then return nil end
    return panel.selectedResultID or panel.selectedResult or panel.selectedIndex or panel.resultID
end

function RM.SignUp()
    if not SmartLFG.IsPlayerSoloOrLeader() then return end
    if not HasRoleSelected() then return end
    local mode = GetLFGMode(LE_LFG_CATEGORY_LFD)
    if mode then return end
    LFGTeleport(false)
    SmartLFG.Print(string.format(SmartLFG.L.SIGNED_UP, SmartLFG.GetLFDRoleDisplay() or "?"))
end

function RM.ApplyToGroup(resultID, activityNameHint, withNote)
    if not SmartLFG.IsPlayerSoloOrLeader() then return end
    if not HasRoleSelected() then return end
    resultID = resultID or GetSelectedPremadeResultID()
    pendingActivityLabel = (activityNameHint and activityNameHint ~= "" and activityNameHint)
                        or GetPremadeActivityLabel(resultID)
    local signUpBtn = LFGListFrame
        and LFGListFrame.SearchPanel
        and LFGListFrame.SearchPanel.SignUpButton
    if signUpBtn then
        if signUpBtn:IsEnabled() then
            if withNote then RM.SetNoteMode(true) end
            signUpBtn:Click()
        elseif not HasActiveApplication(resultID) then
            SmartLFG.Print(SmartLFG.L.MAX_APPLICATIONS)
        end
    elseif LFGListSearchPanel_SignUp and LFGListFrame and LFGListFrame.SearchPanel then
        LFGListSearchPanel_SignUp(LFGListFrame.SearchPanel)
    else
        SmartLFG.Warn(SmartLFG.L.NO_SIGNUP_BTN)
    end
end

function RM.AutoAcceptRoleCheck()
    if not SmartLFG.DB.Get("autoAcceptFriends") then return end
    local leader, leaderUnit = SmartLFG.GetGroupLeader()
    if not SmartLFG.IsFriend(leader) then return end
    if not HasRoleSelected() then return end
    local btn = LFDRoleCheckPopupAcceptButton
    if not (btn and btn:IsVisible()) then return end
    btn:Click()
    local C = SmartLFG.COLOR
    local _, classFile = UnitClass(leaderUnit or "player")
    local leaderColor = SmartLFG.CLASS_COLOR[classFile] or C.OK
    SmartLFG.Print(string.format(SmartLFG.L.AUTO_ACCEPTED,
        SmartLFG.GetLFDRoleDisplay() or "?",
        leaderColor .. tostring(leader) .. C.RESET
    ))
end

function RM.OnActiveEntryUpdate()
    if not (C_LFGList and C_LFGList.GetActiveEntryInfo) then return end
    local entry = C_LFGList.GetActiveEntryInfo()
    if not entry then return end
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
        if pendingListingJoin then
            pendingListingJoin.activity = activityName
        end
    end
end

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
        pendingActivityLabel = nil
        if newStatus == "applied" and oldStatus ~= "applied" then
            SmartLFG.Print(string.format(SmartLFG.L.APPLYING, SmartLFG.GetLFDRoleDisplay() or "?"))
        end
    end
end

function RM.MaybePrintJoinedListingGroup()
    if not pendingListingJoin then return end
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
