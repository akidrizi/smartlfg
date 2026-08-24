# CLAUDE.md — SmartLFG

Guidance for AI agents (and humans) working in this repository. This is the single
source of truth for how the addon is structured and how to work on it. Keep it
accurate: after changing the code, reconcile this file (see **Keeping this file in
sync** at the bottom).

---

## What SmartLFG is

A small, **native-as-possible** World of Warcraft addon that streamlines applying to
**Premade Groups** (Group Finder → Premade Groups, Blizzard's `LFGList`) and creating
Dungeons listings. Install and forget: sensible defaults, one small options dialog
reachable from `/slfg` or a minimap button.

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
5. **Enhanced Premade Groups.** An options-panel toggle (on by default) for the **Dungeons**
   "Start a Group" flow. Two behaviors, on and off together: it **trims the dungeon
   dropdown to the current Mythic+ season** ("More…" still reaches Blizzard's full list),
   and **pre-selects Mythic+ difficulty and a Competitive playstyle** (re-asserting
   Mythic+ whenever the player switches dungeon). Unticking restores Blizzard's stock
   behavior on an already-open form — no `/reload` (see `GroupCreation.Refresh`).
   Everything here is scoped to the Dungeons category: **every** entry point guards on
   `IsDungeonsForm` before acting, including the two `hooksecurefunc` hooks, which fire
   for all categories and bail immediately unless it's Dungeons.

   > **Naming note:** the UI label is "Enhanced Premade Groups", but the DB key is
   > `enhancedListing` and the locale keys are `OPTIONS_ENHANCED*` — kept stable across
   > two label rewrites rather than churning a schema migration for cosmetics.

The UI is a **standalone movable dialog** (dark backdrop, gold border, close X,
ESC-closable, drag to reposition), opened by `/slfg` or by a **native minimap button**
(left-click toggles it; right-click toggles the master Enable switch; drag the button
around the minimap ring — its angle persists per-character in `minimapAngle`; the button
hugs round, square or cornered minimaps via `GetMinimapShape()`). Layout (top → bottom): a header with a branded round icon then the
cyan name + grey version top-left, and the master **Enable** check on the version row,
top-right; a **SIGN-UP
ROLES** section (white small-caps header) with three centered circular role icons
(ring + role icon + label beneath, an additive selection highlight on the chosen role); an
**OPTIONS** section (white small-caps header) with three toggles — **Double-click
sign-up** (features 1, 2 and 4) and **Auto-accept role** (feature 3) sit inline as one
centred row, with **Enhanced Premade Groups** (feature 5) centred on its own row beneath
them; and a bottom **Tip** line reusing the tooltip-hint note string. Help text is shown
on hover (tooltips), not inline. While **Enable** is off the toggles/labels grey out and
roles desaturate (and the Tip line greys when double-click sign-up is off). The Blizzard
Settings → AddOns entry is a tiny placeholder (name, version, a clickable `/slfg`) that
just opens the dialog.

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

`Commands → Constants → Core → Database → FrameHook → GroupCreation → Locale → Minimap → Options → RoleManager → Util`

Safe because **no file calls another module's functions at load time** — all
cross-module calls happen inside function bodies, which run only after every file loads.

### Files

| File | Responsibility |
|---|---|
| `Constants.lua` | UI color codes (`SmartLFG.COLOR`), role tokens (`SmartLFG.ROLES`), native role-icon atlases (`SmartLFG.ROLE_ATLAS`, the Group Finder role badges). |
| `Locale.lua` | All user-visible strings (`SmartLFG.L`). `L_enUS` is the authoritative base; `deDE/frFR/esES/ruRU/ptBR/itIT` metatable-fallback to it (`esMX`→`esES`). |
| `Database.lua` | `SmartLFGDB` access via `DB.Get`/`DB.Set` only. Per-character. `SCHEMA_VERSION = 12`; keys are `enabled`, `quickSignUp`, `autoAccept`, `roleInitialized`, `minimapAngle`, `selectedRoles`, `enhancedListing` (+ `schemaVersion`). v12 renamed `rememberDungeonListing` → `enhancedListing`, carrying the player's on/off choice over, and dropped `dungeonListing`. |
| `Util.lua` | Stateless helpers: `Print`, `Warn`, `GetAddonVersion`, and the role model (`GetAvailableRoles`, `GetNativeRoles`, `GetSelectedRoles`, `GetCurrentSpecRole`, `GetCurrentSpecName`, `ToggleRole`, `ResolveSignUpRoles`, `ApplyResolvedRoles`, `GetRoleName`), plus `IsPlayerSoloOrLeader`. |
| `Minimap.lua` | Native, hand-rolled minimap button (no libraries; icon `media/minimap_64.png`, circular-masked). `M.Create()` builds it once; left-click calls `Options.Toggle()`, right-click flips the `enabled` DB key (mirrors `/slfg on\|off`, with chat feedback) and refreshes the tooltip, drag repositions it (angle saved in the `minimapAngle` DB key). The tooltip (`ShowTooltip`) shows the drag/open hint plus a right-click line that flips green "Enable" / red "Disable" with the current state. `UpdatePosition` clamps the button to the minimap edge using `GetMinimapShape()` + a `MINIMAP_SHAPES` quadrant table, so it follows round/square/cornered minimaps (the LibDBIcon approach, library-free). |
| `Options.lua` | The standalone options dialog (movable `BackdropTemplate` frame, dark backdrop, close X, ESC-closable). Header (branded `media/minimap_64.png` icon + name/version + Enable; the header icon is a button that opens Group Finder → Premade Groups via `PVEFrame_ToggleFrame("GroupFinderFrame", "LFGListPVEStub")`, falling back to `ToggleLFDParentFrame` — an easter egg), a SIGN-UP ROLES section (its header carries a turn-in icon — `GossipFrame\ActiveQuestIcon` — whose hover tooltip names the spec-role fallback) of three circular role buttons with labels, an OPTIONS section (its header carries a native quest icon — `GossipFrame\AvailableQuestIcon` — whose hover tooltip, `CONFLICT_INFO_*`, explains the per-option conflict triangles) with three toggles: Double-click sign-up and Auto-accept role sit inline as one centred row (each reserves a status-icon slot after its label — `OPT_ICON`/`OPT_ICON_GAP`, plus `TOGGLE_GAP` between them — so the row stays symmetric; the Double-click sign-up toggle carries a `services-icon-warning` triangle, hidden until the conflict self-check fires, whose tooltip repeats `CONFLICT_DETECTED`; the auto-accept slot is reserved for a future indicator), and Enhanced Premade Groups centred on its own row (`OPT_Y2`) beneath them — its tooltip formats `OPTIONS_ENHANCED_DESC` with the addon-cyan `OPTIONS_ENHANCED_MYTHIC`/`_COMPETITIVE` terms — and a bottom Tip line; help text is hover-tooltip only. Also builds the tiny Settings → AddOns stub that opens the dialog. `O.Register()`, `O.Open()`, `O.Toggle()`, `O.Refresh()` (which also calls `GroupCreation.Refresh()` so the toggle applies live); `CreateCheck` builds one DB-bound checkbox (label + tooltip), `CreateRoleButton` builds one ringed role icon, `CreateSectionHeader`/`WireTooltip` are layout helpers. |
| `RoleManager.lua` | Behaviors: `ApplyToGroup` (premade sign-up; resolves + applies roles first, then arms the conflict self-check), `SignUp` (LFD queue — legacy), `AutoAcceptRoleCheck` (gated by the `autoAccept` DB key), `PreselectRoleFromSpec` (first-run seeding of `selectedRoles`), the session note (`GetNote`/`SetNote`) + note mode for Shift, and the conflict self-check (`NotifyDialogShown` from the application dialog's OnShow, `HasConflict` read by Options). |
| `GroupCreation.lua` | The Dungeons "Start a Group" behaviors, all gated by one `IsEnhanced()` check (`enabled` + `enhancedListing`), re-read on every entry point so the toggle is live: `GC.OnEntryCreationShow` pre-selects Mythic+ (`activityInfo.isMythicPlusActivity`) and a Competitive playstyle, deferred one frame and retrying while the activity list is still empty; `GC.OnSelect` re-asserts Mythic+ on dungeon change; `GC.OnSetupGroupDropdown` trims the dungeon dropdown to the current M+ season; `GC.Refresh` re-applies both to an already-open form when the option changes. **Never writes the Title** — that is Blizzard's. Every undocumented-internal call goes through `SafeCall` (existence-checked + `pcall`-guarded). All activity changes funnel through `SelectActivity`, and playstyle is a direct `generalPlaystyle` field write — both to minimize trips through the protected `SetEntryTitle` (see **Taint**). |
| `FrameHook.lua` | Hooks the LFG UI: premade row double-click + tooltip + application-dialog auto-submit (all gated by the `quickSignUp` DB key), note hold-open / deferred note restore, the LFD dungeon-list double-click, and wires `LFGListFrame.EntryCreation`'s `OnShow` + its `ListGroupButton`'s `OnClick` to `GroupCreation`. |
| `Commands.lua` | `/slfg` (opens the dialog) and `/slfg on\|off`. |
| `Core.lua` | Entry point: registers events, holds the enabled-gate, calls `Options.Register()` and `Minimap.Create()`, and retries the LFG frame hooks on every `ADDON_LOADED` (never matching a Blizzard addon name — see **Never match Blizzard addon names**). |

### Events (registered in `Core.lua`)

| Event | Gate | Handler |
|---|---|---|
| `ADDON_LOADED` | always | Init DB + options dialog + minimap button (own addon only); then, on **every** `ADDON_LOADED`, retry `FrameHook.HookLFGList()` + `HookLFD()` — see **Never match Blizzard addon names** below. |
| `PLAYER_LOGIN` | always | `RoleManager.PreselectRoleFromSpec()` — first-run role seeding (spec data is ready by now). |
| `LFG_LIST_SEARCH_RESULTS_RECEIVED` | always | Re-hook recycled premade ScrollBox rows. |
| `LFG_ROLE_CHECK_SHOW` | enabled | `RoleManager.AutoAcceptRoleCheck()` (no-ops unless the `autoAccept` key is set). |

**Enabled gate:** a single `elseif not DB.Get("enabled") then return` in `Core.lua` sits
between the always-on events and the feature events. Frame-script paths in
`FrameHook.lua` (double-click handlers, dialog `OnShow`, tooltip eligibility) keep their
own `DB.Get("enabled")` check because they are not event-gated.

**Never match Blizzard addon names.** `Core.lua` used to install the LFG hooks from
`ADDON_LOADED` only when `loaded == "Blizzard_LFGList"` / `"Blizzard_LookingForGroup"`.
Blizzard renamed the Premade Groups UI to **`Blizzard_GroupFinder`**, so that branch stopped
firing — and it failed *silently*: no error, hooks simply never installed. Premade sign-up
kept working purely by luck, because `LFG_LIST_SEARCH_RESULTS_RECEIVED` also calls
`HookLFGList()` and searching fires it; the group-*creation* path never searches, so
`GroupCreation` never ran at all. `Core.lua` now retries both hooks on **every**
`ADDON_LOADED` (gated on a local `ready` flag so the DB is initialized first). Both are
idempotent and no-op until their frames exist. **Do not reintroduce a hardcoded Blizzard
addon name** — hook on frame existence, not on who supplied the frame.

### Sign-up flow (Premade)

Double-click → `OnDoubleClickPremade` → `RoleManager.ApplyToGroup(shift)` → clicks the
search panel's Sign Up button (opens the dialog) → the dialog's `OnShow` hook either
auto-submits (plain) or holds it open for a note (Shift). **All of this is synchronous
inside the hardware-click event** so the protected `ApplyToGroup` is allowed. We never
`SetText`/`SetChecked` the secure dialog — that taints and blocks the sign-up.

**Conflict self-check.** No static incompatible-addon list — we infer a clash from *who*
drives the sign-up, anchored on the application dialog opening (`OnShow` →
`RoleManager.NotifyDialogShown`). `ApplyToGroup` records `lastInitiated`/`sawOurDialog`.
Two failure shapes both call `FlagConflict` (once per session): **(A)** the dialog opens
but we didn't initiate it (no `ApplyToGroup` within `INITIATE_WINDOW`) *and* it auto-closes
within `SETTLE_DELAY` — another addon's one-click sign-up (e.g. Premade Groups Filter) drove
and submitted it, bypassing us; the auto-close requirement avoids flagging a human using
Blizzard's own Sign Up button (dialog stays open). **(B)** we *did* initiate but no dialog
ever appears (`sawOurDialog` stays false) — our click was replaced/blocked. `FlagConflict`
emits a one-time `Warn(CONFLICT_DETECTED)` and calls `Options.Refresh()`;
`RoleManager.HasConflict()` exposes the latched flag so `Options.lua` shows a warning
triangle beside the OPTIONS header. The flag is a Lua session local, so the chat warning
and the icon both reset on `/reload` or relog.

### Group creation flow (Dungeons)

Blizzard's own `LFGListEntryCreation_Show` resets the "Start a Group" form
(`LFGListEntryCreation_Clear`) almost every time it's shown for Dungeons — the category
is `preferCurrentArea`, so it defaults to whatever dungeon the player is standing near
instead of keeping the previous listing. GroupCreation doesn't fight *why* Blizzard
resets it; it just reasserts on top, on **every** `EntryCreation` `OnShow` for the
Dungeons category (`GROUP_FINDER_CATEGORY_ID_DUNGEONS`), which covers delisting, a fresh
"Start a Group", or any other cause uniformly. Everything below is gated by a single
`IsEnhanced()` helper (`enabled` + `enhancedListing`), re-read on every entry point rather
than cached — that is what makes the toggle take effect without a `/reload`.

1. **Difficulty + playstyle pre-select** (`GC.OnEntryCreationShow` → `ApplyToEntryCreation`):
   locates whichever available activity has `isMythicPlusActivity == true` for the
   currently-selected dungeon and selects it via `SelectActivity`, then sets the playstyle
   to Competitive (`Enum.LFGEntryGeneralPlaystyle.FunSerious`) with a direct
   `generalPlaystyle` field write. Runs inside `C_Timer.After(0, …)`, deferred one frame off
   `OnShow` — the same "defer past Blizzard's own reset" pattern `RestoreNote` uses for the
   note box — so it applies *after* `LFGListEntryCreation_Show`'s `Clear()`/`Select()` has
   fully settled.

**The Title cannot be written by an addon. At all.** `EntryCreation.Name` looks like an
ordinary EditBox but is a **protected** one (note its `editBoxEnabled`, `LockButton`, and
`tabCategory="ENTRY_CREATION"` fields) — same class as the sign-up dialog's note box.
`Name:SetText()` from addon code fails with *"Call is illegal when disabled by security
settings"* + `Lua Taint: SmartLFG`, and the only other route,
`C_LFGList.SetEntryTitle`, is protected too (it is what raises the
`ADDON_ACTION_BLOCKED` documented under **Taint**). Being inside a hardware event doesn't
help — the block is taint, not hardware.

Two title features were built and then removed once this was understood: restoring a
remembered title, and a mouse-wheel keystone-level prefix ("+5 Your Title"). **Both were
deleted, not disabled. Do not attempt either again** — the failure mode is an error spam
loop, not a silent no-op. A prior revision of this file wrongly asserted `Name:SetText()`
was safe because the widget has no `OnTextChanged` route into a protected API; the write
itself is what's blocked. The title is entirely Blizzard's: on Mythic+ it derives from the
player's current keystone.

2. **Mythic+ season filter + dungeon-change enforcement.**
   Two `hooksecurefunc` hooks on Blizzard globals, installed once in `FH.HookLFGList`
   (existence-checked first — `hooksecurefunc` errors on a name that isn't a function):
   - `LFGListEntryCreation_Select` → `GC.OnSelect`. Blizzard passes a **groupID** when the
     *dungeon* changes and an **activityID** when the *difficulty* changes; we react only
     to the former, so picking Heroic by hand from the difficulty dropdown is still
     respected. Re-entrancy is blocked by the `enforcing` flag, since our fix-up calls
     `LFGListEntryCreation_Select` again.
   - `LFGListEntryCreation_SetupGroupDropdown` → `GC.OnSetupGroupDropdown`, which replaces
     Blizzard's just-installed menu with `BuildFilteredGroupMenu` — a faithful
     reimplementation of Blizzard's generator (same Recommended-narrowing pass, same
     order-index merge of groups and standalone activities, same radio callbacks) with one
     addition: dungeons with no Mythic+ activity are dropped. **A dungeon counts as
     "current season" exactly when `C_LFGList` still offers a Mythic+ activity for it** —
     the same lookup that drives the difficulty baseline, so it can never drift out of
     sync the way a hardcoded season roster would. Two deliberate safety valves: if the
     filter would empty the list it falls through to the unfiltered one, and if our
     generator ever raises, `filterFailed` latches and the dropdown is handed back to
     Blizzard permanently. The **"More…" button is reproduced verbatim** (same
     `LFGListEntryCreationActivityFinder_Show` arguments) and is force-enabled whenever we
     hid anything, so nothing we filter out is ever unreachable.

**Toggling the option is live — no `/reload`.** Every entry point re-reads `IsEnhanced()`,
so unticking the box stops the pre-select and dungeon-change enforcement from the next call
onward for free. The dropdown is the exception and needs a push: our filtered menu stays
installed on the widget until something re-runs the setup. `O.Refresh()` therefore calls
`GC.Refresh()`, which no-ops unless the Dungeons creation form is currently open, and
otherwise re-runs Blizzard's own `LFGListEntryCreation_SetupGroupDropdown` — that installs
the unfiltered menu, and our hook then either replaces it (option on) or leaves it (option
off). Turning the option off never *undoes* an already-applied difficulty or playstyle; it
only stops enforcing, leaving the player free to change them.

**Repainting the playstyle dropdown.** Setting `generalPlaystyle` only changes the backing
value; the control keeps painting its default `GROUP_FINDER_PLAYSTYLE_REQUIRED` text
("Select Playstyle (required)") until the menu re-evaluates its radios' `IsSelected`
callbacks. Blizzard never hits this because picking from the menu repaints it inherently —
which is why its own code calls `GenerateMenu()` on the Group/Activity dropdowns but not on
`PlayStyleDropdown`. `ApplyToEntryCreation` calls `frame.PlayStyleDropdown:GenerateMenu()`
last so the control visibly reads "Competitive".

**Retry, don't give up.** `OnShow` can land before Blizzard has populated the available
activities for the preselected dungeon, so a single deferred pass would find no Mythic+
activity and silently do nothing. When `FindActivity` comes back empty,
`ApplyToEntryCreation` reschedules itself (0.1s × 10, self-terminating — the same shape as
`RoleManager`'s role-check poll) instead of bailing.

**Taint — this form is not taint-free.** An earlier version of this file claimed it was;
that was wrong and produced live `ADDON_ACTION_BLOCKED` reports. The widgets themselves are
ordinary (Blizzard's own `Clear()` writes them identically, and `frame.Name` has no
`OnTextChanged` reaching a protected API), **but `LFGListEntryCreation_Select` ends in
`LFGListEntryCreation_SetTitleFromActivityInfo`, which calls the protected
`C_LFGList.SetEntryTitle` whenever the selected activity `isMythicPlusActivity`** — exactly
what this module selects. Driving that from addon code is blocked: the M+ selection itself
still applies, but Blizzard's keystone auto-title is skipped *for that call* (the player's
own clicks title normally). Consequences for anyone editing this file:

- **Funnel every activity change through `SelectActivity`.** It skips the call when the
  activity is already selected, which is the only lever we have on how often the block fires.
- **Never call `LFGListEntryCreation_OnPlayStyleSelectedInternal`.** It reaches the same
  protected path via `DoesEntryTitleMatchPrebuiltTitle`, for no benefit — `SetPlaystyle`
  writes the `generalPlaystyle` field directly instead, exactly as Blizzard's `Clear()` does.
- Do not "fix" the block by reaching for the protected call another way. It cannot be
  laundered the way `RoleManager`'s `/click` trick launders the role-check accept.

Every write into Blizzard's undocumented internals still goes through `SafeCall`
(existence-checked *and* `pcall`-guarded), so a naming or signature mismatch on some client
build degrades that one effect silently instead of aborting the rest of
`ApplyToEntryCreation`. See **Known limitations**.

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
| Build release zip | `bash package.sh` → `dist/<version>.zip` |
| Deploy to the live client | `bash package.sh --deploy` (Git Bash). Builds the same staging tree as the zip, then copies it into the WoW AddOns folder. Destination resolves first match of: `--dest <addons-dir>`, `$WOW_ADDONS_DIR`, then `DEFAULT_ADDONS_DIR` in the script. Uses `rsync` if present, else a `tar` fallback. |
| Release | Push a **bare semver** tag matching `## Version:` in the `.toc` (e.g. `2.0.0`, no `v` prefix); `release.yml` calls `package.sh` and creates the GitHub Release. |

- `package.sh` is the **single source of truth** for what ships: it builds the
  staging tree once from its `EXCLUDES` list, then either zips it (default) or
  copies it to the live client (`--deploy`), so the two are byte-identical.
- The shipped runtime is the `.toc` + `src/` + `media/` + the repo docs
  (`README.md`, `CHANGELOG.md`, `LICENSE.md`). `media/icon.jpg` is the in-game
  AddOns-list icon (referenced by `## IconTexture:`) and `media/minimap_64.png`
  is the minimap button icon; both must stay a format the client renders.
- **Two exclude lists must stay in sync:** `package.sh` (EXCLUDES) and
  `pkgmeta.yaml` (ignore — CurseForge/Wago). They drop VCS/CI/IDE metadata,
  `docs/`, `dist/`, tooling, `CLAUDE.md`, and dotfiles.
- `media/` ships wholesale and contains only what's actually referenced: `icon.jpg`
  (AddOns-list icon) and `minimap_64.png` (minimap button). Unused dev assets get
  deleted, not excluded — keep it that way.

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
- **Group creation (Dungeons) hooks undocumented Blizzard internals.** Unlike the rest of
  the addon, `GroupCreation.lua` touches `LFGListFrame.EntryCreation` fields/functions
  (`selectedGroup`, `selectedActivity`, `generalPlaystyle`, `Name`, `ListGroupButton`,
  `LFGListEntryCreation_Select`, `LFGListEntryCreation_SetupGroupDropdown`,
  `GroupDropdown`/`PlayStyleDropdown`, `MAX_LFG_LIST_GROUP_DROPDOWN_ENTRIES`,
  `isMythicPlusActivity`, `Enum.LFGEntryGeneralPlaystyle.FunSerious` for "Competitive", etc.)
  that aren't part of the stable `C_LFGList` public API and have thin in-game test coverage —
  sourced from Blizzard's actual shipped Lua (community mirror). The `FunSerious` →
  "Competitive" mapping (4 playstyle tiers: Learning/FunRelaxed/FunSerious/Expert, in that
  order) was confirmed against a live client's dropdown labels — Learning, Relaxed,
  Competitive, Carry Offered — matching by position. Every access goes through `SafeCall`
  (existence-checked *and* `pcall`-guarded) so a Blizzard patch that
  renames/removes a field degrades to a silent no-op (the feature stops applying) rather
  than an error. **Status: verify in-game per client; expect field-name/enum touch-ups
  after a Blizzard UI update.**
- **Selecting Mythic+ trips a protected call, by design.** `LFGListEntryCreation_Select` →
  `SetTitleFromActivityInfo` → protected `C_LFGList.SetEntryTitle` fires precisely because
  the activity is Mythic+, so an occasional `ADDON_ACTION_BLOCKED` for `SetEntryTitle()` is
  expected whenever SmartLFG (rather than the player) selects the difficulty. The M+
  selection still lands; only Blizzard's keystone auto-title is skipped on that call. The
  mitigation is to keep those calls minimal (`SelectActivity`, `SetPlaystyle`) — see
  **Taint** above. **Status: reduced, not eliminated; do not attempt to force the protected
  call through.**
- **The Mythic+ season filter is confirmed only by eye.** "Current season" is inferred as
  "the client still offers a Mythic+ activity for this dungeon". That proxy was verified on
  a live client by observing that the dropdown lists exactly the season's dungeons, but
  never against a machine-readable roster (there isn't one outside the game). If a future
  season shows the wrong dungeons, the fallback is a maintained season list — which would
  then need updating every season.

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
