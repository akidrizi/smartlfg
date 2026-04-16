# SmartLFG — Packaging & Release Guide

How to prepare the source tree, run the CI pipeline, and publish a release.

---

## 1. Project layout

```
SmartLFG/                        ← repository root (= addon folder name)
├── .gitignore
├── .editorconfig
├── .luacheckrc                  ← luacheck configuration (single source of truth)
├── CHANGELOG.md
├── LICENSE.md
├── package.sh                   ← local build helper
├── pkgmeta.yaml                 ← Curseforge build helper
├── README.md
├── SmartLFG.toc                 ← WoW Table of Contents
├── .github/
│   └── workflows/
│       ├── ci.yml               ← lint on push / PR
│       └── release.yml          ← package + GitHub Release on semver tag
├── docs/
│   └── PACKAGING.md             ← this file
└── src/
    ├── Commands.lua
    ├── Constants.lua
    ├── Core.lua
    ├── Database.lua
    ├── FrameHook.lua
    ├── Locale.lua
    ├── RoleManager.lua
    └── Util.lua
```

---

## 2. GitHub Actions workflows

### `ci.yml` — Continuous Integration

Runs on every push to `main` / `develop` and on all pull requests.  
Does **not** run on semver tags — those are handled exclusively by `release.yml`.

| Step | What it checks |
|---|---|
| **luacheck** | Lints all `src/*.lua` using `.luacheckrc` (Lua 5.1 + WoW API globals) |
| **TOC version** | `## Version:` is valid semver (`MAJOR.MINOR.PATCH` or with pre-release suffix) |
| **TOC interface** | `## Interface:` is a 6-digit WoW build number (e.g. `120001`) |

### `release.yml` — Release Pipeline

Triggers only on tags that match the semver regex (see below).

```
Job 1: validate   →   regex check + version consistency with .toc
Job 2: package    →   builds <version>.zip
Job 3: release    →   creates GitHub Release, attaches zip, auto-labels pre-releases
```

---

## 3. Semver tag format & regex

Tags use **bare semver** — no `v` prefix.

### Allowed tag formats

| Tag | Type | Example use |
|---|---|---|
| `1.2.3` | Stable release | Production-ready version |
| `1.2.3-alpha.1` | Pre-release | Early development build |
| `1.2.3-beta.2` | Pre-release | Feature-complete, testing |
| `1.2.3-rc.1` | Pre-release | Release candidate |

Tags that **do not** match (and will be rejected):

```
v1.2.3         ← "v" prefix not allowed
1.2            ← missing PATCH component
01.2.3         ← leading zero in MAJOR
1.2.3-dev.1    ← "dev" is not an allowed pre-release identifier
1.2.3-beta     ← missing numeric index after identifier
1.2.3.4        ← four components not allowed
```

---

## 4. Publishing a release (step by step)

### Step 1 — Update the version

Edit `SmartLFG.toc` and bump `## Version:` to match the tag you plan to push:

```
## Version: 1.2.0
```

### Step 2 — Commit

```bash
git add SmartLFG.toc
git commit -m "chore: release 1.2.0"
git push
```

Wait for the CI workflow (`ci.yml`) to pass on `main` before tagging.

### Step 3 — Tag

```bash
# Stable release
git tag 1.2.0

# Pre-release
git tag 1.2.0-beta.1
```

### Step 4 — Push the tag

```bash
git push origin 1.2.0
```

The `release.yml` workflow starts automatically. It will:

1. Validate `1.2.0` against the semver regex ✅
2. Confirm that `## Version: 1.2.0` in `SmartLFG.toc` matches ✅
3. Build `dist/1.2.0.zip` ✅
4. Create a GitHub Release named **SmartLFG 1.2.0** with:
   - Auto-generated changelog (commits since the last tag)
   - `1.2.0.zip` attached as a downloadable asset
   - Pre-release flag set automatically for `alpha`/`beta`/`rc` tags ✅

### Step 5 — Verify

Go to **Releases** on your GitHub repository page. The new release should be visible with the zip attached. Download it and verify the folder structure inside:

```
1.2.0.zip
└── SmartLFG/
    ├── CHANGELOG.md
    ├── LICENSE.md
    ├── README.md
    ├── SmartLFG.toc
    └── src/
```

---

## 5. Local build (without CI)

```bash
chmod +x package.sh
./package.sh
# → dist/<version>.zip
```

---

## 6. WoW interface version reference

| Expansion | Interface value |
|---|---|
| Midnight 12.0.x | `120001` |
| The War Within 11.0.x | `110002` |
| Dragonflight 10.2.x | `100207` |
| Wrath Classic | `30403` |

Check the live version in-game:

```lua
/run print(select(3, GetBuildInfo()))
```

---

## 7. Linting locally

```bash
luarocks install luacheck   # one-time install
luacheck src/               # uses .luacheckrc automatically
```

All globals, ignore rules, and per-file overrides live in `.luacheckrc` — no extra flags needed.
