-- English (enUS) is the authoritative base — every key must be defined here
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
    WELCOME              = "v%s  ·  /slfg help",

    -- Role guard
    NO_ROLE              = "No role selected — open the Group Finder (%s) and tick at least one role.",

    -- LFD sign-up
    SIGNED_UP            = "Signed up as %s.",

    -- Premade sign-up
    APPLYING             = "Applying to group as %s.",
    MAX_APPLICATIONS     = "Maximum applications reached.",
    NO_SIGNUP_BTN        = "Could not find the sign-up button.",

    -- Role-check auto-accept
    AUTO_ACCEPTED        = "Auto-accepted role check as %s (leader: %s).",

    -- Role display names (used in colored output)
    ROLE_TANK            = "Tank",
    ROLE_HEALER          = "Healer",
    ROLE_DPS             = "DPS",

    -- /slfg help (descriptions only; command prefix colored in Commands.lua)
    HELP_HEADER          = "=== SmartLFG ===",
    HELP_STATUS          = "Current settings",
    HELP_ENABLE          = "Enable SmartLFG",
    HELP_DISABLE         = "Disable SmartLFG",
    HELP_FRIENDS         = "Toggle friend auto-accept",
    HELP_ROLE_HINT       = "Set your role in the Group Finder (%s).",

    -- /slfg status
    STATUS_HEADER        = "=== SmartLFG Status ===",
    STATUS_ENABLED       = "Enabled: ",
    STATUS_CLASS         = "Class: ",
    STATUS_ROLES         = "LFD role(s): ",
    STATUS_FRIENDS       = "Friend auto-accept: ",
    STATUS_NO_ROLE       = "None ticked",

    -- /slfg on|off
    ADDON_ENABLED        = "SmartLFG enabled.",
    ADDON_DISABLED       = "SmartLFG disabled.",

    -- Unknown command
    CMD_UNKNOWN          = "Unknown command '%s'. Type /slfg help.",

    -- Generic tokens used in status output
    YES                  = "YES",
    NO                   = "NO",
    ON                   = "ON",
    OFF                  = "OFF",

    -- Fallback when the Group Finder key is unbound
    KEY_FALLBACK         = "Group Finder key",

    -- Options panel
    OPTIONS_VERSION      = "Version: %s",
    OPTIONS_HINT         = "Access options with `/slfg`",

    -- Tooltip hint (LFG rows) — rendered as two lines with a blank line between
    TOOLTIP_QUICK_SIGNUP = "Double-click to quickly sign up.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Double-click to add a note.",

    -- Join notification
    JOINED_GROUP_FOR     = "Joined group for %s.",
    GROUP_TYPE_UNKNOWN   = "this activity",
}

