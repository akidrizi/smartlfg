# CLAUDE.md — SmartLFG

Guidance for AI agents (and humans) working in this repository. This is the single
source of truth for how the addon is structured and how to work on it. Keep it
accurate: after changing the code, reconcile this file (see **Keeping this file in
sync** at the bottom — a skill + Stop hook enforce it).

---

## What SmartLFG is

A small, **native-as-possible** World of Warcraft addon that streamlines applying to
**Premade Groups** (Group Finder → Premade Groups, Blizzard's `LFGList`). Install and
forget: sensible defaults, one small options panel.

### Features

1. **Double-click to sign up.** Double-click a Premade listing to apply instantly with
   your selected role(s).
2. **Shift + double-click to add a note.** Opens the application dialog and holds it
   open so you can type a note, then submit. SmartLFG remembers the last submitted note
   for the session and *attempts* to pre-fill it on the next Shift+double-click (see
   **Known limitations** — the note box is a secure widget, so this is best-effort).
3. **Auto-accept role check.** When the group leader signs the group up to another
   listing, SmartLFG auto-accepts the role-check popup (for any leader).
4. **Tooltip hint.** Hovering an applicable listing appends a two-line hint, in the
   addon's signature cyan, at the bottom of the tooltip.

Two independent toggles in the options panel sit under the master **Enable** switch:
**Quick sign-up** (features 1, 2 and 4 — double-click, Shift+double-click note, and the
tooltip hint) and **Auto-accept role checks** (feature 3). Each can be turned off on its
own; both are disabled (greyed) in the panel while the master switch is off.

### Commands

| Command            | Behavior                                                          |
|--------------------|------------------------------------------------------------------|
| `/slfg`            | Opens the options panel (all help/config lives there).           |
| `/slfg on` / `off` | Master switch for all functionality; mirrors the panel checkbox. |

`/smartlfg` is an alias. There is no other text command — the panel is the UI.

### Role model — native LFG roles

The sign-up role is the player's **native LFG role** (the same tank/healer/dps the
Dungeon Finder uses), read via `GetLFGRoles()` and written via `SetLFGRoles()`. The
options panel is a **multi-select** front-end to those roles, **constrained to the
roles the player's class can perform** (derived from its specializations). The Premade
sign-up dialog inherits these roles natively — SmartLFG never writes the secure dialog.
Roles are therefore per-character and persisted by Blizzard, not stored in our DB.

**First-run pre-selection:** the first time SmartLFG sees a character (per-character
`roleInitialized` DB flag, set on `PLAYER_LOGIN`), `RoleManager.PreselectRoleFromSpec`
ticks the current spec's role (`GetCurrentSpecRole` → `SetRole`) so sign-up works out of
the box. It never overrides a role the player already has selected and only runs once, so
manual choices are respected thereafter. If a role is later cleared, sign-up warns
`ROLE_REQUIRED` as normal.

---

## Architecture

Shared table `SmartLFG` is passed to every file via the `...` vararg (`local _, SmartLFG
= ...`, or `local addonName, SmartLFG = ...` where the name is needed). It is the same
object in every file. `SavedVariablesPerCharacter: SmartLFGDB`.

### Load order (alphabetical within `src\`, declared in the `.toc`)

`Commands → Constants → Core → Database → FrameHook → Locale → Options → RoleManager → Util`

Safe because **no file calls another module's functions at load time** — all
cross-module calls happen inside function bodies, which run only after every file loads.

### Files

