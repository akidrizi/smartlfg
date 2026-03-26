-- src/Commands.lua
-- Registers and handles /slfg slash commands.

local addonName, SmartLFG = ...

local function PrintHelp()
    local L, C = SmartLFG.L, SmartLFG.COLOR
    SmartLFG.Print(L.HELP_HEADER)
    SmartLFG.Print(C.ROLE .. "/slfg status"           .. C.RESET .. " — " .. L.HELP_STATUS)
    SmartLFG.Print(C.ROLE .. "/slfg enable"           .. C.RESET .. " — " .. L.HELP_ENABLE)
    SmartLFG.Print(C.ROLE .. "/slfg disable"          .. C.RESET .. " — " .. L.HELP_DISABLE)
    SmartLFG.Print(C.ROLE .. "/slfg friends"          .. C.RESET .. " — " .. L.HELP_FRIENDS)
    SmartLFG.Print(C.ROLE .. "/slfg tooltip"          .. C.RESET .. " — " .. L.HELP_TOOLTIP)
    SmartLFG.Print(string.format(L.HELP_ROLE_HINT, C.ROLE .. SmartLFG.GetDungeonFinderKey() .. C.RESET))
end

local function CmdStatus()
    local L, C = SmartLFG.L, SmartLFG.COLOR
    local enabled     = SmartLFG.DB.Get("enabled")
    local autoFriends = SmartLFG.DB.Get("autoAcceptFriends")
    local tooltipHint = SmartLFG.DB.Get("tooltipHint")
    local roleDisplay = SmartLFG.GetLFDRoleDisplay() or (C.WARN .. L.STATUS_NO_ROLE .. C.RESET)
    SmartLFG.Print(L.STATUS_HEADER)
    SmartLFG.Print(L.STATUS_ENABLED  .. (enabled     and C.OK .. L.YES or C.WARN .. L.NO)  .. C.RESET)
    SmartLFG.Print(L.STATUS_CLASS    .. SmartLFG.GetClassColoredName())
    SmartLFG.Print(L.STATUS_ROLES    .. roleDisplay)
    SmartLFG.Print(L.STATUS_FRIENDS  .. (autoFriends and C.OK .. L.ON  or C.WARN .. L.OFF) .. C.RESET)
    SmartLFG.Print(L.STATUS_TOOLTIP  .. (tooltipHint and C.OK .. L.ON  or C.WARN .. L.OFF) .. C.RESET)
end

local function CmdFriends()
    local L, C = SmartLFG.L, SmartLFG.COLOR
    local nextValue = not SmartLFG.DB.Get("autoAcceptFriends")
    SmartLFG.DB.Set("autoAcceptFriends", nextValue)
    SmartLFG.Print(L.STATUS_FRIENDS .. (nextValue and C.OK .. L.ON or C.WARN .. L.OFF) .. C.RESET .. ".")
end

local function CmdTooltip()
    local L, C = SmartLFG.L, SmartLFG.COLOR
    local nextValue = not SmartLFG.DB.Get("tooltipHint")
    SmartLFG.DB.Set("tooltipHint", nextValue)
    SmartLFG.Print(L.STATUS_TOOLTIP .. (nextValue and C.OK .. L.ON or C.WARN .. L.OFF) .. C.RESET .. ".")
end

local function Dispatch(msg)
    local L, C = SmartLFG.L, SmartLFG.COLOR
    msg = msg:match("^%s*(.-)%s*$"):lower()
    local cmd = msg:match("^(%S+)%s*")
    cmd = cmd or ""

    if     cmd == "" or cmd == "help" then PrintHelp()
    elseif cmd == "status"  then CmdStatus()
    elseif cmd == "enable"  then
        SmartLFG.DB.Set("enabled", true)
        SmartLFG.Print(C.OK .. L.ADDON_ENABLED .. C.RESET)
    elseif cmd == "disable" then
        SmartLFG.DB.Set("enabled", false)
        SmartLFG.Print(C.WARN .. L.ADDON_DISABLED .. C.RESET)
    elseif cmd == "friends" then CmdFriends()
    elseif cmd == "tooltip" then CmdTooltip()
    else   SmartLFG.Warn(string.format(L.CMD_UNKNOWN, cmd))
    end
end

SLASH_SMARTLFG1 = "/slfg"
SLASH_SMARTLFG2 = "/smartlfg"
SlashCmdList["SMARTLFG"] = Dispatch
