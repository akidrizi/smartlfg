local _, SmartLFG = ...
local C = SmartLFG.COLOR

function SmartLFG.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(
        C.ADDON .. "[SmartLFG]" .. C.RESET .. " " .. tostring(msg)
    )
end

function SmartLFG.Warn(msg)
    SmartLFG.Print(C.WARN .. msg .. C.RESET)
end

function SmartLFG.GetAddonVersion()
    return C_AddOns.GetAddOnMetadata("SmartLFG", "Version") or "unknown"
end

function SmartLFG.HasLFDRoleSelected()
    local _, tank, healer, dps = GetLFGRoles()
    return tank or healer or dps
end

-- ── Class-based role model ──────────────────────────────────────────────────
-- The roles a class can perform, derived from its specializations. Returns a
-- set keyed by role token, e.g. { TANK = true, DAMAGER = true }.
function SmartLFG.GetAvailableRoles()
    local roles = {}
    for i = 1, (GetNumSpecializations() or 0) do
        local role = select(5, GetSpecializationInfo(i))
        if role then roles[role] = true end
    end
    if not next(roles) then roles.DAMAGER = true end  -- safety fallback
    return roles
end

-- The player's currently selected sign-up roles, read live from the native LFG
-- role state. Returned as a set keyed by role token.
function SmartLFG.GetSelectedRoles()
    local _, tank, healer, dps = GetLFGRoles()
    return { TANK = tank, HEALER = healer, DAMAGER = dps }
end

-- Toggle one role on/off in the native LFG role state. The sign-up dialog and
-- the dungeon finder both read these, so this is how the panel's role choice
-- actually takes effect — no secure-frame manipulation, no taint.
function SmartLFG.ToggleRole(role)
    local leader, tank, healer, dps = GetLFGRoles()
    local set = { TANK = tank, HEALER = healer, DAMAGER = dps }
    set[role] = not set[role]
    SetLFGRoles(leader, set.TANK, set.HEALER, set.DAMAGER)
end

-- Localized display name for a role token, in its themed color.
function SmartLFG.GetRoleName(role)
    local L = SmartLFG.L
    if role == "TANK"   then return C.TANK   .. L.ROLE_TANK   .. C.RESET end
    if role == "HEALER" then return C.HEALER .. L.ROLE_HEALER .. C.RESET end
    return C.DPS .. L.ROLE_DPS .. C.RESET
end

function SmartLFG.IsPlayerSoloOrLeader()
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then return true end
    return UnitIsGroupLeader("player")
end
