-- src/Locale.lua
-- All user-visible strings, keyed by locale returned from GetLocale().
-- Falls back to enUS for any unsupported client language.
-- Strings with %s placeholders are meant for string.format() in the caller.

local addonName, SmartLFG = ...

-- ---------------------------------------------------------------------------
-- English (enUS / default)
-- ---------------------------------------------------------------------------
local L_enUS = {
    -- Startup
    WELCOME             = "v%s  ·  /slfg help",

    -- Role guard
    NO_ROLE             = "No role selected — open the Dungeon Finder (%s) and tick at least one role.",

    -- LFD sign-up
    ALREADY_QUEUED      = "Already in queue (state: %s). Not re-queuing.",
    SIGNED_UP           = "Signed up as %s.",

    -- Premade sign-up
    APPLYING            = "Applying to group as %s.",
    ALREADY_APPLIED     = "Already applied — waiting for the leader's response.",
    NO_SIGNUP_BTN       = "Could not find the sign-up button.",

    -- Role-check auto-accept
    AUTO_ACCEPTED       = "Auto-accepted role check as %s (leader: %s).",

    -- Role display names (used in colored output)
    ROLE_TANK           = "Tank",
    ROLE_HEALER         = "Healer",
    ROLE_DPS            = "DPS",
    ROLE_UNKNOWN        = "Unknown",

    -- /slfg help (descriptions only; command prefix colored in Commands.lua)
    HELP_HEADER         = "=== SmartLFG ===",
    HELP_STATUS         = "Current settings",
    HELP_ENABLE         = "Enable SmartLFG",
    HELP_DISABLE        = "Disable SmartLFG",
    HELP_FRIENDS        = "Toggle friend auto-accept",
    HELP_ROLE_HINT      = "Set your role in the Dungeon Finder (%s).",

    -- /slfg status
    STATUS_HEADER       = "=== SmartLFG Status ===",
    STATUS_ENABLED      = "Enabled: ",
    STATUS_CLASS        = "Class: ",
    STATUS_ROLES        = "LFD role(s): ",
    STATUS_FRIENDS      = "Friend auto-accept: ",
    STATUS_NO_ROLE      = "None ticked",

    -- /slfg enable|disable
    ADDON_ENABLED       = "SmartLFG enabled.",
    ADDON_DISABLED      = "SmartLFG disabled.",

    -- /slfg friends
    FRIENDS_USAGE       = "Usage: /slfg friends on|off",

    -- Unknown command
    CMD_UNKNOWN         = "Unknown command '%s'. Type /slfg help.",

    -- Generic tokens used in status output
    YES                 = "YES",
    NO                  = "NO",
    ON                  = "ON",
    OFF                 = "OFF",

    -- Fallback when the Group Finder key is unbound
    KEY_FALLBACK        = "Dungeon Finder key",
}

-- ---------------------------------------------------------------------------
-- German (deDE)
-- ---------------------------------------------------------------------------
local L_deDE = {
    WELCOME             = "v%s  ·  /slfg help",
    NO_ROLE             = "Keine Rolle ausgewählt — öffne den Dungeon-Sucher (%s) und wähle mindestens eine Rolle.",
    ALREADY_QUEUED      = "Bereits in der Warteschlange (Status: %s). Kein erneutes Einreihen.",
    SIGNED_UP           = "Als %s angemeldet.",
    APPLYING            = "Bewerbung als %s.",
    ALREADY_APPLIED     = "Bereits beworben — warte auf Antwort des Gruppenanführers.",
    NO_SIGNUP_BTN       = "Anmelde-Schaltfläche nicht gefunden.",
    AUTO_ACCEPTED       = "Rollenprüfung automatisch bestätigt als %s (Anführer: %s).",
    ROLE_TANK           = "Tank",
    ROLE_HEALER         = "Heiler",
    ROLE_DPS            = "DPS",
    ROLE_UNKNOWN        = "Unbekannt",
    HELP_HEADER         = "=== SmartLFG ===",
    HELP_STATUS         = "Aktuelle Einstellungen",
    HELP_ENABLE         = "SmartLFG aktivieren",
    HELP_DISABLE        = "SmartLFG deaktivieren",
    HELP_FRIENDS        = "Freunde-Auto-Bestätigung umschalten",
    HELP_ROLE_HINT      = "Setze deine Rolle im Dungeon-Sucher (%s).",
    STATUS_HEADER       = "=== SmartLFG Status ===",
    STATUS_ENABLED      = "Aktiviert: ",
    STATUS_CLASS        = "Klasse: ",
    STATUS_ROLES        = "LFD-Rolle(n): ",
    STATUS_FRIENDS      = "Freunde-Auto-Bestätigung: ",
    STATUS_NO_ROLE      = "Keine ausgewählt",
    ADDON_ENABLED       = "SmartLFG aktiviert.",
    ADDON_DISABLED      = "SmartLFG deaktiviert.",
    FRIENDS_USAGE       = "Verwendung: /slfg friends on|off",
    CMD_UNKNOWN         = "Unbekannter Befehl '%s'. Tippe /slfg help.",
    YES                 = "JA",
    NO                  = "NEIN",
    ON                  = "AN",
    OFF                 = "AUS",
    KEY_FALLBACK        = "Dungeon-Sucher-Taste",
}

