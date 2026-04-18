local _, SmartLFG = ...
local C = SmartLFG.COLOR

SmartLFG.CLASS_COLOR = { RESET = "|r" }
if RAID_CLASS_COLORS then
    for classFile, color in pairs(RAID_CLASS_COLORS) do
        SmartLFG.CLASS_COLOR[classFile] = string.format("|cff%02x%02x%02x",
            color.r * 255, color.g * 255, color.b * 255)
    end
end

function SmartLFG.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(
        C.ADDON .. "[SmartLFG]" .. C.RESET .. " " .. tostring(msg)
    )
end

function SmartLFG.Warn(msg)
    SmartLFG.Print(C.WARN .. msg .. C.RESET)
end

function SmartLFG.GetAddonVersion()
    return C_AddOns.GetAddOnMetadata("SmartLFG", "Version") or "unknown"
end

function SmartLFG.GetPlayerClass()
    local _, classFile = UnitClass("player")
    return classFile
end

function SmartLFG.GetClassColoredName(classFile)
    classFile = classFile or SmartLFG.GetPlayerClass()
    local color = SmartLFG.CLASS_COLOR[classFile] or C.RESET
    local displayName = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile]) or classFile
    return color .. displayName .. C.RESET
end

function SmartLFG.GetGroupFinderKey()
    local key = GetBindingKey("TOGGLEGROUPFINDER")
    if key and key ~= "" then
        return key
    end
    return SmartLFG.L.KEY_FALLBACK
end

function SmartLFG.GetLFDRoleDisplay()
    local _, tank, healer, dps = GetLFGRoles()
    local L, parts = SmartLFG.L, {}
    if tank   then parts[#parts + 1] = C.TANK   .. L.ROLE_TANK   .. C.RESET end
    if healer then parts[#parts + 1] = C.HEALER .. L.ROLE_HEALER .. C.RESET end
    if dps    then parts[#parts + 1] = C.DPS    .. L.ROLE_DPS    .. C.RESET end
    if #parts == 0 then return nil end
    return table.concat(parts, ", ")
end

function SmartLFG.HasLFDRoleSelected()
    local _, tank, healer, dps = GetLFGRoles()
    return tank or healer or dps
end

function SmartLFG.IsFriend(name)
    if not name or name == "" then return false end

    local function strip(n) return (n:match("^(.-)%-") or n):lower() end
    local shortName = strip(name)

    for i = 1, BNGetNumFriends() do
        for j = 1, C_BattleNet.GetFriendNumGameAccounts(i) do
            local info = C_BattleNet.GetFriendGameAccountInfo(i, j)
            if info and info.characterName and strip(info.characterName) == shortName then
                return true
            end
        end
    end

    for i = 1, C_FriendList.GetNumFriends() do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name and strip(info.name) == shortName then
            return true
        end
    end

    return false
end

function SmartLFG.IsPlayerSoloOrLeader()
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then return true end
    return UnitIsGroupLeader("player")
end

function SmartLFG.GetGroupLeader()
    local total = GetNumGroupMembers()
    if total == 0 then return nil, nil end

    if UnitIsGroupLeader("player") then
        return UnitName("player"), "player"
    end

    for i = 1, math.min(total, 40) do
        local unit = (IsInRaid() and "raid" or "party") .. i
        if UnitExists(unit) and UnitIsGroupLeader(unit) then
            return UnitName(unit), unit
        end
    end

    return nil, nil
end
