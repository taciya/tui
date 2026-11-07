TUI 2.0.0 — World of Warcraft: Infinite

Target baseline
- Interface: 16001
- Client build checked: 1.60.1.70790 (2026-11-07)
- Lua runtime: 5.1.4

Installation
1. Close the game.
2. Copy the TUI folder into the Infinite client's Interface\AddOns folder.
   For the standard Windows installation this is under:
   World of Warcraft\_forever_\Interface\AddOns\TUI
3. Start the game and enable TUI in the AddOns list.

Removed by request
- Recipients.lua / recipient-list UI and RecipientsDB
- TUI_Raid.lua / raid-frame customization module and BobUI dependency
- All TOC load references to those files

Retained features
- Main TUI commands and chat utilities
- Secure binding definitions
- ItemRack equipment-set data and commands
- Player-link context actions
- Sequential mail-attachment looting
- Existing localization entry point

Refactoring in this build
- Added Core bootstrap, compatibility helpers, persistent-variable defaults,
  and a lightweight event bus for future feature modules.
- Updated TOC Interface and load order.
- Removed the old global ChatFrame_OnEvent replacement in favor of
  ChatFrame_AddMessageEventFilter when available.
- Fixed several slash-command handlers that were assigned before their
  functions existed.
- Prevented SavedVariables tables from being reset on every reload.
- Mail attachment button is created lazily after the mailbox UI is loaded.
- Recipient-only localization was removed; attachment strings now live in
  TUI_LOCALE.

Important compatibility notes
- This is a source-level compatibility pass, not an in-client certification.
  The game client is not available in this environment, so UI layout, mail
  events, secure bindings and equipment operations still require in-game QA.
- Equipment swaps and other protected actions may be blocked during combat.
  The addon does not attempt to bypass the client's protected-action rules.
- Some legacy spellbook, chat and item APIs in the retained original modules
  may need additional per-build adaptation if the client has removed them.
- Keep a backup of WTF\Account\...\SavedVariables\TUI.lua before first launch.


TUI 2.2.0 - Inspector module
----------------------------
Commands:
  /tuiinspect        Open/close Inspector
  /tuiinspect spell 12345   Inspect a spell by ID or name
  /tuiinspect item 12345    Inspect an item by ID or name
  /tuiinspect state         Inspect live player state
  /tuiinspect api           List supported read-only API probes
  /tuiinspect macro         Show macro conditional reference
  /tiq                    Alias for /tuiinspect

The Inspector uses guarded API calls and does not evaluate arbitrary Lua code.
Macro conditional support and stance/form numbering must be verified against
the current WoW: Infinite client. API-observed values are not guaranteed to
be identical to secure macro-condition evaluation.
