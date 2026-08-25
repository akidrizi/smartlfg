SmartLFG Changelog
==================

2.3.0
-----
- New: the /slfg dialog now follows your UI skin — window border and background included, along with the close button and the option checkboxes. EllesmereUI, ElvUI, AddOnSkins and Aurora are all recognised automatically — with none of them installed, nothing changes and the dialog keeps Blizzard's stock look.
- Skinning is strictly optional: SmartLFG never depends on those addons, and if one of them fails or is still loading, the dialog keeps its normal look rather than breaking.
- EllesmereUI users control this from EUI's own options, per addon, like any other skinned addon.
- Only one skinning addon ever styles the window, so two of them can never fight over it. Double-click the version number in `/slfg` (or run `/run SmartLFG.Skin.GetProvider()`) to see which one picked it up and which are loaded.
- Fix: browsing Premade Groups churned far more temporary memory than it should have — every scroll processed the visible group list twice. Only the memory reported against SmartLFG was affected, never your settings or sign-ups.

2.2.0
-----
- New option: Enhanced Premade Groups (on by default, toggle in /slfg) — makes starting a Dungeons premade group quicker. Applies to Dungeons only; every other Premade category is left untouched.
- The dungeon dropdown now lists only the current Mythic+ season's dungeons. "More..." still opens Blizzard's full, unfiltered list, so nothing is out of reach.
- Mythic+ difficulty and the Competitive playstyle are pre-selected for you, and Mythic+ is re-applied whenever you switch dungeon — picking another difficulty by hand still sticks.
- Turning the option off restores Blizzard's stock behavior straight away, with no /reload.
- The options panel icon now opens the Group Finder straight to Premade Groups instead of the Dungeon Finder tab.
- Fix: SmartLFG's Group Finder hooks were tied to a Blizzard addon name that has since changed, so they silently failed to install unless you browsed for groups first.
- Smaller download: dropped about 1 MB of unused artwork that was still being packaged.

2.1.0
-----
- New: conflict detection — SmartLFG now notices when another add-on hijacks the Premade sign-up, warns you once in chat, and marks the affected option with a ▲ icon in /slfg.
- New: right-click the minimap button to enable/disable the addon; the tooltip shows the action and flips with the current state.
- Updated locales for the new messages.

2.0.0
-----
- New in-game options panel: enable/disable and pick your sign-up role(s).
- New option: toggle Quick sign-up (double-click sign-up, Shift + Double-click note, and the tooltip hint) on or off.
- New option: toggle Auto-accept role checks on or off.
- Both toggles sit under the master Enable switch and grey out while the addon is disabled.
- Class-aware multi-role selection — choose any roles your class can perform.
- Double-click a Premade Groups listing to sign up; Shift + double-click to add a note.
- Auto-accept the role check when any leader queues the group.
- Tooltip hint on listings you can sign up to.
- Simplified commands: /slfg opens the options panel, /slfg on|off toggles the addon.
- Major internal overhaul and cleanup; roles now use the native Group Finder role state.

1.7.0
-----
- Removed signup & joined messages to make add-on less noisy.
- Optimize signup method.

1.6.0
-----
- Improved status command with Wow Class colors.
- In-game icon.
- Minor update in Addon panel.

1.5.0
-----
- New option: Shift + Double-click on listing for adding a note.
- Improved announcements for sign-up, tooltip hint and note addition.
- Update Locales.

1.4.3
-----
- Fix CurseForge packaging (remove invalid pkgmeta.yaml key).

1.4.2
-----
- Improve announcements for sign-up & tooltip hint.

1.4.1
-----
- Improve all announcements.

1.4.0
-----
- Announce joined group in chat.
- Announce group sign-up in chat from friend.

1.3.0
-----
- Tooltip hint in Group Finder.

1.2.0
-----
- Add in-game options panel in Options -> Addons -> SmartLFG.

1.1.0
-----
- Multilingual support.

1.0.1
-----
- `/slfg` command improvements.

1.0.0
-----
- Double-click to join sign-up in Group Finder.
- Auto-accept role-check from friends.
- `/slfg` command to controll the addon.
