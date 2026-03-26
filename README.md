# SmartLFG — Quick Apply LFG Sign-Ups & Auto-Accept Friend Queues

**SmartLFG** is a lightweight World of Warcraft addon that speeds up dungeon and group sign-ups. Double-click any listing in LFG -> Premade Groups browser to instantly apply or let the addon auto-accept role checks when a friend queues the group.

> **Compatible with WoW Midnight (12.x) · No dependencies · Zero background activity**

---

## ✨ Features

### ⚡ Double-Click Sign-Up
Double-click any entry in the **Dungeon Finder** or **Premade Groups** browser (dungeons, raids, mythics, delves, quests — anything) and SmartLFG signs you up immediately using whatever role you already have ticked in the native WoW panel.

### 👥 Friend Group Auto-Accept
When a **friend queues your group** for a dungeon, SmartLFG automatically accepts the role-check popup on your behalf. Works with both BNet friends and in-game friends.

### 🔒 Non-Invasive by Design
SmartLFG reads your role directly from the **native WoW Dungeon Finder checkboxes** — it never stores or overrides your role preference. If you haven't ticked any role, the addon prints a reminder and does nothing. Disable it at any time with `/slfg disable`.

---

## 🎮 How It Works

### Setting Your Role
Open the Dungeon Finder (press `I` by default) and tick the role checkboxes at the top of the panel — **Tank**, **Healer**, **DPS**, or any combination your class supports. WoW already enforces which roles each class can play, so no extra configuration is needed.

SmartLFG reads these checkboxes live every time you sign up. Change your role anytime simply by changing your selection in the panel.

### Signing Up
- **Premade Groups:** Double-click any listing → application submitted automatically.

If no role is ticked, SmartLFG prints a reminder in chat and leaves the normal WoW flow untouched.

### Friend Auto-Accept
When your group leader (who must be on your friends list) queues for a dungeon, the role-check popup that appears for all party members is automatically confirmed. You don't need to switch back to WoW just to click it.

---

## 💬 Slash Commands

| Command | What it does |
|---|---|
| `/slfg status` | Show current settings and active role |
| `/slfg enable` | Enable SmartLFG automation |
| `/slfg disable` | Disable automation (WoW behaves normally) |
| `/slfg friends` | Toggle auto-accept for friend-queued groups |
| `/slfg tooltip` | Toggle the Dungeon Finder tooltip quick sign-up hint |
| `/slfg help` | Print all commands to chat |

You can also use `/smartlfg` as an alternative prefix.

---

## ❓ Frequently Asked Questions

**Does this work with Premade Groups (raids, mythics, delves)?**
Yes. Double-click any listing in the Premade Groups browser to apply instantly. SmartLFG will also auto-confirm the application dialog that normally requires a second click.

**Does this work with all Dungeon Finder queue types?**
Yes — random dungeons, heroics, mythics, and any queue type available through the LFD panel.

**Will it auto-accept role checks from strangers?**
No. The auto-accept feature only triggers when the group leader is on your **friends list** (BNet or in-game).

**What if I haven't ticked a role in the Dungeon Finder?**
SmartLFG prints a chat message telling you to open the Dungeon Finder and tick a role, then steps aside. Nothing is broken — WoW behaves exactly as it would without the addon.

**Can I queue as multiple roles at once (e.g. Tank + Healer)?**
Yes. SmartLFG reads whatever combination of roles you have ticked. If you tick Tank and Healer, it signs you up for both.

**Can I turn it off temporarily?**
Yes: `/slfg disable`. This bypasses every hook and puts WoW back to its default behaviour until you run `/slfg enable`.

**Does it break any Blizzard ToS?**
SmartLFG only calls Blizzard-provided addon APIs. It does not inject input, modify protected frames, or bypass role checks. It is equivalent to a player clicking the buttons themselves.

---

## 🌍 Multilingual Support

SmartLFG automatically adapts all chat messages to your WoW client language. Supported locales:

| Code | Language |
|------|----------|
| `enUS` | English (default / fallback) |
| `deDE` | German |
| `frFR` | French |
| `esES` / `esMX` | Spanish |
| `ruRU` | Russian |
| `ptBR` | Portuguese (Brazil) |
| `itIT` | Italian |

All strings live in `src/Locale.lua`. To add a new locale, copy an existing table, translate the values, and add an `elseif` branch at the bottom of the file.

---

## 📋 Compatibility

| Version             | Status |
|---------------------|---|
| WoW Retail          | ✅ Supported |
| WoW Classic / Era   | ❌ Not supported (different LFG system) |

---

## 🐛 Reporting Issues

Found a bug? Please open an issue on [Github](https://github.com/akidrizi/smartlfg/issues) and include:

- Your WoW version (`/run print(GetBuildInfo())`)
- Your class and which role(s) were ticked
- What you expected vs what happened
- Any Lua error messages
- Screenshots with the WoW UI visible
