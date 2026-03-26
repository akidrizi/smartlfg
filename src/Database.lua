-- src/Database.lua
-- Manages SmartLFGDB (SavedVariables) with versioned defaults.

local addonName, SmartLFG = ...

-- ---------------------------------------------------------------------------
-- SavedVariables schema version — bump when adding new keys so existing
-- installs get the new defaults merged in automatically.
-- ---------------------------------------------------------------------------
local SCHEMA_VERSION = 3

-- ---------------------------------------------------------------------------
-- Default values applied on first load or after a schema upgrade.
-- ---------------------------------------------------------------------------
local DEFAULTS = {
    schemaVersion     = SCHEMA_VERSION,
    enabled           = true,
    autoAcceptFriends = true,
    tooltipHint       = true,
}

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------
SmartLFG.DB = {}

--- Called from ADDON_LOADED. Merges defaults into SmartLFGDB.
function SmartLFG.DB.Init()
    -- SmartLFGDB is declared in the .toc SavedVariables line and is guaranteed
    -- to exist (as an empty table on first run) by the time ADDON_LOADED fires.
    SmartLFGDB = SmartLFGDB or {}

    -- Schema upgrade: if the stored version is older, re-apply new defaults
    -- while preserving any keys the user has already set.
    if (SmartLFGDB.schemaVersion or 0) < SCHEMA_VERSION then
        for k, v in pairs(DEFAULTS) do
            if SmartLFGDB[k] == nil then
                SmartLFGDB[k] = v
            end
        end
        -- v2: selectedRole removed — role is now read live from the LFD panel.
        -- v3: tooltipHint added.
        SmartLFGDB.selectedRole = nil
        SmartLFGDB.schemaVersion = SCHEMA_VERSION
    end
end

--- Convenience getter — avoids scattering SmartLFGDB references everywhere.
function SmartLFG.DB.Get(key)
    return SmartLFGDB[key]
end

--- Convenience setter.
function SmartLFG.DB.Set(key, value)
    SmartLFGDB[key] = value
end