-- ---------------------------------------------------------------------------
-- German (deDE)
-- Omitted (same as English): WELCOME, ROLE_TANK, ROLE_DPS, HELP_HEADER,
--   STATUS_HEADER, OPTIONS_VERSION.
-- ---------------------------------------------------------------------------
local L_deDE = setmetatable({
    NO_ROLE              = "Keine Rolle ausgewählt — öffne den Gruppensucher (%s) und wähle mindestens eine Rolle.",
    SIGNED_UP            = "Als %s angemeldet.",
    APPLYING             = "Bewerbung als %s.",
    MAX_APPLICATIONS     = "Maximale Anzahl an Bewerbungen erreicht.",
    NO_SIGNUP_BTN        = "Anmelde-Schaltfläche nicht gefunden.",
    AUTO_ACCEPTED        = "Rollenprüfung automatisch bestätigt als %s (Anführer: %s).",
    ROLE_HEALER          = "Heiler",
    HELP_STATUS          = "Aktuelle Einstellungen",
    HELP_ENABLE          = "SmartLFG einschalten",
    HELP_DISABLE         = "SmartLFG ausschalten",
    HELP_FRIENDS         = "Freunde-Auto-Bestätigung umschalten",
    HELP_ROLE_HINT       = "Setze deine Rolle im Gruppensucher (%s).",
    STATUS_ENABLED       = "Aktiviert: ",
    STATUS_CLASS         = "Klasse: ",
    STATUS_ROLES         = "LFD-Rolle(n): ",
    STATUS_FRIENDS       = "Freunde-Auto-Bestätigung: ",
    STATUS_NO_ROLE       = "Keine ausgewählt",
    ADDON_ENABLED        = "SmartLFG aktiviert.",
    ADDON_DISABLED       = "SmartLFG deaktiviert.",
    CMD_UNKNOWN          = "Unbekannter Befehl '%s'. Tippe /slfg help.",
    YES                  = "JA",
    NO                   = "NEIN",
    ON                   = "AN",
    OFF                  = "AUS",
    KEY_FALLBACK         = "Gruppensucher-Taste",
    OPTIONS_HINT         = "Optionen mit `/slfg` aufrufen",
    TOOLTIP_QUICK_SIGNUP = "Doppelklick für schnelles Anmelden.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Doppelklick zum Hinzufügen einer Notiz.",
    JOINED_GROUP_FOR     = "Gruppe beigetreten für %s.",
    GROUP_TYPE_UNKNOWN   = "diese Aktivität",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- French (frFR)
-- Omitted (same as English): WELCOME, ROLE_TANK, ROLE_DPS, HELP_HEADER,
--   ON, OFF.
-- ---------------------------------------------------------------------------
local L_frFR = setmetatable({
    NO_ROLE              = "Aucun rôle sélectionné — ouvre le Chercheur de groupe (%s) et coche au moins un rôle.",
    SIGNED_UP            = "Inscrit en tant que %s.",
    APPLYING             = "Candidature en tant que %s.",
    MAX_APPLICATIONS     = "Nombre maximum de candidatures atteint.",
    NO_SIGNUP_BTN        = "Bouton d'inscription introuvable.",
    AUTO_ACCEPTED        = "Vérification de rôle acceptée automatiquement en tant que %s (chef : %s).",
    ROLE_HEALER          = "Soignant",
    HELP_STATUS          = "Paramètres actuels",
    HELP_ENABLE          = "Activer SmartLFG",
    HELP_DISABLE         = "Désactiver SmartLFG",
    HELP_FRIENDS         = "Activer/désactiver l'acceptation automatique des amis",
    HELP_ROLE_HINT       = "Définis ton rôle dans le Chercheur de groupe (%s).",
    STATUS_HEADER        = "=== Statut SmartLFG ===",
    STATUS_ENABLED       = "Activé : ",
    STATUS_CLASS         = "Classe : ",
    STATUS_ROLES         = "Rôle(s) LFD : ",
    STATUS_FRIENDS       = "Auto-acceptation amis : ",
    STATUS_NO_ROLE       = "Aucun coché",
    ADDON_ENABLED        = "SmartLFG activé.",
    ADDON_DISABLED       = "SmartLFG désactivé.",
    CMD_UNKNOWN          = "Commande inconnue '%s'. Tape /slfg help.",
    YES                  = "OUI",
    NO                   = "NON",
    KEY_FALLBACK         = "touche Chercheur de groupe",
    OPTIONS_VERSION      = "Version : %s",
    OPTIONS_HINT         = "Accédez aux options avec `/slfg`",
    TOOLTIP_QUICK_SIGNUP = "Double-cliquez pour vous inscrire rapidement.",
    TOOLTIP_SHIFT_NOTE   = "Maj + Double-clic pour ajouter une note.",
    JOINED_GROUP_FOR     = "Vous avez rejoint un groupe pour %s.",
    GROUP_TYPE_UNKNOWN   = "cette activité",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Spanish (esES / esMX)
-- Omitted (same as English): WELCOME, ROLE_TANK, ROLE_DPS, HELP_HEADER,
--   ON, OFF.
-- ---------------------------------------------------------------------------
local L_esES = setmetatable({
    NO_ROLE              = "Ningún rol seleccionado — abre el Buscador de grupos (%s) y marca al menos un rol.",
    SIGNED_UP            = "Registrado como %s.",
    APPLYING             = "Solicitando grupo como %s.",
    MAX_APPLICATIONS     = "Número máximo de solicitudes alcanzado.",
    NO_SIGNUP_BTN        = "No se encontró el botón de registro.",
    AUTO_ACCEPTED        = "Verificación de rol aceptada automáticamente como %s (líder: %s).",
    ROLE_HEALER          = "Sanador",
    HELP_STATUS          = "Configuración actual",
    HELP_ENABLE          = "Activar SmartLFG",
    HELP_DISABLE         = "Desactivar SmartLFG",
    HELP_FRIENDS         = "Alternar aceptación automática de amigos",
    HELP_ROLE_HINT       = "Establece tu rol en el Buscador de grupos (%s).",
    STATUS_HEADER        = "=== Estado de SmartLFG ===",
    STATUS_ENABLED       = "Activado: ",
    STATUS_CLASS         = "Clase: ",
    STATUS_ROLES         = "Rol(es) LFD: ",
    STATUS_FRIENDS       = "Auto-aceptar amigos: ",
    STATUS_NO_ROLE       = "Ninguno marcado",
    ADDON_ENABLED        = "SmartLFG activado.",
    ADDON_DISABLED       = "SmartLFG desactivado.",
    CMD_UNKNOWN          = "Comando desconocido '%s'. Escribe /slfg help.",
    YES                  = "SÍ",
    KEY_FALLBACK         = "tecla del Buscador de grupos",
    OPTIONS_VERSION      = "Versión: %s",
    OPTIONS_HINT         = "Accede a las opciones con `/slfg`",
    TOOLTIP_QUICK_SIGNUP = "Doble clic para apuntarte rápido.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Doble clic para añadir una nota.",
    JOINED_GROUP_FOR     = "Te uniste a un grupo para %s.",
    GROUP_TYPE_UNKNOWN   = "esta actividad",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Russian (ruRU)
-- Omitted (same as English): WELCOME, ROLE_DPS, HELP_HEADER.
-- ---------------------------------------------------------------------------
local L_ruRU = setmetatable({
    NO_ROLE              = "Роль не выбрана — откройте Поиск группы (%s) и отметьте хотя бы одну роль.",
    SIGNED_UP            = "Записан как %s.",
    APPLYING             = "Заявка в группу как %s.",
    MAX_APPLICATIONS     = "Достигнут максимум заявок.",
    NO_SIGNUP_BTN        = "Кнопка записи не найдена.",
    AUTO_ACCEPTED        = "Проверка роли подтверждена как %s (лидер: %s).",
    ROLE_TANK            = "Танк",
    ROLE_HEALER          = "Целитель",
    HELP_STATUS          = "Текущие настройки",
    HELP_ENABLE          = "Включить SmartLFG",
    HELP_DISABLE         = "Отключить SmartLFG",
    HELP_FRIENDS         = "Авто-принятие приглашений от друзей",
    HELP_ROLE_HINT       = "Установите роль в Поиске группы (%s).",
    STATUS_HEADER        = "=== Статус SmartLFG ===",
    STATUS_ENABLED       = "Включён: ",
    STATUS_CLASS         = "Класс: ",
    STATUS_ROLES         = "Роль(и) LFD: ",
    STATUS_FRIENDS       = "Авто-принятие друзей: ",
    STATUS_NO_ROLE       = "Ничего не отмечено",
    ADDON_ENABLED        = "SmartLFG включён.",
    ADDON_DISABLED       = "SmartLFG отключён.",
    CMD_UNKNOWN          = "Неизвестная команда '%s'. Введите /slfg help.",
    YES                  = "ДА",
    NO                   = "НЕТ",
    ON                   = "ВКЛ",
    OFF                  = "ВЫКЛ",
    KEY_FALLBACK         = "клавиша Поиска группы",
    OPTIONS_VERSION      = "Версия: %s",
    OPTIONS_HINT         = "Откройте опции через `/slfg`",
    TOOLTIP_QUICK_SIGNUP = "Двойной щелчок для быстрой записи.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Двойной щелчок для добавления примечания.",
    JOINED_GROUP_FOR     = "Вы присоединились к группе для %s.",
    GROUP_TYPE_UNKNOWN   = "этого занятия",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Portuguese Brazil (ptBR)
-- Omitted (same as English): WELCOME, ROLE_DPS, HELP_HEADER, ON, OFF.
-- ---------------------------------------------------------------------------
local L_ptBR = setmetatable({
    NO_ROLE              = "Nenhum papel selecionado — abra o Localizador de Grupos (%s) e marque um papel.",
    SIGNED_UP            = "Inscrito como %s.",
    APPLYING             = "Candidatando ao grupo como %s.",
    MAX_APPLICATIONS     = "Número máximo de candidaturas atingido.",
    NO_SIGNUP_BTN        = "Botão de inscrição não encontrado.",
    AUTO_ACCEPTED        = "Verificação de papel aceita automaticamente como %s (líder: %s).",
    ROLE_TANK            = "Tanque",
    ROLE_HEALER          = "Curandeiro",
    HELP_STATUS          = "Configurações atuais",
    HELP_ENABLE          = "Ativar SmartLFG",
    HELP_DISABLE         = "Desativar SmartLFG",
    HELP_FRIENDS         = "Alternar aceitação automática de amigos",
    HELP_ROLE_HINT       = "Defina seu papel no Localizador de Grupos (%s).",
    STATUS_HEADER        = "=== Status SmartLFG ===",
    STATUS_ENABLED       = "Ativado: ",
    STATUS_CLASS         = "Classe: ",
    STATUS_ROLES         = "Papel(éis) LFD: ",
    STATUS_FRIENDS       = "Aceitação automática de amigos: ",
    STATUS_NO_ROLE       = "Nenhum marcado",
    ADDON_ENABLED        = "SmartLFG ativado.",
    ADDON_DISABLED       = "SmartLFG desativado.",
    CMD_UNKNOWN          = "Comando desconhecido '%s'. Digite /slfg help.",
    YES                  = "SIM",
    NO                   = "NÃO",
    KEY_FALLBACK         = "tecla do Localizador de Grupos",
    OPTIONS_VERSION      = "Versão: %s",
    OPTIONS_HINT         = "Acesse as opções com `/slfg`",
    TOOLTIP_QUICK_SIGNUP = "Clique duplo para se inscrever rapidamente.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Clique duplo para adicionar uma nota.",
    JOINED_GROUP_FOR     = "Entrou no grupo para %s.",
    GROUP_TYPE_UNKNOWN   = "esta atividade",
}, { __index = L_enUS })

-- ---------------------------------------------------------------------------
-- Italian (itIT)
-- Omitted (same as English): WELCOME, ROLE_TANK, ROLE_DPS, HELP_HEADER,
--   ON, OFF.
-- ---------------------------------------------------------------------------
local L_itIT = setmetatable({
    NO_ROLE              = "Nessun ruolo selezionato — apri il Cercatore di Gruppo (%s) e spunta almeno un ruolo.",
    SIGNED_UP            = "Iscritto come %s.",
    APPLYING             = "Candidatura al gruppo come %s.",
    MAX_APPLICATIONS     = "Numero massimo di candidature raggiunto.",
    NO_SIGNUP_BTN        = "Pulsante di iscrizione non trovato.",
    AUTO_ACCEPTED        = "Verifica del ruolo accettata automaticamente come %s (leader: %s).",
    ROLE_HEALER          = "Curatore",
    HELP_STATUS          = "Impostazioni attuali",
    HELP_ENABLE          = "Abilita SmartLFG",
    HELP_DISABLE         = "Disabilita SmartLFG",
    HELP_FRIENDS         = "Attiva/disattiva accettazione automatica amici",
    HELP_ROLE_HINT       = "Imposta il tuo ruolo nel Cercatore di Gruppo (%s).",
    STATUS_HEADER        = "=== Stato SmartLFG ===",
    STATUS_ENABLED       = "Abilitato: ",
    STATUS_CLASS         = "Classe: ",
    STATUS_ROLES         = "Ruolo/i LFD: ",
    STATUS_FRIENDS       = "Auto-accettazione amici: ",
    STATUS_NO_ROLE       = "Nessuno selezionato",
    ADDON_ENABLED        = "SmartLFG abilitato.",
    ADDON_DISABLED       = "SmartLFG disabilitato.",
    CMD_UNKNOWN          = "Comando sconosciuto '%s'. Digita /slfg help.",
    YES                  = "SÌ",
    KEY_FALLBACK         = "tasto del Cercatore di Gruppo",
    OPTIONS_VERSION      = "Versione: %s",
    OPTIONS_HINT         = "Accedi alle opzioni con `/slfg`",
    TOOLTIP_QUICK_SIGNUP = "Doppio clic per iscriverti rapidamente.",
    TOOLTIP_SHIFT_NOTE   = "Shift + Doppio clic per aggiungere una nota.",
    JOINED_GROUP_FOR     = "Entrato nel gruppo per %s.",
    GROUP_TYPE_UNKNOWN   = "questa attività",
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
