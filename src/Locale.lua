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
    WELCOME              = "v%s  -  /slfg",

    -- Premade sign-up
    NO_SIGNUP_BTN        = "Could not find the sign up button.",

    -- Behavioral conflict self-check: our sign-up pipeline didn't open the
    -- application dialog, so another sign-up add-on likely drove it first.
    CONFLICT_TITLE       = "Add-on conflict",
    CONFLICT_DETECTED    = "Couldn't sign up. Another add-on that manages Premade Groups or LFG may be getting in the way. Try disabling those add-ons, then /reload.",

    -- OPTIONS-header quest icon tooltip explaining the per-option conflict marks.
    -- _DESC's %s is the warning-triangle icon (inline atlas markup, added by Options.lua).
    CONFLICT_INFO_TITLE  = "Conflict Detection",
    CONFLICT_INFO_DESC   = "The %s icon next to an option indicates that a conflict has been detected.",
    CONFLICT_INFO_HINT   = "Hover over the icon, when it appears, to understand the conflict.",

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
    OPTIONS_QUICKSIGNUP      = "Double-click sign up",
    OPTIONS_QUICKSIGNUP_DESC = "Double-click on a Premade Group listing to quickly sign up.",
    OPTIONS_AUTOACCEPT       = "Auto-accept role",
    OPTIONS_AUTOACCEPT_DESC  = "Automatically accept the role check pop-up when the group leader queues up the group.",
    OPTIONS_ROLE         = "Sign up roles",
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
    MINIMAP_TOOLTIP      = "Click to open - drag to move",
    -- Right-click hint; %s is the colored action (green Enable / red Disable).
    MINIMAP_RIGHTCLICK   = "Right click to %s",
    MINIMAP_ENABLE       = "Enable",
    MINIMAP_DISABLE      = "Disable",
}

