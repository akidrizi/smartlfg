local _, SmartLFG = ...

local SCHEMA_VERSION = 12

local DEFAULTS = {
    schemaVersion   = SCHEMA_VERSION,
    enabled         = true,
    autoAccept      = true,
    quickSignUp     = true,
    -- One-shot guard for first-run role pre-selection (see RoleManager).
    roleInitialized = false,
    -- Minimap button position, in degrees around the minimap ring.
    minimapAngle    = 200,
    -- "Enhanced listing": filter the Dungeons dropdown to the current Mythic+
    -- season and pre-select Mythic+ / Competitive (see GroupCreation).
    enhancedListing = true,
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

        -- v10: `dungeonListing` (the remembered Dungeons creation-form snapshot)
        -- is written lazily on first "List Group" click, so it needs no seeding
        -- here — it's simply nil (no memory yet) until then. Nothing to migrate.

        -- v11: `dungeonListing`'s shape changed (dropped groupID/requirement
        -- fields, added difficultyName) while iterating on GroupCreation. A
        -- pre-v11 snapshot's leftover `generalPlaystyle` value (captured before
        -- the Mythic+/Competitive baseline existed) would otherwise silently
        -- override the new baseline — 0 (Enum.LFGEntryGeneralPlaystyle.None) is
        -- truthy in Lua, so even a "nothing selected" snapshot read as
        -- "remembered". Discard it outright.
        if from < 11 then
            SmartLFGDB.dungeonListing = nil
        end

        -- v12: "Remember listing" became "Enhanced listing" — the option now
        -- gates the season filter + Mythic+/Competitive pre-selection, and the
        -- remember-the-last-listing behavior (with its `dungeonListing` store)
        -- is gone entirely. Carry the player's on/off choice across the rename
        -- rather than silently re-enabling it for anyone who turned it off.
        if from < 12 then
            if SmartLFGDB.rememberDungeonListing ~= nil then
                SmartLFGDB.enhancedListing = SmartLFGDB.rememberDungeonListing
            end
            SmartLFGDB.rememberDungeonListing = nil
            SmartLFGDB.dungeonListing = nil
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