-- ---------------------------------------------------------------------------
-- French (frFR)
-- ---------------------------------------------------------------------------
local L_frFR = {
    WELCOME             = "v%s  ·  /slfg help",
    NO_ROLE             = "Aucun rôle sélectionné — ouvre le Chercheur de donjon (%s) et coche au moins un rôle.",
    ALREADY_QUEUED      = "Déjà en file d'attente (état : %s). Pas de nouvelle inscription.",
    SIGNED_UP           = "Inscrit en tant que %s.",
    APPLYING            = "Candidature en tant que %s.",
    ALREADY_APPLIED     = "Déjà candidaté — en attente de la réponse du chef de groupe.",
    NO_SIGNUP_BTN       = "Bouton d'inscription introuvable.",
    AUTO_ACCEPTED       = "Vérification de rôle acceptée automatiquement en tant que %s (chef : %s).",
    ROLE_TANK           = "Tank",
    ROLE_HEALER         = "Soignant",
    ROLE_DPS            = "DPS",
    ROLE_UNKNOWN        = "Inconnu",
    HELP_HEADER         = "=== SmartLFG ===",
    HELP_STATUS         = "Paramètres actuels",
    HELP_ENABLE         = "Activer SmartLFG",
    HELP_DISABLE        = "Désactiver SmartLFG",
    HELP_FRIENDS        = "Activer/désactiver l'acceptation automatique des amis",
    HELP_ROLE_HINT      = "Définis ton rôle dans le Chercheur de donjon (%s).",
    STATUS_HEADER       = "=== Statut SmartLFG ===",
    STATUS_ENABLED      = "Activé : ",
    STATUS_CLASS        = "Classe : ",
    STATUS_ROLES        = "Rôle(s) LFD : ",
    STATUS_FRIENDS      = "Auto-acceptation amis : ",
    STATUS_NO_ROLE      = "Aucun coché",
    ADDON_ENABLED       = "SmartLFG activé.",
    ADDON_DISABLED      = "SmartLFG désactivé.",
    FRIENDS_USAGE       = "Utilisation : /slfg friends on|off",
    CMD_UNKNOWN         = "Commande inconnue '%s'. Tape /slfg help.",
    YES                 = "OUI",
    NO                  = "NON",
    ON                  = "ON",
    OFF                 = "OFF",
    KEY_FALLBACK        = "touche Chercheur de donjon",
}

