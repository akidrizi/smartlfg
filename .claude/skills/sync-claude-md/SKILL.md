---
name: sync-claude-md
description: Reconcile this repo's CLAUDE.md with the current state of the codebase after changes. Use after editing src/*.lua, SmartLFG.toc, the build/packaging scripts, or whenever the Stop hook reports CLAUDE.md is stale.
---

# Sync CLAUDE.md

Keep `CLAUDE.md` an accurate, single source of truth for the SmartLFG addon. Run this
after making changes (the `Stop` hook in `.claude/settings.json` will flag drift by
checking file mtimes).

## Steps

1. **Read** `CLAUDE.md`.

2. **Audit each section against the actual code.** Check, concretely:
   - **Load order & file list** — match the `src\` entries and their order in
     `SmartLFG.toc`. Every `src/*.lua` file must appear in the Files table with an
     accurate one-line responsibility.
   - **Commands** — match the slash handlers in `Commands.lua` (`/slfg`, `on`, `off`).
   - **Role model** — confirm roles still come from native `GetLFGRoles`/`SetLFGRoles`
     (grep `Util.lua`). If the source of roles changed, update the description.
   - **Events** — match `Core.lua`'s `RegisterEvent` calls and the enabled-gate.
   - **Database** — match `SCHEMA_VERSION` and the keys in `DEFAULTS` (`Database.lua`).
   - **Features** — double-click, Shift+note, auto-accept, tooltip: confirm each still
     exists in `FrameHook.lua` / `RoleManager.lua` and behaves as described.
   - **Build/deploy/release** — match `deploy.sh`, `package.sh`, `pkgmeta.yaml`,
     `.github/workflows/`. Verify the three exclude lists still agree and still keep
     `media/icon.jpg`.
   - **Conventions** — still true (namespace, DB access, strings, colors, lint, taint).
   - **Known limitations / pending** — update as items are fixed or added (note
     persistence, auto-accept timing, LFD removal).
   - **Version** — `## Version:` in the `.toc` (mention only if CLAUDE.md cites it).

3. **Verify supporting facts** with quick greps rather than memory, e.g.:
   - `grep -n "RegisterEvent" src/Core.lua`
   - `grep -n "SCHEMA_VERSION\|DEFAULTS" src/Database.lua`
   - `grep -rn "GetLFGRoles\|SetLFGRoles" src/`
   - Confirm `luacheck src/*.lua` is clean if code changed.

4. **Edit `CLAUDE.md`** to correct any drift. Keep it concise — fix facts, don't pad.
   Do not reintroduce removed features or files.

5. **Re-save `CLAUDE.md`** even if nothing changed (a no-op re-write/touch), so its mtime
   is at least as new as the sources and the Stop hook's staleness check clears.

## Guardrails

- CLAUDE.md describes the **current** state, not aspirational plans. Pending/limitations
  go only in the dedicated section.
- Never document a file, function, command, or DB key that no longer exists — verify
  before writing.
- If you find the code itself is wrong (not the doc), surface it to the user; don't paper
  over a bug by documenting it as intended.
