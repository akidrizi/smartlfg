-- Centralised constants for SmartLFG.
-- Imported first so every other module can rely on these globals.

local _, SmartLFG = ...

-- ---------------------------------------------------------------------------
-- Role identifiers
-- These match the strings expected by UnitGroupRolesAssigned() and the
-- native LFD role-check system in Midnight (12.x).
-- ---------------------------------------------------------------------------
SmartLFG.ROLE = {
    TANK   = "TANK",
    HEALER = "HEALER",
    DPS    = "DAMAGER",   -- WoW internal string for damage dealer
}

-- ---------------------------------------------------------------------------
-- UI / timing constants
-- ---------------------------------------------------------------------------
SmartLFG.DOUBLE_CLICK_THRESHOLD = 0.4   -- seconds between two clicks

-- ---------------------------------------------------------------------------
-- Chat colour codes (WoW |cAARRGGBB format, always close with |r)
-- ---------------------------------------------------------------------------
SmartLFG.COLOR = {
    ADDON   = "|cff00ccff",   -- cyan  — prefix tag
    WARN    = "|cffff4444",   -- red   — errors / warnings
    OK      = "|cff00ff00",   -- green — success / friends
    ROLE    = "|cffffcc00",   -- gold  — role names / commands
    TANK    = "|cff0066ff",   -- blue  — tank
    HEALER  = "|cff00ff66",   -- teal  — healer
    DPS     = "|cffff4444",   -- red   — dps
    RESET   = "|r",
}