| File | Responsibility |
|---|---|
| `Constants.lua` | UI color codes (`SmartLFG.COLOR`), role tokens (`SmartLFG.ROLES`), native role-icon atlases (`SmartLFG.ROLE_ATLAS`). |
| `Locale.lua` | All user-visible strings (`SmartLFG.L`). `L_enUS` is the authoritative base; `deDE/frFR/esES/ruRU/ptBR/itIT` metatable-fallback to it (`esMX`→`esES`). |
| `Database.lua` | `SmartLFGDB` access via `DB.Get`/`DB.Set` only. Per-character. `SCHEMA_VERSION = 7`; keys are `enabled`, `quickSignUp`, `autoAccept`, `roleInitialized` (+ `schemaVersion`). |
| `Util.lua` | Stateless helpers: `Print`, `Warn`, `GetAddonVersion`, `HasLFDRoleSelected`, the role model (`GetAvailableRoles`, `GetSelectedRoles`, `GetCurrentSpecRole`, `SetRole`, `ToggleRole`, `GetRoleName`), and `IsPlayerSoloOrLeader`. |
| `Options.lua` | The options panel: enable checkbox, Quick sign-up + Auto-accept toggles, and the multi-select native role-icon row. `O.Register()`, `O.Open()`, `O.Refresh()`; `CreateCheck` builds one DB-bound checkbox, `CreateRoleButton` builds one role icon. |
| `RoleManager.lua` | Behaviors: `ApplyToGroup` (premade sign-up), `SignUp` (LFD queue — legacy), `AutoAcceptRoleCheck` (gated by the `autoAccept` DB key), `PreselectRoleFromSpec` (first-run role seeding), and the session note (`GetNote`/`SetNote`) + note mode for Shift. |
| `FrameHook.lua` | Hooks the LFG UI: premade row double-click + tooltip + application-dialog auto-submit (all gated by the `quickSignUp` DB key), note hold-open / deferred note restore, and the LFD dungeon-list double-click. |
| `Commands.lua` | `/slfg` (opens panel) and `/slfg on\|off`. |
| `Core.lua` | Entry point: registers events, holds the enabled-gate, calls `Options.Register()`. |

### Events (registered in `Core.lua`)

| Event | Gate | Handler |
|---|---|---|
| `ADDON_LOADED` | always | Init DB + options panel; hook `Blizzard_LFGList` and `Blizzard_LookingForGroup` when they lazy-load. |
| `PLAYER_LOGIN` | always | `RoleManager.PreselectRoleFromSpec()` — first-run role seeding (spec data is ready by now). |
| `LFG_LIST_SEARCH_RESULTS_RECEIVED` | always | Re-hook recycled premade ScrollBox rows. |
| `LFG_ROLE_CHECK_SHOW` | enabled | `RoleManager.AutoAcceptRoleCheck()` (no-ops unless the `autoAccept` key is set). |

**Enabled gate:** a single `elseif not DB.Get("enabled") then return` in `Core.lua` sits
between the always-on events and the feature events. Frame-script paths in
`FrameHook.lua` (double-click handlers, dialog `OnShow`, tooltip eligibility) keep their
own `DB.Get("enabled")` check because they are not event-gated.

### Sign-up flow (Premade)

Double-click → `OnDoubleClickPremade` → `RoleManager.ApplyToGroup(shift)` → clicks the
search panel's Sign Up button (opens the dialog) → the dialog's `OnShow` hook either
auto-submits (plain) or holds it open for a note (Shift). **All of this is synchronous
inside the hardware-click event** so the protected `ApplyToGroup` is allowed. We never
`SetText`/`SetChecked` the secure dialog — that taints and blocks the sign-up.

---

## Conventions

- **Namespace:** every public symbol under `SmartLFG.*`. `local function` = file-private;
  assigned to a module table (`RM.*`, `FH.*`, `O.*`) = public.
- **DB:** only `DB.Get` / `DB.Set`. Never touch `SmartLFGDB` directly outside `Database.lua`.
- **Strings:** never hardcode user-visible text — add a key to `L_enUS`. Only add to a
  non-English table when the value differs. `HELP_*`-style description keys carry no
  color codes; the caller adds color.
- **Colors:** UI colors from `SmartLFG.COLOR`; close with `RESET`. Never hardcode hex.
- **Output:** `Print` (cyan `[SmartLFG]`), `Warn` (red). Normal operation is silent —
  chat only for `/slfg on|off` and genuine warnings.
- **Roles:** native LFG roles only — read `GetLFGRoles()`, write `SetLFGRoles()`,
  constrain to `GetAvailableRoles()`. Role tokens are `"TANK" | "HEALER" | "DAMAGER"`.
- **Security/taint:** never write secure LFG widgets (the application dialog's note box
  is a secure EditBox; its role checks live in a secure popup). Writing them taints
  SmartLFG and blocks the protected sign-up. Read-only (`GetText`, `IsEnabled`) is fine.
- **Lint:** `luacheck src/*.lua` must pass; declare any new WoW global in `.luacheckrc`,
  and remove globals that are no longer referenced.
