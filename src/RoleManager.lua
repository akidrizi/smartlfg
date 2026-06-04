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
function RM.AutoAcceptRoleCheck()
    -- Accept for any leader (the friends-list gate was removed in the overhaul).
    -- TODO(rework B): make this timing-proof — the popup button may not be
    -- visible in the same frame the LFG_ROLE_CHECK_SHOW event fires.
    if not (LFDRoleCheckPopupAcceptButton and LFDRoleCheckPopupAcceptButton:IsVisible()) then return end
    LFDRoleCheckPopupAcceptButton:Click()
end
