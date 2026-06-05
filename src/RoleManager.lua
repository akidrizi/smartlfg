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
-- A direct `LFDRoleCheckPopupAcceptButton:Click()` from addon code taints the
-- protected accept and it's intermittently dropped (calling CompleteLFGRoleCheck
-- directly was worse). So we "launder" the click through the secure `/click` chat
-- command: routing it via the chat command handler runs the click inside
-- Blizzard's secure code path, not our tainted one.
--
-- Footprint matters: every time our insecure code touches the protected popup it
-- risks leaving taint that eventually (after many checks in a session) defeats
-- both auto-accept AND the player's own manual clicks (resets on /reload). So we
-- follow the lowest-footprint community pattern (cf. AutomaticRoleCheck): hook
-- the accept button's OnShow and fire ONE `/click` — no polling/retry loop.
-- OnShow runs when the popup appears (not during a click), so it never taints the
-- player's manual click. Accepts for any leader (friends gate removed in overhaul).

-- The command must go through a real, fully-initialized chat editbox
-- (DEFAULT_CHAT_FRAME.editBox); a standalone ChatFrameEditBoxTemplate errors on
-- load (no backing chatFrame). We only hijack it while hidden (idle) so a
-- mid-typed message isn't clobbered, else fall back to a best-effort click.
local function AcceptViaSecureClick(button)
    local eb = DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
    if not eb or eb:IsShown() then
        if button:IsEnabled() then button:Click() end
        return
    end
    eb:SetText("/click " .. button:GetName())
    ChatEdit_SendText(eb, 0)
end

local function AcceptCurrentRoleCheck()
    -- Defer a frame so the popup is laid out / the button enabled.
    C_Timer.After(0, function()
        if not SmartLFG.DB.Get("enabled") or not SmartLFG.DB.Get("autoAccept") then return end
        local btn = LFDRoleCheckPopupAcceptButton
        if btn and btn:IsVisible() then AcceptViaSecureClick(btn) end
    end)
end

-- Install the OnShow hook once, lazily (the popup may live in a lazy-loaded
-- Blizzard addon). Returns true only on the call that actually installs it.
local onShowHooked = false
local function EnsureOnShowHook()
    if onShowHooked then return false end
    local btn = LFDRoleCheckPopupAcceptButton
    if not (btn and btn.HookScript) then return false end
    onShowHooked = true
    btn:HookScript("OnShow", function()
        if not SmartLFG.DB.Get("enabled") or not SmartLFG.DB.Get("autoAccept") then return end
        AcceptCurrentRoleCheck()
    end)
    return true
end

function RM.AutoAcceptRoleCheck()
    if not SmartLFG.DB.Get("autoAccept") then return end
    -- Once the OnShow hook exists it handles every popup; the event only needs to
    -- install it. The install is too late for the popup that just appeared, so on
    -- that first install we accept the current one directly (single attempt).
    if EnsureOnShowHook() then
        AcceptCurrentRoleCheck()
    end
end
