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

-- ── First-run role pre-selection ────────────────────────────────────────────
-- The very first time SmartLFG sees a character, pre-tick the role of its
-- current spec so sign-up works out of the box. Runs once (guarded by the
-- per-character `roleInitialized` DB flag) and never overrides a role the
-- player already has selected, so manual choices are always respected.
function RM.PreselectRoleFromSpec()
    if SmartLFG.DB.Get("roleInitialized") then return end

    -- Already has a native LFG role set: nothing to seed, just mark it done.
    if SmartLFG.HasLFDRoleSelected() then
        SmartLFG.DB.Set("roleInitialized", true)
        return
    end

    -- Spec data may not be ready yet; if so, leave the flag unset and retry
    -- on the next login rather than locking in "no role".
    local role = SmartLFG.GetCurrentSpecRole()
    if not role then return end

    SmartLFG.SetRole(role)
    SmartLFG.DB.Set("roleInitialized", true)
    SmartLFG.Options.Refresh()
end

-- ── Sign up to a Premade group ──────────────────────────────────────────────
-- Opens the application dialog. FrameHook's OnShow hook either auto-submits
-- (plain double-click) or holds it open for a note (note mode). The role comes
-- from the player's native LFG roles (set via the /slfg options panel), so we
-- never touch the secure dialog here.
function RM.ApplyToGroup(withNote)
    if not SmartLFG.IsPlayerSoloOrLeader() then return end
    if not SmartLFG.HasLFDRoleSelected() then
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
    signUpBtn:Click()
end

-- ── LFD queue sign-up (double-click in the dungeon finder) ──────────────────
-- TODO(rework A): remove once SmartLFG is Premade-only.
function RM.SignUp()
    if not SmartLFG.IsPlayerSoloOrLeader() then return end
    if not SmartLFG.HasLFDRoleSelected() then return end
    if GetLFGMode(LE_LFG_CATEGORY_LFD) then return end
    LFGTeleport(false)
end

-- ── Auto-accept role check ──────────────────────────────────────────────────
-- Tracing showed that a simulated button click fired from this (non-hardware)
-- event path intermittently gets swallowed — even retried for ~1s — while a
-- single real click always works. That's the accept button's protected click
-- path refusing addon-driven `:Click()`. So we call the underlying API
-- (`CompleteLFGRoleCheck(true)`, the same function the button's handler calls)
-- directly, which isn't gated by the button's protected click. The button click
-- stays as a fallback, and we still retry until the popup is no longer visible —
-- which reliably means the accept went through — or we hit the attempt cap.
-- Both paths are idempotent no-ops once accepted, so the loop self-terminates.
-- Accepts for any leader (the friends-list gate was removed in the overhaul).
local ACCEPT_RETRY_INTERVAL = 0.1   -- seconds between attempts
local ACCEPT_MAX_TRIES      = 10    -- ~1s total

local function tryAcceptRoleCheck(tries)
    local btn = LFDRoleCheckPopupAcceptButton
    -- Popup gone → our accept registered (or it was cancelled). Done.
    if not (btn and btn:IsVisible()) then return end

    -- Prefer the API call; fall back to the button click if it's unavailable
    -- or errors (e.g. if the function is ever protected on a given client).
    local ok = CompleteLFGRoleCheck and pcall(CompleteLFGRoleCheck, true)
    if not ok and btn:IsEnabled() then btn:Click() end

    if tries >= ACCEPT_MAX_TRIES then return end
    C_Timer.After(ACCEPT_RETRY_INTERVAL, function() tryAcceptRoleCheck(tries + 1) end)
end

function RM.AutoAcceptRoleCheck()
    if not SmartLFG.DB.Get("autoAccept") then return end
    tryAcceptRoleCheck(0)
end
