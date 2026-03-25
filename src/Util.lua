-- src/Util.lua
-- Generic helper utilities shared across SmartLFG modules.

local addonName, SmartLFG = ...
local C = SmartLFG.COLOR

-- ---------------------------------------------------------------------------
-- Chat output
-- ---------------------------------------------------------------------------

--- Print a prefixed message to the default chat frame.
--- @param msg string
function SmartLFG.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(
        C.ADDON .. "[SmartLFG]" .. C.RESET .. " " .. tostring(msg)
    )
end

--- Print an error/warning message (red prefix).
--- @param msg string
function SmartLFG.Warn(msg)
    SmartLFG.Print(C.WARN .. msg .. C.RESET)
end

--- Returns the addon version from the .toc file metadata.
--- @return string
function SmartLFG.GetAddonVersion()
    return C_AddOns.GetAddOnMetadata("SmartLFG", "Version") or "unknown"
end

-- ---------------------------------------------------------------------------
-- Class helpers
-- ---------------------------------------------------------------------------

--- Returns the classFile token for the current player (e.g. "WARRIOR").
--- @return string
function SmartLFG.GetPlayerClass()
    local _, classFile = UnitClass("player")
    return classFile
end

--- Returns the class name colored in its WoW class color.
--- @param classFile string  Optional — defaults to the current player's class.
--- @return string
function SmartLFG.GetClassColoredName(classFile)
    classFile = classFile or SmartLFG.GetPlayerClass()
    local color = SmartLFG.CLASS_COLOR[classFile] or C.RESET
    return color .. classFile .. C.RESET
end

--- Returns the key currently bound to opening the Dungeon Finder / Group
--- Finder panel, formatted for display in chat messages.
--- Falls back to a plain description if the action is unbound.
--- @return string
function SmartLFG.GetDungeonFinderKey()
    -- "TOGGLEGROUPFINDER" is the WoW binding name for the Group Finder panel
    -- (the same frame the player opens with the default "I" key).
    local key = GetBindingKey("TOGGLEGROUPFINDER")
    if key and key ~= "" then
        return key
    end
    return SmartLFG.L.KEY_FALLBACK
end

-- ---------------------------------------------------------------------------
-- LFD role helpers
-- ---------------------------------------------------------------------------

--- Reads the role tick-boxes the player has checked in the native Dungeon
--- Finder panel via GetLFGRoles() and returns a human-readable colored string.
--- Returns nil (with no output) if no role box is ticked.
---
--- Examples:  ["TANK"] ["TANK, HEALER"] ["TANK, HEALER, DPS"]
---
--- @return string|nil
function SmartLFG.GetLFDRoleDisplay()
    local _, tank, healer, dps = GetLFGRoles()
    local L, parts = SmartLFG.L, {}
    if tank   then parts[#parts + 1] = C.TANK   .. L.ROLE_TANK   .. C.RESET end
    if healer then parts[#parts + 1] = C.HEALER .. L.ROLE_HEALER .. C.RESET end
    if dps    then parts[#parts + 1] = C.DPS    .. L.ROLE_DPS    .. C.RESET end
    if #parts == 0 then return nil end
    return table.concat(parts, ", ")
end

--- Returns true when the player has ticked at least one role in the LFD panel.
--- @return boolean
function SmartLFG.HasLFDRoleSelected()
    local _, tank, healer, dps = GetLFGRoles()
    return tank or healer or dps
end

-- ---------------------------------------------------------------------------
-- Role display helpers
-- ---------------------------------------------------------------------------

--- Returns a coloured display string for a single role constant.
--- @param role string  One of SmartLFG.ROLE.*
--- @return string
function SmartLFG.RoleDisplay(role)
    local R, L = SmartLFG.ROLE, SmartLFG.L
    if role == R.TANK   then return C.TANK   .. L.ROLE_TANK    .. C.RESET end
    if role == R.HEALER then return C.HEALER .. L.ROLE_HEALER  .. C.RESET end
    if role == R.DPS    then return C.DPS    .. L.ROLE_DPS     .. C.RESET end
    return C.WARN .. L.ROLE_UNKNOWN .. C.RESET
end

-- ---------------------------------------------------------------------------
-- Friends list lookup
-- ---------------------------------------------------------------------------

--- Returns true if `name` (character name, realm optional) is on the
--- player's friends list (both BNet game accounts and in-game friends).
--- @param name string
--- @return boolean
function SmartLFG.IsFriend(name)
    if not name or name == "" then return false end
    local shortName = (name:match("^(.-)%-") or name):lower()

    -- BNet friends
    local numBNet = BNGetNumFriends()
    for i = 1, numBNet do
        local numAccounts = C_BattleNet.GetFriendNumGameAccounts(i)
        for j = 1, numAccounts do
            local info = C_BattleNet.GetFriendGameAccountInfo(i, j)
            if info and info.characterName then
                local cn = (info.characterName:match("^(.-)%-") or info.characterName):lower()
                if cn == shortName then return true end
            end
        end
    end

    -- In-game friends
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name then
            local fn = (info.name:match("^(.-)%-") or info.name):lower()
            if fn == shortName then return true end
        end
    end

    return false
end

-- ---------------------------------------------------------------------------
-- Group leader lookup
-- ---------------------------------------------------------------------------

--- Returns the name of the current group leader, or nil if not in a group.
--- @return string|nil
function SmartLFG.GetGroupLeader()
    local total = GetNumGroupMembers()
    if total == 0 then return nil end

    if UnitIsGroupLeader("player") then
        return UnitName("player")
    end

    for i = 1, math.min(total, 40) do
        local unit = (IsInRaid() and "raid" or "party") .. i
        if UnitExists(unit) and UnitIsGroupLeader(unit) then
            return UnitName(unit)
        end
    end

    return nil
end
