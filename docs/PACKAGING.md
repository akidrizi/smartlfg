# SmartLFG — Packaging & Release Guide

How to prepare the source tree, run the CI pipeline, and publish a release.

---

## 1. Project layout

```
SmartLFG/                        ← repository root (= addon folder name)
├── SmartLFG.toc                 ← WoW Table of Contents
├── .editorconfig
├── .gitignore
├── .luacheckrc                  ← luacheck configuration
├── package.sh                   ← local build helper
├── README.md
├── LICENSE.md
├── .github/
│   └── workflows/
│       ├── ci.yml               ← lint on push / PR
│       └── release.yml          ← package + GitHub Release on semver tag
├── docs/
│   └── PACKAGING.md             ← this file
└── src/
    ├── Constants.lua
    ├── Database.lua
    ├── Util.lua
    ├── RoleManager.lua
    ├── FrameHook.lua
    ├── Commands.lua
    └── Core.lua
```

---

## 2. GitHub Actions workflows

### `ci.yml` — Continuous Integration

Runs on every push to `main` / `develop` and on all pull requests.

| Step | What it checks |
|---|---|
| **luacheck** | Lints all `src/*.lua` against Lua 5.1 + known WoW API globals |
| **TOC version** | `## Version:` is valid semver (`MAJOR.MINOR.PATCH` or with pre-release) |
| **TOC interface** | `## Interface:` is a 6-digit WoW build number (e.g. `120001`) |

### `release.yml` — Release Pipeline

Triggers only on tags that match the semver regex (see below).

```
Job 1: validate   →   regex check + version consistency with .toc
Job 2: package    →   builds SmartLFG-<version>.zip
Job 3: release    →   creates GitHub Release, attaches zip, auto-labels pre-releases
```

---

## 3. Semver tag format & regex

### Allowed tag formats

| Tag | Type | Example use |
|---|---|---|
| `v1.2.3` | Stable release | Production-ready version |
| `v1.2.3-alpha.1` | Pre-release | Early development build |
| `v1.2.3-beta.2` | Pre-release | Feature-complete, testing |
| `v1.2.3-rc.1` | Pre-release | Release candidate |

Tags that **do not** match (and will be rejected):

```
1.2.3          ← missing "v" prefix
v1.2           ← missing PATCH component
v01.2.3        ← leading zero in MAJOR
v1.2.3-dev.1   ← "dev" is not an allowed pre-release identifier
v1.2.3-beta    ← missing numeric index after identifier
v1.2.3.4       ← four components not allowed
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
git commit -m "chore: release v1.2.0"
git push
```

Wait for the CI workflow (`ci.yml`) to pass on `main` before tagging.

### Step 3 — Tag

```bash
# Stable release
git tag v1.2.0

# Pre-release
git tag v1.2.0-beta.1
```

### Step 4 — Push the tag

```bash
git push origin v1.2.0
```

The `release.yml` workflow starts automatically. It will:

1. Validate `v1.2.0` against the semver regex ✅
2. Confirm that `## Version: 1.2.0` in `SmartLFG.toc` matches ✅
3. Build `dist/SmartLFG-1.2.0.zip` ✅
4. Create a GitHub Release named **SmartLFG v1.2.0** with:
   - Auto-generated changelog (commits since the last tag)
   - `SmartLFG-1.2.0.zip` attached as a downloadable asset
   - Pre-release flag set automatically for `alpha`/`beta`/`rc` tags ✅

### Step 5 — Verify

Go to **Releases** on your GitHub repository page. The new release should be visible with the zip attached. Download it and verify the folder structure inside:

```
SmartLFG-1.2.0.zip
└── SmartLFG/
    ├── SmartLFG.toc
    └── src/
```

---

## 5. Local build (without CI)

```bash
chmod +x package.sh
./package.sh
# → dist/SmartLFG-<version>.zip
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

---

## 8. Required repository secret

The release workflow uses `secrets.GITHUB_TOKEN`, which GitHub **provides automatically** — no manual secret setup is required.
