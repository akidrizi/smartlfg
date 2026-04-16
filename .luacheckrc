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
ignore = { "211", "212", "213" }

-- ── WoW API globals ────────────────────────────────────────────────────────
-- Everything the WoW client injects into the global environment.
-- Listed here so luacheck doesn't flag them as undefined globals.
globals = {
    -- Addon saved variable (declared in SmartLFG.toc SavedVariables)
    "SmartLFGDB",

    -- Unit / group queries
    "UnitClass",
    "UnitName",
    "UnitExists",
    "UnitIsGroupLeader",
    "GetNumGroupMembers",
    "IsInRaid",
    "IsInGroup",
    "LE_PARTY_CATEGORY_HOME",

    -- LFD / queue API
    "GetLFGRoles",
    "LFDRoleCheckPopupAcceptButton",
    "LFGTeleport",
    "GetLFGMode",
    "LE_LFG_CATEGORY_LFD",

    -- LFG List events (used only to trigger frame re-hook, not polling)
    "LFG_LIST_SEARCH_RESULTS_RECEIVED",

    -- C_* namespaces
    "C_BattleNet",
    "C_FriendList",
    "C_LFGList",

    -- ScrollBox (WoW 10.x+ scroll container used by Blizzard_LFGList)
    "BaseScrollBoxEvents",

    -- Friends
    "BNGetNumFriends",

    -- UI / frame
    "CreateFrame",
    "UIParent",
    "GameTooltip",
    "DEFAULT_CHAT_FRAME",
    "GetTime",
    "GetBuildInfo",
    "GetBindingKey",
    "GetLocale",
    "C_AddOns",

    -- LFG frame globals
    "LFGParentFrame",
    "LFGListFrame",
    "LFGListApplicationDialog",
    "LFGListSearchPanel_SignUp",

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
