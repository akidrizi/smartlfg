-- .luacheckrc
-- Luacheck configuration for SmartLFG
-- https://luacheck.readthedocs.io/en/stable/config.html

-- WoW embeds Lua 5.1
std = "lua51"

-- Maximum line length (matches .editorconfig)
max_line_length = 120

-- Ignore warnings we explicitly don't care about:
--   211 — unused local variable (common in WoW addon boilerplate)
--   212 — unused argument
--   213 — unused loop variable
-- ignore = { "211", "212", "213" }

-- ── WoW API globals ────────────────────────────────────────────────────────
-- Everything the WoW client injects into the global environment.
-- Listed here so luacheck doesn't flag them as undefined globals.
-- Keep this list in sync with what src/ actually references.
globals = {
    -- Addon saved variable (declared in SmartLFG.toc)
    "SmartLFGDB",

    -- Unit / group queries
    "UnitIsGroupLeader",
    "IsInGroup",
    "UnitClass",
    "LE_PARTY_CATEGORY_HOME",

    -- LFD / queue API
    "GetLFGRoles",
    "SetLFGRoles",
    "LFDRoleCheckPopupAcceptButton",
    "ChatEdit_SendText",
    "LFGTeleport",
    "GetLFGMode",
    "LE_LFG_CATEGORY_LFD",

    -- Specialization / role API (class-based role selection)
    "GetNumSpecializations",
    "GetSpecialization",
    "GetSpecializationInfo",

    -- In-game options / settings panel
    "Settings",
    "InterfaceOptions_AddCategory",
    "GameFontNormalLarge",
    "GameFontHighlightSmall",
    "PlaySound",
    "SOUNDKIT",
    "CreateAtlasMarkup",
    "RAID_CLASS_COLORS",

    -- C_* namespaces
    "C_LFGList",
    "C_AddOns",
    "C_Timer",
    "C_ClassColor",

    -- Embedded LuaBitOp (bit flag combination for LFGList filters)
    "bit",

    -- ScrollBox (WoW 10.x+ scroll container used by Blizzard_LFGList)
    "BaseScrollBoxEvents",

    -- UI / frame
    "CreateFrame",
    "UIParent",
    "GameTooltip",
    "DEFAULT_CHAT_FRAME",
    "GetTime",
    "GetLocale",
    "IsShiftKeyDown",
    "Minimap",
    "GetCursorPosition",
    "GetMinimapShape",
    "UISpecialFrames",

    -- LFG frame globals
    "LFGParentFrame",
    "LFGListFrame",
    "LFGListApplicationDialog",
    "LFGListSearchPanel_SignUp",
    "ToggleLFDParentFrame",
    "PVEFrame_ToggleFrame",

    -- Premade Groups creation flow (LFGListFrame.EntryCreation) — see GroupCreation.
    "GROUP_FINDER_CATEGORY_ID_DUNGEONS",
    "LFGListEntryCreation_Select",
    "LFGListEntryCreation_SetupGroupDropdown",
    "LFGListEntryCreation_SetupActivityDropdown",
    "LFGListEntryCreation_SetupPlayStyleDropdown",
    "LFGListEntryCreation_UpdateValidState",
    "LFGListEntryCreationActivityFinder_Show",
    "MAX_LFG_LIST_GROUP_DROPDOWN_ENTRIES",
    "LFG_LIST_MORE",
    "Enum",
    "hooksecurefunc",

    -- Slash command registration
    "SLASH_SMARTLFG1",
    "SLASH_SMARTLFG2",
    "SlashCmdList",
}

-- ── Per-file overrides ─────────────────────────────────────────────────────
files = {
    -- Locale strings can legitimately exceed the default limit.
    ["src/Locale.lua"] = { max_line_length = 200 },
    ["src/Constants.lua"] = {
        -- Constants intentionally uses the addon table from vararg, which
        -- luacheck sees as an implicit global write. Suppress that warning.
        ignore = { "111" },
    },
}
