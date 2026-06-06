# CLAUDE.md — SmartLFG

Guidance for AI agents (and humans) working in this repository. This is the single
source of truth for how the addon is structured and how to work on it. Keep it
accurate: after changing the code, reconcile this file (see **Keeping this file in
sync** at the bottom).

---

## What SmartLFG is

A small, **native-as-possible** World of Warcraft addon that streamlines applying to
**Premade Groups** (Group Finder → Premade Groups, Blizzard's `LFGList`). Install and
forget: sensible defaults, one small options dialog reachable from `/slfg` or a minimap
button.

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

The UI is a **standalone movable dialog** (dark backdrop, gold border, close X,
ESC-closable, drag to reposition), opened by `/slfg` or by a **native minimap button**
(left-click toggles it; drag the button around the minimap ring — its angle persists
per-character in `minimapAngle`; the button hugs round, square or cornered minimaps via
`GetMinimapShape()`). Layout (top → bottom): a header with a branded round icon then the
cyan name + grey version top-left, and the master **Enable** check on the version row,
top-right; a **SIGN-UP
ROLES** section (white small-caps header) with three centered circular role icons
(ring + role icon + label beneath, an additive selection highlight on the chosen role); an
**OPTIONS** section (white small-caps header) with two columns of toggles, **Double-click
sign-up** (features 1, 2 and 4) and **Auto-accept role** (feature 3); and a bottom
**Tip** line reusing the tooltip-hint note string. Help text is shown on hover (tooltips),
not inline. While **Enable** is off the toggles/labels grey out and roles desaturate (and
the Tip line greys when double-click sign-up is off). The Blizzard Settings → AddOns entry
is a tiny placeholder (name, version, a clickable `/slfg`) that just opens the dialog.

### Commands

| Command            | Behavior                                                          |
|--------------------|------------------------------------------------------------------|
| `/slfg`            | Opens the options dialog (all help/config lives there).          |
| `/slfg on` / `off` | Master switch for all functionality; mirrors the dialog checkbox.|

`/smartlfg` is an alias. There is no other text command — the dialog is the UI.

### Role model — explicit selection with a dynamic fallback

Sign-up roles are an **explicit per-character selection** stored in the DB
(`selectedRoles`, a set of role tokens), **constrained to the roles the player's class
can perform** (derived from its specializations). The options dialog is a
**multi-select** front-end to that store. At sign-up, `Util.ResolveSignUpRoles` decides
what to apply:

- **Any role selected → use exactly that selection** (it always wins).
- **Nothing selected → fall back to the current spec's role** (`GetCurrentSpecRole`).

`Util.ApplyResolvedRoles` writes the resolved set into the **native LFG roles**
(`SetLFGRoles()`) immediately before the sign-up; the secure Premade dialog inherits them
natively — SmartLFG never writes the secure dialog. `ToggleRole` also mirrors the current
selection into the native state so Blizzard's own UI matches (an empty selection clears
it). Because the selection lives in our DB (not the native state), "nothing selected"
stays a real, persistent state, so the fallback **re-evaluates on every sign-up**.

**First-run pre-selection:** the first time SmartLFG sees a character (per-character
`roleInitialized` DB flag, seeded on `PLAYER_LOGIN`), `RoleManager.PreselectRoleFromSpec`
populates `selectedRoles` — importing any pre-existing native LFG roles, else the current
spec's role — so sign-up works out of the box. It runs once, so manual choices are
respected thereafter. If the resolved set is ever empty (e.g. solo with no resolvable
spec role), sign-up warns `ROLE_REQUIRED`.

---

## Architecture

Shared table `SmartLFG` is passed to every file via the `...` vararg (`local _, SmartLFG
= ...`, or `local addonName, SmartLFG = ...` where the name is needed). It is the same
object in every file. `SavedVariablesPerCharacter: SmartLFGDB`.

### Load order (alphabetical within `src\`, declared in the `.toc`)

`Commands → Constants → Core → Database → FrameHook → Locale → Minimap → Options → RoleManager → Util`

Safe because **no file calls another module's functions at load time** — all
cross-module calls happen inside function bodies, which run only after every file loads.

### Files

