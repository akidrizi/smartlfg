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

-- The roles currently set in the native LFG role state, as a set keyed by token.
-- Used only to import a player's pre-existing setup on first run.
function SmartLFG.GetNativeRoles()
    local _, tank, healer, dps = GetLFGRoles()
    local out = {}
    if tank   then out.TANK    = true end
    if healer then out.HEALER  = true end
    if dps    then out.DAMAGER = true end
    return out
end

-- The player's *explicitly selected* sign-up roles, stored in our DB
-- (`selectedRoles`) and constrained to the roles the class can perform. This is
-- the source of truth for the options dialog; the native LFG state is only
-- written at sign-up time (see ResolveSignUpRoles / ApplyResolvedRoles). An
-- empty result means "nothing selected" — the caller then falls back.
function SmartLFG.GetSelectedRoles()
    local stored = SmartLFG.DB.Get("selectedRoles") or {}
    local avail  = SmartLFG.GetAvailableRoles()
    local out = {}
    for _, role in ipairs(SmartLFG.ROLES) do
        if stored[role] and avail[role] then out[role] = true end
    end
    return out
end

-- The role token of the player's *current* specialization (TANK/HEALER/DAMAGER),
-- or nil if it can't be resolved. Used as a fallback when no role is selected.
function SmartLFG.GetCurrentSpecRole()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    return select(5, GetSpecializationInfo(specIndex))
end

-- Localized display name of the player's current specialization (e.g. "Frost"),
-- or nil if it can't be resolved. Shown in the roles-section fallback tooltip.
function SmartLFG.GetCurrentSpecName()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    return select(2, GetSpecializationInfo(specIndex))
end

-- Toggle one class-valid role on/off in the explicit DB selection, then mirror
-- the selection into the native LFG role state so Blizzard's own UI matches
-- (an empty selection clears the native roles). No secure-frame writes, no taint.
function SmartLFG.ToggleRole(role)
    if not SmartLFG.GetAvailableRoles()[role] then return end
    local stored = SmartLFG.DB.Get("selectedRoles") or {}
    local new = { TANK = stored.TANK, HEALER = stored.HEALER, DAMAGER = stored.DAMAGER }
    new[role] = (not new[role]) or nil
    SmartLFG.DB.Set("selectedRoles", new)

    local leader = GetLFGRoles()
    SetLFGRoles(leader, new.TANK or false, new.HEALER or false, new.DAMAGER or false)
end

-- Resolve the roles to actually sign up with: the explicit selection if any is
-- set, otherwise a fallback to the current spec's role. Returns a set keyed by
-- token, or empty if unresolvable.
function SmartLFG.ResolveSignUpRoles()
    local selected = SmartLFG.GetSelectedRoles()
    if next(selected) then return selected end

    local role  = SmartLFG.GetCurrentSpecRole()
    local avail = SmartLFG.GetAvailableRoles()
    if role and avail[role] then return { [role] = true } end
    return {}
end

-- Write the resolved sign-up roles into the native LFG state (which the secure
-- Premade sign-up dialog inherits). Returns true if a role was applied, false if
-- nothing could be resolved (the caller should then warn ROLE_REQUIRED).
function SmartLFG.ApplyResolvedRoles()
    local roles  = SmartLFG.ResolveSignUpRoles()
    local leader = GetLFGRoles()
    SetLFGRoles(leader, roles.TANK or false, roles.HEALER or false, roles.DAMAGER or false)
    return next(roles) ~= nil
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
