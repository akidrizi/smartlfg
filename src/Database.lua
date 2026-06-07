local _, SmartLFG = ...

local SCHEMA_VERSION = 9

local DEFAULTS = {
    schemaVersion   = SCHEMA_VERSION,
    enabled         = true,
    autoAccept      = true,
    quickSignUp     = true,
    -- One-shot guard for first-run role pre-selection (see RoleManager).
    roleInitialized = false,
    -- Minimap button position, in degrees around the minimap ring.
    minimapAngle    = 200,
}

SmartLFG.DB = {}

function SmartLFG.DB.Init()
    SmartLFGDB = SmartLFGDB or {}

    local from = SmartLFGDB.schemaVersion or 0
    if from < SCHEMA_VERSION then
        for k, v in pairs(DEFAULTS) do
            if SmartLFGDB[k] == nil then
                SmartLFGDB[k] = v
            end
        end

        -- v9: the explicit role selection now lives in the DB (`selectedRoles`,
        -- a set of role tokens), not the native LFG state. Seed the store and
        -- re-run first-run pre-selection once so existing characters import the
        -- roles they had configured. (Kept out of DEFAULTS to avoid sharing one
        -- table reference across keys.)
        if from < 9 then
            SmartLFGDB.selectedRoles   = SmartLFGDB.selectedRoles or {}
            SmartLFGDB.roleInitialized = false
        end

        -- Legacy single-role key (pre-v8); never reinstated.
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
