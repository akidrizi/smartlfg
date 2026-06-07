local _, SmartLFG = ...

SmartLFG.RoleManager = {}
local RM = SmartLFG.RoleManager

-- Note mode is armed by Shift+double-click so the application dialog stays open
-- for the player to type a note, instead of auto-submitting.
--
-- We deliberately do NOT pre-fill the note: the dialog's note box is a secure
-- EditBox and SetText from an addon is blocked by Blizzard (and taints the
-- whole flow, which then blocks the protected sign-up). Shift simply holds the
-- dialog open so the player types it themselves.
local noteMode = false
function RM.SetNoteMode(v) noteMode = not not v end
function RM.IsNoteMode()   return noteMode end

-- Remembered note text for the session. We can only *read* the secure note box
-- (GetText) safely; writing it back is attempted deferred + guarded in
-- FrameHook, since a direct write taints the protected sign-up.
local noteText = ""
function RM.GetNote()     return noteText end
function RM.SetNote(text) noteText = text or "" end

-- ── Behavioral conflict self-check ──────────────────────────────────────────
-- We keep no static list of incompatible add-ons; we infer a clash from who
-- drove the sign-up. The application dialog (LFGListApplicationDialog) opening
-- is the anchor: its OnShow calls RM.NotifyDialogShown.
--
-- Two failure shapes, both reported via FlagConflict (once per session):
--   A. The dialog opens but SmartLFG did NOT initiate it (no recent ApplyToGroup)
--      AND it auto-closes immediately — i.e. another add-on's one-click sign-up
--      (e.g. Premade Groups Filter) opened and submitted it, bypassing us. We
--      require the auto-close so a human manually using Blizzard's own Sign Up
--      button (dialog stays open to type/confirm) is NOT flagged.
--   B. SmartLFG DID initiate (double-click → ApplyToGroup) but no dialog ever
--      appears — something replaced/blocked our click.
local INITIATE_WINDOW = 1.0   -- a sign-up we drove within this many seconds is "ours"
local SETTLE_DELAY    = 0.3   -- a not-by-us dialog gone by now was auto-submitted
local lastInitiated   = -100  -- GetTime() of our last ApplyToGroup (never, initially)
local sawOurDialog    = false -- did the dialog open after our most recent initiate?
local conflictDetected = false

local function FlagConflict()
    if conflictDetected then return end
    conflictDetected = true
    SmartLFG.Warn(SmartLFG.L.CONFLICT_DETECTED)   -- one-time chat warning
    SmartLFG.Options.Refresh()                    -- surface the icon if the dialog is open
end

-- Called from the application dialog's OnShow.
function RM.NotifyDialogShown()
    if (GetTime() - lastInitiated) <= INITIATE_WINDOW then
        sawOurDialog = true   -- our own double-click flow opened it (shape B is happy)
        return
    end
    -- Opened without us. Flag only if it auto-closes (automation), not if it
    -- stays open for a human (manual Blizzard sign-up).
    C_Timer.After(SETTLE_DELAY, function()
        local d = LFGListApplicationDialog
        if d and d:IsShown() then return end
        FlagConflict()
    end)
end

-- Read by Options.lua to show the warning triangle by the OPTIONS header.
-- Session state (a Lua local), so it clears on /reload or relog.
function RM.HasConflict() return conflictDetected end

-- ── First-run role pre-selection ────────────────────────────────────────────
-- The very first time SmartLFG sees a character, seed the explicit DB selection
-- (`selectedRoles`) so sign-up works out of the box. Runs once (guarded by the
-- per-character `roleInitialized` DB flag). If the player already had native LFG
-- roles configured we import those (upgrading characters keep what they chose);
-- otherwise we seed the current spec's role.
function RM.PreselectRoleFromSpec()
    if SmartLFG.DB.Get("roleInitialized") then return end

    -- Import an existing native LFG role setup as the explicit selection.
    local native = SmartLFG.GetNativeRoles()
    if next(native) then
        SmartLFG.DB.Set("selectedRoles", native)
        SmartLFG.DB.Set("roleInitialized", true)
        SmartLFG.Options.Refresh()
        return
    end

    -- Spec data may not be ready yet; if so, leave the flag unset and retry
    -- on the next login rather than locking in "no role".
    local role = SmartLFG.GetCurrentSpecRole()
    if not role then return end

    SmartLFG.DB.Set("selectedRoles", { [role] = true })
    SmartLFG.DB.Set("roleInitialized", true)
    SmartLFG.Options.Refresh()
end

