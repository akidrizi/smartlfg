-- Manages SmartLFGDB (SavedVariables) with versioned defaults.

local _, SmartLFG = ...

-- ---------------------------------------------------------------------------
-- SavedVariables schema version — bump when adding new keys so existing
-- installs get the new defaults merged in automatically.
-- ---------------------------------------------------------------------------
local SCHEMA_VERSION = 4

-- ---------------------------------------------------------------------------
-- Default values applied on first load or after a schema upgrade.
-- ---------------------------------------------------------------------------
local DEFAULTS = {
    schemaVersion     = SCHEMA_VERSION,
    enabled           = true,
    autoAcceptFriends = true,
}

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------
SmartLFG.DB = {}

--- Called from ADDON_LOADED. Merges defaults into SmartLFGDB.
function SmartLFG.DB.Init()
    SmartLFGDB = SmartLFGDB or {}

    if (SmartLFGDB.schemaVersion or 0) < SCHEMA_VERSION then
        for k, v in pairs(DEFAULTS) do
            if SmartLFGDB[k] == nil then
                SmartLFGDB[k] = v
            end
        end

        SmartLFGDB.selectedRole  = nil
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