-- ---------------------------------------------------------------------------
-- German (deDE)
-- ---------------------------------------------------------------------------
local L_deDE = setmetatable({
    NO_SIGNUP_BTN        = "Anmelde-Schaltfläche nicht gefunden.",
    CONFLICT_TITLE       = "Addon-Konflikt",
    CONFLICT_DETECTED    = "Anmeldung fehlgeschlagen. Ein anderes Addon, das Premade-Gruppen oder LFG verwaltet, könnte stören. "
        .. "Deaktiviere diese Addons und gib dann /reload ein.",
    CONFLICT_INFO_TITLE  = "Konflikterkennung",
    CONFLICT_INFO_DESC   = "Das %s-Symbol neben einer Option bedeutet, dass ein Konflikt erkannt wurde.",
    CONFLICT_INFO_HINT   = "Bewege den Mauszeiger über das Symbol, wenn es erscheint, um den Konflikt zu verstehen.",
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
    MINIMAP_TOOLTIP      = "Klicken zum Öffnen - ziehen zum Verschieben",
    MINIMAP_RIGHTCLICK   = "Rechtsklick zum %s",
    MINIMAP_ENABLE       = "Aktivieren",
    MINIMAP_DISABLE      = "Deaktivieren",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- French (frFR)
-- ---------------------------------------------------------------------------
local L_frFR = setmetatable({
    NO_SIGNUP_BTN        = "Bouton d'inscription introuvable.",
    CONFLICT_TITLE       = "Conflit d'add-on",
    CONFLICT_DETECTED    = "Impossible de s'inscrire. Un autre add-on qui gère les groupes Premade ou le LFG peut interférer. "
        .. "Essayez de désactiver ces add-ons, puis tapez /reload.",
    CONFLICT_INFO_TITLE  = "Détection des conflits",
    CONFLICT_INFO_DESC   = "L'icône %s à côté d'une option indique qu'un conflit a été détecté.",
    CONFLICT_INFO_HINT   = "Survolez l'icône, lorsqu'elle apparaît, pour comprendre le conflit.",
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
    MINIMAP_TOOLTIP      = "Cliquez pour ouvrir - glissez pour déplacer",
    MINIMAP_RIGHTCLICK   = "Clic droit pour %s",
    MINIMAP_ENABLE       = "activer",
    MINIMAP_DISABLE      = "désactiver",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Spanish (esES / esMX)
-- ---------------------------------------------------------------------------
local L_esES = setmetatable({
    NO_SIGNUP_BTN        = "No se encontró el botón de registro.",
    CONFLICT_TITLE       = "Conflicto de complemento",
    CONFLICT_DETECTED    = "No se pudo registrar. Otro complemento que gestiona grupos Premade o LFG puede estar interfiriendo. "
        .. "Prueba a desactivar esos complementos y luego usa /reload.",
    CONFLICT_INFO_TITLE  = "Detección de conflictos",
    CONFLICT_INFO_DESC   = "El icono %s junto a una opción indica que se ha detectado un conflicto.",
    CONFLICT_INFO_HINT   = "Pasa el cursor sobre el icono, cuando aparezca, para entender el conflicto.",
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
    MINIMAP_TOOLTIP      = "Clic para abrir - arrastra para mover",
    MINIMAP_RIGHTCLICK   = "Clic derecho para %s",
    MINIMAP_ENABLE       = "activar",
    MINIMAP_DISABLE      = "desactivar",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Russian (ruRU)
-- ---------------------------------------------------------------------------
local L_ruRU = setmetatable({
    NO_SIGNUP_BTN        = "Кнопка записи не найдена.",
    CONFLICT_TITLE       = "Конфликт аддонов",
    CONFLICT_DETECTED    = "Не удалось записаться. Другой аддон, управляющий группами Premade или LFG, может мешать. Попробуйте отключить эти аддоны, затем введите /reload.",
    CONFLICT_INFO_TITLE  = "Обнаружение конфликтов",
    CONFLICT_INFO_DESC   = "Значок %s рядом с опцией означает, что обнаружен конфликт.",
    CONFLICT_INFO_HINT   = "Наведите курсор на значок, когда он появится, чтобы понять конфликт.",
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
    MINIMAP_TOOLTIP      = "Щелчок — открыть - перетаскивание — переместить",
    MINIMAP_RIGHTCLICK   = "Правый клик, чтобы %s",
    MINIMAP_ENABLE       = "включить",
    MINIMAP_DISABLE      = "отключить",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Portuguese Brazil (ptBR)
-- ---------------------------------------------------------------------------
local L_ptBR = setmetatable({
    NO_SIGNUP_BTN        = "Botão de inscrição não encontrado.",
    CONFLICT_TITLE       = "Conflito de addon",
    CONFLICT_DETECTED    = "Não foi possível se inscrever. Outro addon que gerencia grupos Premade ou LFG pode estar interferindo. Tente desativar esses addons e depois use /reload.",
    CONFLICT_INFO_TITLE  = "Detecção de conflitos",
    CONFLICT_INFO_DESC   = "O ícone %s ao lado de uma opção indica que um conflito foi detectado.",
    CONFLICT_INFO_HINT   = "Passe o cursor sobre o ícone, quando ele aparecer, para entender o conflito.",
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
    MINIMAP_TOOLTIP      = "Clique para abrir - arraste para mover",
    MINIMAP_RIGHTCLICK   = "Clique direito para %s",
    MINIMAP_ENABLE       = "ativar",
    MINIMAP_DISABLE      = "desativar",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Italian (itIT)
-- ---------------------------------------------------------------------------
local L_itIT = setmetatable({
    NO_SIGNUP_BTN        = "Pulsante di iscrizione non trovato.",
    CONFLICT_TITLE       = "Conflitto tra addon",
    CONFLICT_DETECTED    = "Impossibile iscriversi. Un altro addon che gestisce i gruppi Premade o LFG potrebbe interferire. "
        .. "Prova a disattivare quegli addon, poi usa /reload.",
    CONFLICT_INFO_TITLE  = "Rilevamento dei conflitti",
    CONFLICT_INFO_DESC   = "L'icona %s accanto a un'opzione indica che è stato rilevato un conflitto.",
    CONFLICT_INFO_HINT   = "Passa il cursore sull'icona, quando appare, per capire il conflitto.",
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
    MINIMAP_TOOLTIP      = "Clic per aprire - trascina per spostare",
    MINIMAP_RIGHTCLICK   = "Clic destro per %s",
    MINIMAP_ENABLE       = "attivare",
    MINIMAP_DISABLE      = "disattivare",
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