-- ── Sign up to a Premade group ──────────────────────────────────────────────
-- Opens the application dialog. FrameHook's OnShow hook either auto-submits
-- (plain double-click) or holds it open for a note (note mode). We resolve and
-- write the native LFG roles first (explicit selection, else solo/group
-- fallback — see ResolveSignUpRoles); the secure dialog inherits them natively,
-- so we never touch it here.
function RM.ApplyToGroup(withNote)
    if not SmartLFG.IsPlayerSoloOrLeader() then return end
    if not SmartLFG.ApplyResolvedRoles() then
        SmartLFG.Warn(SmartLFG.L.ROLE_REQUIRED)
        return
    end

    local panel = LFGListFrame and LFGListFrame.SearchPanel
    local signUpBtn = panel and panel.SignUpButton
    if not signUpBtn then
        if LFGListSearchPanel_SignUp and panel then
            LFGListSearchPanel_SignUp(panel)
        else
            SmartLFG.Warn(SmartLFG.L.NO_SIGNUP_BTN)
        end
        return
    end
    if not signUpBtn:IsEnabled() then return end

    RM.SetNoteMode(withNote)

    -- Arm the conflict self-check (shape B): mark this as our initiation, then
    -- verify the dialog actually opened. NotifyDialogShown sets sawOurDialog when
    -- it fires within INITIATE_WINDOW; if it never does, our click was swallowed.
    lastInitiated = GetTime()
    sawOurDialog  = false
    signUpBtn:Click()
    C_Timer.After(SETTLE_DELAY, function()
        if sawOurDialog then return end   -- our dialog opened → no conflict
        FlagConflict()
    end)
end

-- ── LFD queue sign-up (double-click in the dungeon finder) ──────────────────
-- TODO(rework A): remove once SmartLFG is Premade-only.
function RM.SignUp()
    if not SmartLFG.IsPlayerSoloOrLeader() then return end
    if not SmartLFG.ApplyResolvedRoles() then return end
    if GetLFGMode(LE_LFG_CATEGORY_LFD) then return end
    LFGTeleport(false)
end

-- ── Auto-accept role check ──────────────────────────────────────────────────
-- A direct `LFDRoleCheckPopupAcceptButton:Click()` from this (non-hardware)
-- event path intermittently gets swallowed: our addon code taints the click and
-- the protected accept is silently dropped (tracing showed ~1 in 9 missed, and
-- calling CompleteLFGRoleCheck directly was worse — heavy taint). The fix is to
-- "launder" the click through the secure `/click` chat command: routing it via
-- the chat command handler runs the click inside Blizzard's secure code path,
-- not our tainted one, so the protected accept goes through cleanly.
--
-- The command must go through a real, fully-initialized chat editbox
-- (DEFAULT_CHAT_FRAME.editBox); a standalone ChatFrameEditBoxTemplate errors on
-- load because it has no backing chatFrame. To avoid clobbering a message the
-- player is mid-typing, we only hijack the editbox when it's hidden (idle); if
-- it's open we fall back to a best-effort direct click. Accepts for any leader
-- (the friends-list gate was removed in the overhaul).
local ACCEPT_RETRY_INTERVAL = 0.1   -- seconds between attempts
local ACCEPT_MAX_TRIES      = 10    -- ~1s total

local function AcceptViaSecureClick(button)
    local eb = DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
    if not eb or eb:IsShown() then
        -- Editbox busy (player typing) or unavailable: don't steal it.
        if button:IsEnabled() then button:Click() end
        return
    end
    eb:SetText("/click " .. button:GetName())
    ChatEdit_SendText(eb, 0)
end

-- `seen` tracks whether the popup has ever been visible during this run. We may
-- fire before Blizzard lays the popup out (handler order for LFG_ROLE_CHECK_SHOW
-- isn't guaranteed), so an invisible button early on means "not ready yet" — keep
-- polling. Once we've seen it and it's gone, the accept went through and we stop.
local function tryAcceptRoleCheck(tries, seen)
    local btn = LFDRoleCheckPopupAcceptButton
    if btn and btn:IsVisible() then
        AcceptViaSecureClick(btn)
        seen = true
    elseif seen then
        return  -- was visible, now gone → accepted/closed. Done.
    end

    if tries >= ACCEPT_MAX_TRIES then return end
    C_Timer.After(ACCEPT_RETRY_INTERVAL, function() tryAcceptRoleCheck(tries + 1, seen) end)
end

function RM.AutoAcceptRoleCheck()
    if not SmartLFG.DB.Get("autoAccept") then return end
    tryAcceptRoleCheck(0, false)
end