-- ---------------------------------------------------------------------------
-- Spanish (esES / esMX)
-- ---------------------------------------------------------------------------
local L_esES = {
    WELCOME             = "v%s  ·  /slfg help",
    NO_ROLE             = "Ningún rol seleccionado — abre el Buscador de mazmorras (%s) y marca al menos un rol.",
    ALREADY_QUEUED      = "Ya en cola (estado: %s). No se vuelve a registrar.",
    SIGNED_UP           = "Registrado como %s.",
    APPLYING            = "Solicitando grupo como %s.",
    ALREADY_APPLIED     = "Ya solicitado — esperando la respuesta del líder.",
    NO_SIGNUP_BTN       = "No se encontró el botón de registro.",
    AUTO_ACCEPTED       = "Verificación de rol aceptada automáticamente como %s (líder: %s).",
    ROLE_TANK           = "Tanque",
    ROLE_HEALER         = "Sanador",
    ROLE_DPS            = "DPS",
    ROLE_UNKNOWN        = "Desconocido",
    HELP_HEADER         = "=== SmartLFG ===",
    HELP_STATUS         = "Configuración actual",
    HELP_ENABLE         = "Activar SmartLFG",
    HELP_DISABLE        = "Desactivar SmartLFG",
    HELP_FRIENDS        = "Alternar aceptación automática de amigos",
    HELP_ROLE_HINT      = "Establece tu rol en el Buscador de mazmorras (%s).",
    STATUS_HEADER       = "=== Estado de SmartLFG ===",
    STATUS_ENABLED      = "Activado: ",
    STATUS_CLASS        = "Clase: ",
    STATUS_ROLES        = "Rol(es) LFD: ",
    STATUS_FRIENDS      = "Auto-aceptar amigos: ",
    STATUS_NO_ROLE      = "Ninguno marcado",
    ADDON_ENABLED       = "SmartLFG activado.",
    ADDON_DISABLED      = "SmartLFG desactivado.",
    FRIENDS_USAGE       = "Uso: /slfg friends on|off",
    CMD_UNKNOWN         = "Comando desconocido '%s'. Escribe /slfg help.",
    YES                 = "SÍ",
    NO                  = "NO",
    ON                  = "ON",
    OFF                 = "OFF",
    KEY_FALLBACK        = "tecla del Buscador de mazmorras",
}

-- ---------------------------------------------------------------------------
-- Russian (ruRU)
-- ---------------------------------------------------------------------------
local L_ruRU = {
    WELCOME             = "v%s  ·  /slfg help",
    NO_ROLE             = "Роль не выбрана — откройте Поиск подземелий (%s) и отметьте хотя бы одну роль.",
    ALREADY_QUEUED      = "Уже в очереди (статус: %s). Повторная постановка не выполняется.",
    SIGNED_UP           = "Записан как %s.",
    APPLYING            = "Заявка в группу как %s.",
    ALREADY_APPLIED     = "Заявка уже подана — ожидание ответа лидера.",
    NO_SIGNUP_BTN       = "Кнопка записи не найдена.",
    AUTO_ACCEPTED       = "Проверка роли подтверждена как %s (лидер: %s).",
    ROLE_TANK           = "Танк",
    ROLE_HEALER         = "Целитель",
    ROLE_DPS            = "ДД",
    ROLE_UNKNOWN        = "Неизвестно",
    HELP_HEADER         = "=== SmartLFG ===",
    HELP_STATUS         = "Текущие настройки",
    HELP_ENABLE         = "Включить SmartLFG",
    HELP_DISABLE        = "Отключить SmartLFG",
    HELP_FRIENDS        = "Авто-принятие приглашений от друзей",
    HELP_ROLE_HINT      = "Установите роль в Поиске подземелий (%s).",
    STATUS_HEADER       = "=== Статус SmartLFG ===",
    STATUS_ENABLED      = "Включён: ",
    STATUS_CLASS        = "Класс: ",
    STATUS_ROLES        = "Роль(и) LFD: ",
    STATUS_FRIENDS      = "Авто-принятие друзей: ",
    STATUS_NO_ROLE      = "Ничего не отмечено",
    ADDON_ENABLED       = "SmartLFG включён.",
    ADDON_DISABLED      = "SmartLFG отключён.",
    FRIENDS_USAGE       = "Использование: /slfg friends on|off",
    CMD_UNKNOWN         = "Неизвестная команда '%s'. Введите /slfg help.",
    YES                 = "ДА",
    NO                  = "НЕТ",
    ON                  = "ВКЛ",
    OFF                 = "ВЫКЛ",
    KEY_FALLBACK        = "клавиша Поиска подземелий",
}

