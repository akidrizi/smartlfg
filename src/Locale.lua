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
    OPTIONS_VERSION      = "Version %s",
    OPTIONS_ENABLE       = "Enable SmartLFG",
    OPTIONS_ENABLE_SHORT = "Enable",
    -- %s placeholders are the chat commands; the caller colors them (Options.lua).
    OPTIONS_ENABLE_DESC  = "Master switch for all SmartLFG features.\nToggle anytime with %s or %s.",
    OPTIONS_QUICKSIGNUP      = "Double-click sign-up",
    OPTIONS_QUICKSIGNUP_DESC = "Double-click on a Premade Group listing to quickly sign-up.",
    OPTIONS_AUTOACCEPT       = "Auto-accept role",
    OPTIONS_AUTOACCEPT_DESC  = "Automatically accept the role check pop-up when the group leader queues up the group.",
    OPTIONS_ROLE         = "Sign-up roles",
    -- Roles-section fallback tooltip. _TITLE is the white first line; the second
    -- line's %s are the spec's role icon and the class-colored spec name.
    OPTIONS_ROLE_INFO_TITLE = "None Selected",
    OPTIONS_ROLE_INFO       = "Uses role from Current Specialization (%s %s).",
    OPTIONS_SECTION      = "Options",
    OPTIONS_TIP          = "Tip: %s",
    OPTIONS_TIP_NOTE     = "Shift + Double-click on a listing to add a note.",

    -- Tooltip hint (LFG rows) — rendered as two lines with a blank line between
    TOOLTIP_QUICK_SIGNUP = "Double-click to quickly sign up.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Double-click to add a note.",

    -- Minimap button
    MINIMAP_TOOLTIP      = "Click to open · drag to move",
}