- **No dead code:** unused functions, locals, colors, DB keys, and locale strings get
  removed, not left behind.

---

## Build / deploy / release

| Task | How |
|---|---|
| Lint | `luacheck src/*.lua` |
| Deploy to the live client | `bash deploy.sh` (Git Bash). Stages to a temp dir then swaps in; uses `rsync` if present, else a `tar` fallback. Copies only runtime files (`.toc`, `src/`, `media/icon.jpg`). |
| Build release zip | `bash package.sh` → `dist/<version>.zip` |
| Release | Push a **bare semver** tag matching `## Version:` in the `.toc` (e.g. `2.0.0`, no `v` prefix); `release.yml` calls `package.sh` and creates the GitHub Release. |

- The deployed/released runtime is the `.toc` + `src/` + `media/icon.jpg` only.
- **Three exclude lists must stay in sync:** `package.sh` (EXCLUDES), `pkgmeta.yaml`
  (ignore — CurseForge/Wago), and `deploy.sh` (EXCLUDES). They drop docs, dev assets,
  tooling, `CLAUDE.md`, and the screenshot PNGs, but **keep `media/icon.jpg`** (the
  in-game AddOns-list icon, referenced by `## IconTexture:`).
- The icon must remain a format the client renders; it ships via `media/icon.jpg`.

---

## Known limitations & pending work

- **Note persistence is best-effort.** The application dialog's note box is a secure
  EditBox. We can *read* it (to remember the last note) but a *write* is blocked inside
  the secure popup and taints the protected sign-up. We attempt a deferred,
  `pcall`-guarded restore on the Shift path only; if the client forbids it, the box
  stays empty and the player types it. Plain double-click relies on Blizzard's own note
  retention (which clears on reject/delist). **Status: imperfect; verify per client.**
- **Auto-accept role check** accepts by running the secure `/click
  LFDRoleCheckPopupAcceptButton` command through the chat editbox
  (`AcceptViaSecureClick`), not a direct `:Click()`. A direct click from the
  non-hardware `LFG_ROLE_CHECK_SHOW` path is tainted and intermittently dropped
  (tracing: ~1 in 9 missed; calling `CompleteLFGRoleCheck` directly was worse — heavy
  taint, role panel appeared). The `/click` command runs the click inside Blizzard's
  secure code path, laundering the taint. The command must go through a real
  chat editbox (`DEFAULT_CHAT_FRAME.editBox`) — a standalone `ChatFrameEditBoxTemplate`
  errors on load (no backing `chatFrame`); we only hijack it while it's hidden so a
  mid-typed message is never clobbered, falling back to a direct click otherwise. A
  self-terminating poll (every 0.1s, up to ~1s) waits for the popup to appear — handler
  order for `LFG_ROLE_CHECK_SHOW` isn't guaranteed, so we may fire before Blizzard lays
  it out — clicks it, and stops once it's been seen and is gone. After ~8–9 checks in one
  session cumulative taint can still defeat the click (resets on `/reload`); when that
  happens an `OnMouseDown` hook on the accept button (hardware-only — our `/click` never
  triggers it) bumps `acceptGen` to cancel the in-flight retry chain, so we stop spamming
  `/click` the moment the player clicks Accept themselves and a single manual press
  finishes it. Role checks always complete server-side (no stacking).
- **LFD (dungeon-finder) hooking is still present** (`FH.HookLFD`, `RoleManager.SignUp`
  via `LFGTeleport`). The product direction is Premade-only; removing LFD is pending.

---

## Keeping this file in sync

After any code change, this file must be reconciled so it never drifts from reality.

- **Skill:** `.claude/skills/sync-claude-md/SKILL.md` — run it to audit CLAUDE.md against
  the codebase (load order vs `.toc`, file responsibilities, DB schema, commands,
  conventions, limitations) and update it.
- **Hook:** a `Stop` hook in `.claude/settings.json` runs
  `.claude/hooks/check-claude-md-sync.sh`, which blocks stopping when any `src/*.lua` or
  `SmartLFG.toc` is newer than `CLAUDE.md` — your cue to run the skill and re-save this
  file. Re-saving CLAUDE.md (even if already aligned) clears the check.