-- ---------------------------------------------------------------------------
-- Portuguese Brazil (ptBR)
-- ---------------------------------------------------------------------------
local L_ptBR = {
    WELCOME             = "v%s  ·  /slfg help",
    NO_ROLE             = "Nenhum papel selecionado — abra o Localizador de Masmorras (%s) e marque pelo menos um papel.",
    ALREADY_QUEUED      = "Já na fila (estado: %s). Não reentrando.",
    SIGNED_UP           = "Inscrito como %s.",
    APPLYING            = "Candidatando ao grupo como %s.",
    ALREADY_APPLIED     = "Já candidatado — aguardando resposta do líder.",
    NO_SIGNUP_BTN       = "Botão de inscrição não encontrado.",
    AUTO_ACCEPTED       = "Verificação de papel aceita automaticamente como %s (líder: %s).",
    ROLE_TANK           = "Tanque",
    ROLE_HEALER         = "Curandeiro",
    ROLE_DPS            = "DPS",
    ROLE_UNKNOWN        = "Desconhecido",
    HELP_HEADER         = "=== SmartLFG ===",
    HELP_STATUS         = "Configurações atuais",
    HELP_ENABLE         = "Ativar SmartLFG",
    HELP_DISABLE        = "Desativar SmartLFG",
    HELP_FRIENDS        = "Alternar aceitação automática de amigos",
    HELP_ROLE_HINT      = "Defina seu papel no Localizador de Masmorras (%s).",
    STATUS_HEADER       = "=== Status SmartLFG ===",
    STATUS_ENABLED      = "Ativado: ",
    STATUS_CLASS        = "Classe: ",
    STATUS_ROLES        = "Papel(éis) LFD: ",
    STATUS_FRIENDS      = "Aceitação automática de amigos: ",
    STATUS_NO_ROLE      = "Nenhum marcado",
    ADDON_ENABLED       = "SmartLFG ativado.",
    ADDON_DISABLED      = "SmartLFG desativado.",
    FRIENDS_USAGE       = "Uso: /slfg friends on|off",
    CMD_UNKNOWN         = "Comando desconhecido '%s'. Digite /slfg help.",
    YES                 = "SIM",
    NO                  = "NÃO",
    ON                  = "ON",
    OFF                 = "OFF",
    KEY_FALLBACK        = "tecla do Localizador de Masmorras",
}

-- ---------------------------------------------------------------------------
-- Italian (itIT)
-- ---------------------------------------------------------------------------
local L_itIT = {
    WELCOME             = "v%s  ·  /slfg help",
    NO_ROLE             = "Nessun ruolo selezionato — apri il Cercatore di Dungeon (%s) e spunta almeno un ruolo.",
    ALREADY_QUEUED      = "Già in coda (stato: %s). Nessuna nuova iscrizione.",
    SIGNED_UP           = "Iscritto come %s.",
    APPLYING            = "Candidatura al gruppo come %s.",
    ALREADY_APPLIED     = "Già candidato — in attesa della risposta del leader.",
    NO_SIGNUP_BTN       = "Pulsante di iscrizione non trovato.",
    AUTO_ACCEPTED       = "Verifica del ruolo accettata automaticamente come %s (leader: %s).",
    ROLE_TANK           = "Tank",
    ROLE_HEALER         = "Curatore",
    ROLE_DPS            = "DPS",
    ROLE_UNKNOWN        = "Sconosciuto",
    HELP_HEADER         = "=== SmartLFG ===",
    HELP_STATUS         = "Impostazioni attuali",
    HELP_ENABLE         = "Abilita SmartLFG",
    HELP_DISABLE        = "Disabilita SmartLFG",
    HELP_FRIENDS        = "Attiva/disattiva accettazione automatica amici",
    HELP_ROLE_HINT      = "Imposta il tuo ruolo nel Cercatore di Dungeon (%s).",
    STATUS_HEADER       = "=== Stato SmartLFG ===",
    STATUS_ENABLED      = "Abilitato: ",
    STATUS_CLASS        = "Classe: ",
    STATUS_ROLES        = "Ruolo/i LFD: ",
    STATUS_FRIENDS      = "Auto-accettazione amici: ",
    STATUS_NO_ROLE      = "Nessuno selezionato",
    ADDON_ENABLED       = "SmartLFG abilitato.",
    ADDON_DISABLED      = "SmartLFG disabilitato.",
    FRIENDS_USAGE       = "Uso: /slfg friends on|off",
    CMD_UNKNOWN         = "Comando sconosciuto '%s'. Digita /slfg help.",
    YES                 = "SÌ",
    NO                  = "NO",
    ON                  = "ON",
    OFF                 = "OFF",
    KEY_FALLBACK        = "tasto del Cercatore di Dungeon",
}

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