| File | Responsibility |
|---|---|
| `Constants.lua` | UI color codes (`SmartLFG.COLOR`), role tokens (`SmartLFG.ROLES`), native role-icon atlases (`SmartLFG.ROLE_ATLAS`, the Group Finder role badges). |
| `Locale.lua` | All user-visible strings (`SmartLFG.L`). `L_enUS` is the authoritative base; `deDE/frFR/esES/ruRU/ptBR/itIT` metatable-fallback to it (`esMX`→`esES`). |
| `Database.lua` | `SmartLFGDB` access via `DB.Get`/`DB.Set` only. Per-character. `SCHEMA_VERSION = 9`; keys are `enabled`, `quickSignUp`, `autoAccept`, `roleInitialized`, `minimapAngle`, `selectedRoles` (+ `schemaVersion`). |
| `Util.lua` | Stateless helpers: `Print`, `Warn`, `GetAddonVersion`, and the role model (`GetAvailableRoles`, `GetNativeRoles`, `GetSelectedRoles`, `GetCurrentSpecRole`, `GetCurrentSpecName`, `ToggleRole`, `ResolveSignUpRoles`, `ApplyResolvedRoles`, `GetRoleName`), plus `IsPlayerSoloOrLeader`. |
| `Minimap.lua` | Native, hand-rolled minimap button (no libraries; icon `media/minimap_64.png`, circular-masked). `M.Create()` builds it once; left-click calls `Options.Toggle()`, drag repositions it (angle saved in the `minimapAngle` DB key). `UpdatePosition` clamps the button to the minimap edge using `GetMinimapShape()` + a `MINIMAP_SHAPES` quadrant table, so it follows round/square/cornered minimaps (the LibDBIcon approach, library-free). |
| `Options.lua` | The standalone options dialog (movable `BackdropTemplate` frame, dark backdrop, close X, ESC-closable). Header (branded `media/minimap_64.png` icon + name/version + Enable; the header icon is a button that toggles the Group Finder via `ToggleLFDParentFrame` — an easter egg), a SIGN-UP ROLES section (its header carries a turn-in icon — `GossipFrame\ActiveQuestIcon` — whose hover tooltip names the spec-role fallback) of three circular role buttons with labels, an OPTIONS section of two-column toggles, and a bottom Tip line; help text is hover-tooltip only. Also builds the tiny Settings → AddOns stub that opens the dialog. `O.Register()`, `O.Open()`, `O.Toggle()`, `O.Refresh()`; `CreateCheck` builds one DB-bound checkbox (label + tooltip), `CreateRoleButton` builds one ringed role icon, `CreateSectionHeader`/`WireTooltip` are layout helpers. |
| `RoleManager.lua` | Behaviors: `ApplyToGroup` (premade sign-up; resolves + applies roles first), `SignUp` (LFD queue — legacy), `AutoAcceptRoleCheck` (gated by the `autoAccept` DB key), `PreselectRoleFromSpec` (first-run seeding of `selectedRoles`), and the session note (`GetNote`/`SetNote`) + note mode for Shift. |
| `FrameHook.lua` | Hooks the LFG UI: premade row double-click + tooltip + application-dialog auto-submit (all gated by the `quickSignUp` DB key), note hold-open / deferred note restore, and the LFD dungeon-list double-click. |
| `Commands.lua` | `/slfg` (opens the dialog) and `/slfg on\|off`. |
| `Core.lua` | Entry point: registers events, holds the enabled-gate, calls `Options.Register()` and `Minimap.Create()`. |

### Events (registered in `Core.lua`)

| Event | Gate | Handler |
|---|---|---|
| `ADDON_LOADED` | always | Init DB + options dialog + minimap button; hook `Blizzard_LFGList` and `Blizzard_LookingForGroup` when they lazy-load. |
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
- **Roles:** the explicit selection lives in the DB (`selectedRoles`); native LFG roles
  are written via `SetLFGRoles()` only at sign-up (resolved by `ResolveSignUpRoles`) and
  on `ToggleRole`, constrained to `GetAvailableRoles()`. Role tokens are
  `"TANK" | "HEALER" | "DAMAGER"`.
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
| Deploy to the live client | `bash deploy.sh` (Git Bash). Stages to a temp dir then swaps in; uses `rsync` if present, else a `tar` fallback. Copies only runtime files (`.toc`, `src/`, `media/icon.jpg`, `media/minimap_64.png`). |
| Build release zip | `bash package.sh` → `dist/<version>.zip` |
| Release | Push a **bare semver** tag matching `## Version:` in the `.toc` (e.g. `2.0.0`, no `v` prefix); `release.yml` calls `package.sh` and creates the GitHub Release. |

- The deployed/released runtime is the `.toc` + `src/` + `media/icon.jpg` +
  `media/minimap_64.png` only.
- **Three exclude lists must stay in sync:** `package.sh` (EXCLUDES), `pkgmeta.yaml`
  (ignore — CurseForge/Wago), and `deploy.sh` (EXCLUDES). They drop docs, dev assets,
  tooling, `CLAUDE.md`, the screenshot PNGs, and the unused minimap icon sizes/previews
  (`minimap_16.png`, `minimap_32.png`, `minimap_preview256.png`, `comparison_minimap.png`),
  but **keep `media/icon.jpg`** (the in-game AddOns-list icon, referenced by
  `## IconTexture:`) and **`media/minimap_64.png`** (the minimap button icon).
- The icons must remain a format the client renders; they ship via `media/icon.jpg` and
  `media/minimap_64.png`.

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
  it out — clicks it, and stops once it's been seen and is gone. Role checks always
  complete server-side (no stacking).
- **LFD (dungeon-finder) hooking is still present** (`FH.HookLFD`, `RoleManager.SignUp`
  via `LFGTeleport`). The product direction is Premade-only; removing LFD is pending.

---

## Keeping this file in sync

After any code change, reconcile this file so it never drifts from reality. Reconcile it
manually as part of the change (the old `sync-claude-md` skill is gone) — audit the parts
that go stale fastest:

- **Load order** vs the `.toc` file list.
- **File responsibilities** vs each `src/*.lua` module's public functions.
- **DB schema** (`SCHEMA_VERSION` + keys) vs `Database.lua`.
- **Commands** vs `Commands.lua`, and **events/gate** vs `Core.lua`.
- **Conventions, limitations, and build/deploy** vs the actual scripts and code.

**Hook:** a `Stop` hook in `.claude/settings.json` runs
`.claude/hooks/check-claude-md-sync.sh`, which blocks stopping when any `src/*.lua` or
`SmartLFG.toc` is newer than `CLAUDE.md` — your cue to reconcile and re-save this file.
The check is purely mtime-based, so re-saving `CLAUDE.md` (even if already aligned)
clears it.
