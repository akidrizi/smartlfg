-- English (enUS) is the authoritative base — every key must be defined here.
-- All other locale tables are metatabled against L_enUS, so any key that
-- has not been translated yet falls back to English automatically.
-- No nil errors, no "must duplicate every key" rule.
--
-- Adding a new string: add it to L_enUS only. Other locales show English
-- until a translator provides an override.

local _, SmartLFG = ...

-- ---------------------------------------------------------------------------
-- English (enUS / default) — every key must be defined here
-- ---------------------------------------------------------------------------
local L_enUS = {
    -- Startup
    WELCOME              = "v%s  ·  /slfg",

    -- Premade sign-up
    NO_SIGNUP_BTN        = "Could not find the sign-up button.",

    -- Warning when trying to sign up with no role selected
    ROLE_REQUIRED        = "Select a role in /slfg before signing up.",

    -- Role display names (used in colored output)
    ROLE_TANK            = "Tank",
    ROLE_HEALER          = "Healer",
    ROLE_DPS             = "DPS",

    -- /slfg on|off
    ADDON_ENABLED        = "SmartLFG enabled.",
    ADDON_DISABLED       = "SmartLFG disabled.",

    -- Options panel
    OPTIONS_VERSION      = "Version: %s",
    OPTIONS_ENABLE       = "Enable SmartLFG",
    OPTIONS_ENABLE_DESC  = "Master switch for all SmartLFG features. Toggle anytime with /slfg on or /slfg off.",
    OPTIONS_QUICKSIGNUP      = "Quick sign-up",
    OPTIONS_QUICKSIGNUP_DESC = "Double-click a Premade Groups listing to sign up, Shift + Double-click to add a note," ..
                               " and show the sign-up hint on listing tooltips.",
    OPTIONS_AUTOACCEPT       = "Auto-accept role checks",
    OPTIONS_AUTOACCEPT_DESC  = "Automatically accept the role check popup when a group leader queues your group.",
    OPTIONS_ROLE         = "Sign-up roles",
    OPTIONS_ROLE_DESC    = "The roles you sign up as. Pick one or more your class can perform —" ..
                           " these are your Dungeon Finder roles.",

    -- Tooltip hint (LFG rows) — rendered as two lines with a blank line between
    TOOLTIP_QUICK_SIGNUP = "Double-click to quickly sign up.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Double-click to add a note.",
}

-- ---------------------------------------------------------------------------
-- German (deDE)
-- ---------------------------------------------------------------------------
local L_deDE = setmetatable({
    NO_SIGNUP_BTN        = "Anmelde-Schaltfläche nicht gefunden.",
    ROLE_HEALER          = "Heiler",
    ADDON_ENABLED        = "SmartLFG aktiviert.",
    ADDON_DISABLED       = "SmartLFG deaktiviert.",
    TOOLTIP_QUICK_SIGNUP = "Doppelklick für schnelles Anmelden.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Doppelklick zum Hinzufügen einer Notiz.",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- French (frFR)
-- ---------------------------------------------------------------------------
local L_frFR = setmetatable({
    NO_SIGNUP_BTN        = "Bouton d'inscription introuvable.",
    ROLE_HEALER          = "Soignant",
    ADDON_ENABLED        = "SmartLFG activé.",
    ADDON_DISABLED       = "SmartLFG désactivé.",
    OPTIONS_VERSION      = "Version : %s",
    TOOLTIP_QUICK_SIGNUP = "Double-cliquez pour vous inscrire rapidement.",
    TOOLTIP_SHIFT_NOTE   = "Maj + Double-clic pour ajouter une note.",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Spanish (esES / esMX)
-- ---------------------------------------------------------------------------
local L_esES = setmetatable({
    NO_SIGNUP_BTN        = "No se encontró el botón de registro.",
    ROLE_HEALER          = "Sanador",
    ADDON_ENABLED        = "SmartLFG activado.",
    ADDON_DISABLED       = "SmartLFG desactivado.",
    OPTIONS_VERSION      = "Versión: %s",
    TOOLTIP_QUICK_SIGNUP = "Doble clic para apuntarte rápido.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Doble clic para añadir una nota.",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Russian (ruRU)
-- ---------------------------------------------------------------------------
local L_ruRU = setmetatable({
    NO_SIGNUP_BTN        = "Кнопка записи не найдена.",
    ROLE_TANK            = "Танк",
    ROLE_HEALER          = "Целитель",
    ADDON_ENABLED        = "SmartLFG включён.",
    ADDON_DISABLED       = "SmartLFG отключён.",
    OPTIONS_VERSION      = "Версия: %s",
    TOOLTIP_QUICK_SIGNUP = "Двойной щелчок для быстрой записи.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Двойной щелчок для добавления примечания.",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Portuguese Brazil (ptBR)
-- ---------------------------------------------------------------------------
local L_ptBR = setmetatable({
    NO_SIGNUP_BTN        = "Botão de inscrição não encontrado.",
    ROLE_TANK            = "Tanque",
    ROLE_HEALER          = "Curandeiro",
    ADDON_ENABLED        = "SmartLFG ativado.",
    ADDON_DISABLED       = "SmartLFG desativado.",
    OPTIONS_VERSION      = "Versão: %s",
    TOOLTIP_QUICK_SIGNUP = "Clique duplo para se inscrever rapidamente.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Clique duplo para adicionar uma nota.",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Italian (itIT)
-- ---------------------------------------------------------------------------
local L_itIT = setmetatable({
    NO_SIGNUP_BTN        = "Pulsante di iscrizione non trovato.",
    ROLE_HEALER          = "Curatore",
    ADDON_ENABLED        = "SmartLFG abilitato.",
    ADDON_DISABLED       = "SmartLFG disabilitato.",
    OPTIONS_VERSION      = "Versione: %s",
    TOOLTIP_QUICK_SIGNUP = "Doppio clic per iscriverti rapidamente.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Doppio clic per aggiungere una nota.",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Route to the correct locale table; fall back to English.
-- ---------------------------------------------------------------------------
local locale = GetLocale()
if     locale == "deDE" then SmartLFG.L = L_deDE
elseif locale == "frFR" then SmartLFG.L = L_frFR
elseif locale == "esES" then SmartLFG.L = L_esES
elseif locale == "esMX" then SmartLFG.L = L_esES
elseif locale == "ruRU" then SmartLFG.L = L_ruRU
elseif locale == "ptBR" then SmartLFG.L = L_ptBR
elseif locale == "itIT" then SmartLFG.L = L_itIT
else                         SmartLFG.L = L_enUS
end
