-- src/Commands.lua
-- Registers and handles /slfg slash commands.

local addonName, SmartLFG = ...

local function PrintHelp()
    local L, C = SmartLFG.L, SmartLFG.COLOR
    SmartLFG.Print(L.HELP_HEADER)
    SmartLFG.Print(C.ROLE .. "/slfg status"           .. C.RESET .. " — " .. L.HELP_STATUS)
    SmartLFG.Print(C.ROLE .. "/slfg enable"           .. C.RESET .. " — " .. L.HELP_ENABLE)
    SmartLFG.Print(C.ROLE .. "/slfg disable"          .. C.RESET .. " — " .. L.HELP_DISABLE)
    SmartLFG.Print(C.ROLE .. "/slfg friends <on|off>" .. C.RESET .. " — " .. L.HELP_FRIENDS)
    SmartLFG.Print(string.format(L.HELP_ROLE_HINT, C.ROLE .. SmartLFG.GetDungeonFinderKey() .. C.RESET))
end

local function CmdStatus()
    local L, C = SmartLFG.L, SmartLFG.COLOR
    local enabled     = SmartLFG.DB.Get("enabled")
    local autoFriends = SmartLFG.DB.Get("autoAcceptFriends")
    local roleDisplay = SmartLFG.GetLFDRoleDisplay() or (C.WARN .. L.STATUS_NO_ROLE .. C.RESET)
    SmartLFG.Print(L.STATUS_HEADER)
    SmartLFG.Print(L.STATUS_ENABLED  .. (enabled     and C.OK .. L.YES or C.WARN .. L.NO)  .. C.RESET)
    SmartLFG.Print(L.STATUS_CLASS    .. SmartLFG.GetClassColoredName())
    SmartLFG.Print(L.STATUS_ROLES    .. roleDisplay)
    SmartLFG.Print(L.STATUS_FRIENDS  .. (autoFriends and C.OK .. L.ON  or C.WARN .. L.OFF) .. C.RESET)
end

local function CmdFriends(arg)
    local L, C = SmartLFG.L, SmartLFG.COLOR
    if arg == "on" or arg == "true" then
        SmartLFG.DB.Set("autoAcceptFriends", true)
        SmartLFG.Print(L.STATUS_FRIENDS .. C.OK .. L.ON .. C.RESET .. ".")
    elseif arg == "off" or arg == "false" then
        SmartLFG.DB.Set("autoAcceptFriends", false)
        SmartLFG.Print(L.STATUS_FRIENDS .. C.WARN .. L.OFF .. C.RESET .. ".")
    else
        SmartLFG.Warn(L.FRIENDS_USAGE)
    end
end

local function Dispatch(msg)
    local L, C = SmartLFG.L, SmartLFG.COLOR
    msg = msg:match("^%s*(.-)%s*$"):lower()
    local cmd, arg = msg:match("^(%S+)%s*(.*)")
    cmd = cmd or ""
    arg = arg or ""

    if     cmd == "" or cmd == "help" then PrintHelp()
    elseif cmd == "status"  then CmdStatus()
    elseif cmd == "enable"  then
        SmartLFG.DB.Set("enabled", true)
        SmartLFG.Print(C.OK .. L.ADDON_ENABLED .. C.RESET)
    elseif cmd == "disable" then
        SmartLFG.DB.Set("enabled", false)
        SmartLFG.Print(C.WARN .. L.ADDON_DISABLED .. C.RESET)
    elseif cmd == "friends" then CmdFriends(arg)
    else   SmartLFG.Warn(string.format(L.CMD_UNKNOWN, cmd))
    end
end

SLASH_SMARTLFG1 = "/slfg"
SLASH_SMARTLFG2 = "/smartlfg"
SlashCmdList["SMARTLFG"] = Dispatch
