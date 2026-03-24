-- src/Commands.lua
-- Registers and handles /slfg slash commands.

local addonName, SmartLFG = ...
local C = SmartLFG.COLOR

-- ---------------------------------------------------------------------------
-- Help text
-- ---------------------------------------------------------------------------
local function PrintHelp()
    SmartLFG.Print("=== SmartLFG ===")
    SmartLFG.Print(C.ROLE .. "/slfg status"           .. C.RESET .. " — Current settings")
    SmartLFG.Print(C.ROLE .. "/slfg enable"           .. C.RESET .. " — Enable SmartLFG")
    SmartLFG.Print(C.ROLE .. "/slfg disable"          .. C.RESET .. " — Disable SmartLFG")
    SmartLFG.Print(C.ROLE .. "/slfg friends <on|off>" .. C.RESET .. " — Toggle friend auto-accept")
    SmartLFG.Print("Set your role in the Dungeon Finder (" ..
        C.ROLE .. SmartLFG.GetDungeonFinderKey() .. C.RESET .. ").")
end

-- ---------------------------------------------------------------------------
-- /slfg status
-- ---------------------------------------------------------------------------
local function CmdStatus()
    local enabled     = SmartLFG.DB.Get("enabled")
    local autoFriends = SmartLFG.DB.Get("autoAcceptFriends")
    local roleDisplay = SmartLFG.GetLFDRoleDisplay() or (C.WARN .. "None ticked" .. C.RESET)

    SmartLFG.Print("=== SmartLFG Status ===")
    SmartLFG.Print("Enabled: " .. (enabled     and C.OK .. "YES" or C.WARN .. "NO")  .. C.RESET)
    SmartLFG.Print("Class: " .. SmartLFG.GetClassColoredName())
    SmartLFG.Print("LFD role(s): " .. roleDisplay)
    SmartLFG.Print("Friend auto-accept: " .. (autoFriends and C.OK .. "ON"  or C.WARN .. "OFF") .. C.RESET)
end

-- ---------------------------------------------------------------------------
-- /slfg friends
-- ---------------------------------------------------------------------------
local function CmdFriends(arg)
    if arg == "on" or arg == "true" then
        SmartLFG.DB.Set("autoAcceptFriends", true)
        SmartLFG.Print("Friend auto-accept: " .. C.OK .. "ON" .. C.RESET .. ".")
    elseif arg == "off" or arg == "false" then
        SmartLFG.DB.Set("autoAcceptFriends", false)
        SmartLFG.Print("Friend auto-accept: " .. C.WARN .. "OFF" .. C.RESET .. ".")
    else
        SmartLFG.Warn("Usage: /slfg friends on|off")
    end
end

-- ---------------------------------------------------------------------------
-- Main dispatcher
-- ---------------------------------------------------------------------------
local function Dispatch(msg)
    msg = msg:match("^%s*(.-)%s*$"):lower()
    local cmd, arg = msg:match("^(%S+)%s*(.*)")
    cmd = cmd or ""
    arg = arg or ""

    if     cmd == "" or cmd == "help" then PrintHelp()
    elseif cmd == "status"  then CmdStatus()
    elseif cmd == "enable"  then
        SmartLFG.DB.Set("enabled", true);  SmartLFG.Print("SmartLFG " .. C.OK   .. "enabled"  .. C.RESET .. ".")
    elseif cmd == "disable" then
        SmartLFG.DB.Set("enabled", false); SmartLFG.Print("SmartLFG " .. C.WARN .. "disabled" .. C.RESET .. ".")
    elseif cmd == "friends" then CmdFriends(arg)
    else   SmartLFG.Warn("Unknown command '" .. cmd .. "'. Type /slfg help.")
    end
end

-- ---------------------------------------------------------------------------
-- Register slash commands
-- ---------------------------------------------------------------------------
SLASH_SMARTLFG1 = "/slfg"
SLASH_SMARTLFG2 = "/smartlfg"
SlashCmdList["SMARTLFG"] = Dispatch