-- ---------------------------------------------------------------------------
-- German (deDE)
-- ---------------------------------------------------------------------------
local L_deDE = setmetatable({
    NO_SIGNUP_BTN        = "Anmelde-Schaltfläche nicht gefunden.",
    ROLE_REQUIRED        = "Wählt vor der Anmeldung eine Rolle in /slfg aus.",
    ROLE_HEALER          = "Heiler",
    ADDON_ENABLED        = "SmartLFG aktiviert.",
    ADDON_DISABLED       = "SmartLFG deaktiviert.",
    OPTIONS_ENABLE       = "SmartLFG aktivieren",
    OPTIONS_ENABLE_SHORT = "Aktivieren",
    OPTIONS_ENABLE_DESC  = "Hauptschalter für alle SmartLFG-Funktionen.\nJederzeit mit %s oder %s umschaltbar.",
    OPTIONS_QUICKSIGNUP      = "Anmeldung per Doppelklick",
    OPTIONS_QUICKSIGNUP_DESC = "Auf einen Eintrag der Vorgefertigten Gruppen doppelklicken, um sich schnell anzumelden.",
    OPTIONS_AUTOACCEPT       = "Rolle autom. annehmen",
    OPTIONS_AUTOACCEPT_DESC  = "Akzeptiert die Rollenüberprüfung automatisch, wenn der Gruppenanführer die Gruppe anmeldet.",
    OPTIONS_ROLE         = "Anmelderollen",
    OPTIONS_ROLE_INFO_TITLE = "Keine ausgewählt",
    OPTIONS_ROLE_INFO       = "Verwendet die Rolle der aktuellen Spezialisierung (%s %s).",
    OPTIONS_SECTION      = "Optionen",
    OPTIONS_TIP          = "Tipp: %s",
    OPTIONS_TIP_NOTE     = "Shift + Doppelklick auf einen Eintrag, um eine Notiz hinzuzufügen.",
    TOOLTIP_QUICK_SIGNUP = "Doppelklick für schnelles Anmelden.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Doppelklick zum Hinzufügen einer Notiz.",
    MINIMAP_TOOLTIP      = "Klicken zum Öffnen · ziehen zum Verschieben",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- French (frFR)
-- ---------------------------------------------------------------------------
local L_frFR = setmetatable({
    NO_SIGNUP_BTN        = "Bouton d'inscription introuvable.",
    ROLE_REQUIRED        = "Sélectionnez un rôle dans /slfg avant de vous inscrire.",
    ROLE_HEALER          = "Soignant",
    ADDON_ENABLED        = "SmartLFG activé.",
    ADDON_DISABLED       = "SmartLFG désactivé.",
    OPTIONS_VERSION      = "Version : %s",
    OPTIONS_ENABLE       = "Activer SmartLFG",
    OPTIONS_ENABLE_SHORT = "Activer",
    OPTIONS_ENABLE_DESC  = "Interrupteur principal de toutes les fonctions de SmartLFG.\nActivable à tout moment avec %s ou %s.",
    OPTIONS_QUICKSIGNUP      = "Inscription par double-clic",
    OPTIONS_QUICKSIGNUP_DESC = "Double-cliquez sur une annonce de groupe prédéfini pour vous inscrire rapidement.",
    OPTIONS_AUTOACCEPT       = "Accepter le rôle auto.",
    OPTIONS_AUTOACCEPT_DESC  = "Accepte automatiquement la vérification des rôles lorsque le chef de groupe inscrit le groupe.",
    OPTIONS_ROLE         = "Rôles d'inscription",
    OPTIONS_ROLE_INFO_TITLE = "Aucun sélectionné",
    OPTIONS_ROLE_INFO       = "Utilise le rôle de la spécialisation actuelle (%s %s).",
    OPTIONS_TIP          = "Astuce : %s",
    OPTIONS_TIP_NOTE     = "Maj + double-clic sur une annonce pour ajouter une note.",
    TOOLTIP_QUICK_SIGNUP = "Double-cliquez pour vous inscrire rapidement.",
    TOOLTIP_SHIFT_NOTE   = "Maj + Double-clic pour ajouter une note.",
    MINIMAP_TOOLTIP      = "Cliquez pour ouvrir · glissez pour déplacer",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Spanish (esES / esMX)
-- ---------------------------------------------------------------------------
local L_esES = setmetatable({
    NO_SIGNUP_BTN        = "No se encontró el botón de registro.",
    ROLE_REQUIRED        = "Selecciona un rol en /slfg antes de apuntarte.",
    ROLE_TANK            = "Tanque",
    ROLE_HEALER          = "Sanador",
    ADDON_ENABLED        = "SmartLFG activado.",
    ADDON_DISABLED       = "SmartLFG desactivado.",
    OPTIONS_VERSION      = "Versión: %s",
    OPTIONS_ENABLE       = "Activar SmartLFG",
    OPTIONS_ENABLE_SHORT = "Activar",
    OPTIONS_ENABLE_DESC  = "Interruptor principal de todas las funciones de SmartLFG.\nActívalo cuando quieras con %s o %s.",
    OPTIONS_QUICKSIGNUP      = "Apuntarse con doble clic",
    OPTIONS_QUICKSIGNUP_DESC = "Haz doble clic en un anuncio de Grupo predefinido para apuntarte rápidamente.",
    OPTIONS_AUTOACCEPT       = "Aceptar rol automát.",
    OPTIONS_AUTOACCEPT_DESC  = "Acepta automáticamente la comprobación de rol cuando el líder apunta al grupo.",
    OPTIONS_ROLE         = "Roles de inscripción",
    OPTIONS_ROLE_INFO_TITLE = "Ninguno seleccionado",
    OPTIONS_ROLE_INFO       = "Usa el rol de la especialización actual (%s %s).",
    OPTIONS_SECTION      = "Opciones",
    OPTIONS_TIP          = "Consejo: %s",
    OPTIONS_TIP_NOTE     = "Mayús + doble clic en un anuncio para añadir una nota.",
    TOOLTIP_QUICK_SIGNUP = "Doble clic para apuntarte rápido.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Doble clic para añadir una nota.",
    MINIMAP_TOOLTIP      = "Clic para abrir · arrastra para mover",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Russian (ruRU)
-- ---------------------------------------------------------------------------
local L_ruRU = setmetatable({
    NO_SIGNUP_BTN        = "Кнопка записи не найдена.",
    ROLE_REQUIRED        = "Выберите роль в /slfg перед записью.",
    ROLE_TANK            = "Танк",
    ROLE_HEALER          = "Целитель",
    ADDON_ENABLED        = "SmartLFG включён.",
    ADDON_DISABLED       = "SmartLFG отключён.",
    OPTIONS_VERSION      = "Версия: %s",
    OPTIONS_ENABLE       = "Включить SmartLFG",
    OPTIONS_ENABLE_SHORT = "Включить",
    OPTIONS_ENABLE_DESC  = "Главный переключатель всех функций SmartLFG.\nПереключается в любой момент через %s или %s.",
    OPTIONS_QUICKSIGNUP      = "Запись двойным щелчком",
    OPTIONS_QUICKSIGNUP_DESC = "Дважды щёлкните по объявлению готовой группы, чтобы быстро записаться.",
    OPTIONS_AUTOACCEPT       = "Авто-принятие роли",
    OPTIONS_AUTOACCEPT_DESC  = "Автоматически принимает проверку ролей, когда лидер записывает группу.",
    OPTIONS_ROLE         = "Роли для записи",
    OPTIONS_ROLE_INFO_TITLE = "Ничего не выбрано",
    OPTIONS_ROLE_INFO       = "Использует роль текущей специализации (%s %s).",
    OPTIONS_SECTION      = "Настройки",
    OPTIONS_TIP          = "Совет: %s",
    OPTIONS_TIP_NOTE     = "Shift + двойной щелчок по объявлению, чтобы добавить примечание.",
    TOOLTIP_QUICK_SIGNUP = "Двойной щелчок для быстрой записи.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Двойной щелчок для добавления примечания.",
    MINIMAP_TOOLTIP      = "Щелчок — открыть · перетаскивание — переместить",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Portuguese Brazil (ptBR)
-- ---------------------------------------------------------------------------
local L_ptBR = setmetatable({
    NO_SIGNUP_BTN        = "Botão de inscrição não encontrado.",
    ROLE_REQUIRED        = "Selecione uma função em /slfg antes de se inscrever.",
    ROLE_TANK            = "Tanque",
    ROLE_HEALER          = "Curandeiro",
    ADDON_ENABLED        = "SmartLFG ativado.",
    ADDON_DISABLED       = "SmartLFG desativado.",
    OPTIONS_VERSION      = "Versão: %s",
    OPTIONS_ENABLE       = "Ativar SmartLFG",
    OPTIONS_ENABLE_SHORT = "Ativar",
    OPTIONS_ENABLE_DESC  = "Interruptor principal de todos os recursos do SmartLFG.\nAlterne a qualquer momento com %s ou %s.",
    OPTIONS_QUICKSIGNUP      = "Inscrição com clique duplo",
    OPTIONS_QUICKSIGNUP_DESC = "Clique duas vezes em um anúncio de Grupo Pré-formado para se inscrever rapidamente.",
    OPTIONS_AUTOACCEPT       = "Auto-aceitar função",
    OPTIONS_AUTOACCEPT_DESC  = "Aceita automaticamente a verificação de função quando o líder inscreve o grupo.",
    OPTIONS_ROLE         = "Funções de inscrição",
    OPTIONS_ROLE_INFO_TITLE = "Nenhuma selecionada",
    OPTIONS_ROLE_INFO       = "Usa a função da especialização atual (%s %s).",
    OPTIONS_SECTION      = "Opções",
    OPTIONS_TIP          = "Dica: %s",
    OPTIONS_TIP_NOTE     = "Shift + clique duplo em um anúncio para adicionar uma nota.",
    TOOLTIP_QUICK_SIGNUP = "Clique duplo para se inscrever rapidamente.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Clique duplo para adicionar uma nota.",
    MINIMAP_TOOLTIP      = "Clique para abrir · arraste para mover",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Italian (itIT)
-- ---------------------------------------------------------------------------
local L_itIT = setmetatable({
    NO_SIGNUP_BTN        = "Pulsante di iscrizione non trovato.",
    ROLE_REQUIRED        = "Seleziona un ruolo in /slfg prima di iscriverti.",
    ROLE_HEALER          = "Curatore",
    ADDON_ENABLED        = "SmartLFG abilitato.",
    ADDON_DISABLED       = "SmartLFG disabilitato.",
    OPTIONS_VERSION      = "Versione: %s",
    OPTIONS_ENABLE       = "Attiva SmartLFG",
    OPTIONS_ENABLE_SHORT = "Attiva",
    OPTIONS_ENABLE_DESC  = "Interruttore principale per tutte le funzioni di SmartLFG.\nAttivabile in qualsiasi momento con %s o %s.",
    OPTIONS_QUICKSIGNUP      = "Iscrizione con doppio clic",
    OPTIONS_QUICKSIGNUP_DESC = "Fai doppio clic su un annuncio di Gruppo Predefinito per iscriverti rapidamente.",
    OPTIONS_AUTOACCEPT       = "Accetta ruolo auto.",
    OPTIONS_AUTOACCEPT_DESC  = "Accetta automaticamente il controllo dei ruoli quando il capogruppo iscrive il gruppo.",
    OPTIONS_ROLE         = "Ruoli d'iscrizione",
    OPTIONS_ROLE_INFO_TITLE = "Nessuno selezionato",
    OPTIONS_ROLE_INFO       = "Usa il ruolo della specializzazione attuale (%s %s).",
    OPTIONS_SECTION      = "Opzioni",
    OPTIONS_TIP          = "Consiglio: %s",
    OPTIONS_TIP_NOTE     = "Shift + doppio clic su un annuncio per aggiungere una nota.",
    TOOLTIP_QUICK_SIGNUP = "Doppio clic per iscriverti rapidamente.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Doppio clic per aggiungere una nota.",
    MINIMAP_TOOLTIP      = "Clic per aprire · trascina per spostare",
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
