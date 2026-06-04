local _, SmartLFG = ...

local SCHEMA_VERSION = 6

local DEFAULTS = {
    schemaVersion = SCHEMA_VERSION,
    enabled       = true,
}

SmartLFG.DB = {}

function SmartLFG.DB.Init()
    SmartLFGDB = SmartLFGDB or {}

    if (SmartLFGDB.schemaVersion or 0) < SCHEMA_VERSION then
        for k, v in pairs(DEFAULTS) do
            if SmartLFGDB[k] == nil then
                SmartLFGDB[k] = v
            end
        end

        -- Roles now live in the native LFG role state, not the DB.
        SmartLFGDB.selectedRole  = nil
        SmartLFGDB.schemaVersion = SCHEMA_VERSION
    end
end

function SmartLFG.DB.Get(key)
    return SmartLFGDB[key]
end

function SmartLFG.DB.Set(key, value)
    SmartLFGDB[key] = value
end
