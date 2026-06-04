local _, SmartLFG = ...

-- Two commands only:
--   /slfg            → open the options panel (where all help/config lives)
--   /slfg on | off   → master switch, mirrored by the panel's Enable checkbox
local function Dispatch(msg)
    local L, C = SmartLFG.L, SmartLFG.COLOR
    local cmd = (msg or ""):match("^%s*(%S*)"):lower()

    if cmd == "on" then
        SmartLFG.DB.Set("enabled", true)
        SmartLFG.Options.Refresh()
        SmartLFG.Print(C.OK .. L.ADDON_ENABLED .. C.RESET)
    elseif cmd == "off" then
        SmartLFG.DB.Set("enabled", false)
        SmartLFG.Options.Refresh()
        SmartLFG.Print(C.WARN .. L.ADDON_DISABLED .. C.RESET)
    else
        SmartLFG.Options.Open()
    end
end

SLASH_SMARTLFG1 = "/slfg"
SLASH_SMARTLFG2 = "/smartlfg"
SlashCmdList["SMARTLFG"] = Dispatch
