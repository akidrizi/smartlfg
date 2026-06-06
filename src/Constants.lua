local _, SmartLFG = ...

SmartLFG.COLOR = {
    ADDON   = "|cff00ccff",
    WARN    = "|cffff4444",
    OK      = "|cff00ff00",
    TANK    = "|cff0066ff",
    HEALER  = "|cff00ff66",
    DPS     = "|cffff4444",
    RESET   = "|r",
}

-- Role identity. We use Blizzard's modern role tokens ("TANK", "HEALER",
-- "DAMAGER") so the values line up with GetSpecializationRole. Order here
-- drives the options-panel role row.
SmartLFG.ROLES = { "TANK", "HEALER", "DAMAGER" }

-- Native role icons (the standard Group Finder role badges). Displayed at a
-- modest size in the options panel so they stay crisp rather than upscaled-soft.
SmartLFG.ROLE_ATLAS = {
    TANK    = "groupfinder-icon-role-large-tank",
    HEALER  = "groupfinder-icon-role-large-heal",
    DAMAGER = "groupfinder-icon-role-large-dps",
}
