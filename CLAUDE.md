# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A **Project Zomboid Build 42** single-player mod ("Warehouse Operator"): an
extraction-shooter loop where the player takes loot missions from a 90s-style
DOS terminal in a Louisville warehouse. Pure Lua against the PZ modding API.
No multiplayer — everything is client-side.

`PROJEKTPLAN.md` is the source of truth for scope, phase roadmap, confirmed
decisions, and dev lessons learned. Read it before non-trivial work. Code
comments and planning docs are in **German**; all in-game/player-facing text
is in **English**.

## Build / run / test

There is **no build step and no test framework**. The repo *is* the mod, living
directly in `%USERPROFILE%\Zomboid\mods\WarehouseOperator`.

- **Run/test:** restart Project Zomboid — Lua changes load on startup. Verify by
  watching the console/`console.txt` for `[WHO] ...` log lines (every module
  prints a load marker and logs state changes).
- **In-game debug hotkeys** (only active when `WHO_Config.DEBUG.ENABLED`):
  - `F7` container report (dumps containers on player tile + neighbors) · `F8` teleport to gas station (Q1 testing)
  - `F9` teleport to SPAWN_POS · `F10` log current position
  - `Numpad 9` accept test quest WHO_Q001 · `Numpad 0` log quest state
- **Static analysis:** two analyzers, two configs — see "Local dev setup"
  below. VSCode + EmmyLua extension reads `.emmyrc.json` (Umbrella type stubs,
  Lua 5.1, workspace root `42/media/lua`). The Claude Code `lua-lsp` plugin runs
  LuaLS (`lua-language-server`), which ignores `.emmyrc.json` but does provide a
  headless CLI check.

## Local dev setup (per-machine, NOT committed to the repo)

Two independent Lua analyzers can run against this code, and they use
**different config files** — do not conflate them:

- **VSCode + EmmyLua extension** → reads `.emmyrc.json` (committed).
- **Claude Code `lua-lsp` plugin** → runs **LuaLS** (`lua-language-server`),
  which reads `.luarc.json` and **ignores `.emmyrc.json`**.

**Install LuaLS (required per-machine; the binary is not in the repo):**

```powershell
winget install --id LuaLS.lua-language-server
```

winget drops the binary under `…\WinGet\Packages\LuaLS.lua-language-server…\bin`
and adds that folder to the **user PATH** — but a running Claude Code keeps the
PATH it launched with, so **fully restart Claude Code** afterward or the
plugin's LSP spawn fails with `ENOENT: ... lua-language-server`. Verify with
`Get-Command lua-language-server`.

**Headless syntax check (CLI equivalent of the LSP, no editor needed):**

```powershell
lua-language-server --check <path> --checklevel Error   # Error = syntax only
```

Quirk: a **single-file** `--check` suppresses `undefined-global`; point it at a
**directory** (e.g. `42/media/lua/client`) for full workspace-mode diagnostics.

**PZ globals** (`getPlayer`, `ISPanel`, `UIFont`, `getTextManager`, …) surface
as `undefined-global` *warnings* under LuaLS — noise, not bugs. To silence them
you need the **Umbrella type stubs** present locally **and** a `.luarc.json`
pointing `workspace.library` at them with `runtime.version = "Lua 5.1"`. The
stubs are **not** in the repo, and the `.emmyrc.json` path
(`C:/Users/manta/dev/Umbrella/library`) is from a different machine. Until both
exist locally, LuaLS flags PZ globals as undefined but still parses the code
cleanly (0 syntax errors).

## Layout & module loading (the non-obvious part)

**Triple `mod.info`** — three copies, each with a distinct role. All actual code
lives under `42/media/` (the Build-42 path):
- **`mod.info` (root)** — B41-style marker; makes the mod recognizable to the PZ
  launcher / mod list.
- **`common/mod.info`** — legacy/duplicate, kept for compatibility (the `common/`
  folder is otherwise empty).
- **`42/mod.info`** — the canonical Build-42 version-folder root. **REQUIRED for
  `ScriptManager` to scan `42/media/scripts/`.** Without it the Lua loader still
  finds `42/media/lua` (so the mod *appears* to work), but item/recipe scripts are
  silently never loaded.

⚠️ **Dev-lesson — a custom item needs a script file AND `42/mod.info`.** If
`42/mod.info` is missing, `42/` isn't recognized as a B42 mod root by
`ScriptManager` (even though the Lua loader finds `42/media/lua` somehow), so the
item type never registers. Symptoms: `getScriptManager():getItem(type)` returns
nil, `container:AddItem(type)` silently returns nil with no error, and
`square:AddWorldInventoryItem(type, …)` throws `NullPointerException` at
`InventoryItemFactory` (`setAlcoholPower … item is null`). The script file can look
perfectly correct — the problem is structural.

PZ auto-loads files differently depending on folder:

- `42/media/lua/client/*.lua` — **executed automatically in alphabetical order.**
  This ordering is load-bearing: `WHO_AAA_TerminalUI.lua` carries the `AAA`
  prefix so the global `WHO_TerminalUI` class exists before
  `WHO_TerminalDebugMenu.lua` references it. Keep that in mind when adding
  client files that depend on each other.
- `42/media/lua/shared/WarehouseOperator/*.lua` — loaded on demand via `require`.

**`require` path conventions** (mixing these up causes load failures):
- shared modules: `require "WarehouseOperator/WHO_Config"`
- client modules: `require "WHO_RewardDispatcher"` (bare name, no folder)

All Lua globals, files, and quest IDs are prefixed `WHO_`. Quest IDs are
`WHO_Q` + 3-digit number. Item types use PZ's `Base.X` form.

## Architecture & data flow

The whole mod is one quest state machine driven by a few cooperating modules.

**Shared (data + logic):**
- `WHO_Config` — central constants: warehouse coords (SPAWN/TERMINAL/EXTRACTION),
  per-quest item-spawn positions, DEBUG flags + keycodes, mod version. Change
  coordinates here, nowhere else.
- `WHO_Quests` — static quest definitions only (id, tier, briefing lines,
  requirements, rewards) + `getById/getByTier/getAvailable`. No behavior.
- `WHO_QuestState` — per-player state machine persisted in
  `player:getModData().WHO`. Status flow: `IDLE → ACTIVE → COMPLETE → IDLE`.
  `acceptQuest` also spawns the quest's required items into the world via
  `WHO_ItemSpawner` at the configured spawn position. Survives save/load.
- `WHO_ItemSpawner` — generic `spawnAt/spawnBatchAt`: finds a container on the
  target square, else drops items on the floor (robust against off-by-one tile
  coords — see PROJEKTPLAN "Dev-Lessons Learned").

**Client (events + UI):**
- `WHO_Spawn` — hooks **`OnNewGame`** (deliberately *not* `OnGameStart`, so
  existing saves are untouched): teleports new operator to SPAWN_POS and grants
  the starter kit, equipping pistol (primary) + crowbar (secondary).
- `WHO_QuestCheck` — `EveryOneMinute` loop: when a quest is ACTIVE, counts items
  in the extraction crate against requirements and flips state to COMPLETE.
- `WHO_RewardDispatcher` — on extraction confirm, removes the required items from
  the crate, adds the reward items, then calls `finishQuest` (back to IDLE).
- `WHO_TerminalDebugMenu` — `OnFillWorldObjectContextMenu`: right-click within
  `INTERACTION_RADIUS` tiles of TERMINAL_POS shows "Boot Terminal" plus
  state-dependent debug options.
- `WHO_AAA_TerminalUI` — `ISPanel` subclass, the DOS-green terminal. Internal
  states `BOOTING → READY → MISSIONS_VIEW`; renders mission list / detail pane /
  active / complete views and drives accept + confirm-extraction through the
  same `WHO_QuestState` / `WHO_RewardDispatcher` backend as the debug menu.
- `WHO_HelloWorld` — load marker + `OnGameStart` position logger.

**End-to-end loop:** accept quest (terminal or debug menu) → required items spawn
in the world → player carries them to the extraction crate → `EveryOneMinute`
check marks COMPLETE → confirm extraction → dispatcher swaps required items for
rewards → state returns to IDLE.

## Working with the PZ Java API (gotchas)

- Java collections returned by the API (`square:getObjects()`,
  `container:getItems()`) are **0-indexed**: iterate `for i = 0, list:size()-1`.
- When **removing** items from a container while iterating, loop **backwards**
  (`for i = size-1, 0, -1`) so indices don't shift out from under you — see
  `WHO_RewardDispatcher.removeItemsOfType`.
- The terminal UI does manual hit-testing in `onMouseDown/onMouseMove` against
  rect helpers (`getMenuItemRect`, `getQuestListItemRect`, etc.) rather than
  child buttons. Known layout-overlap glitches are catalogued under
  "Phase 3b: Known UI Issues" in PROJEKTPLAN.md.
- Container/world coordinates must be verified **in-game** (right-click →
  Tile Report), not read off map.projectzomboid.com (off by 1-2 tiles).
- **B42 item definitions use `ItemType = base:X` (e.g. `base:key`), NOT B41's
  `Type = Normal`.** An item written with the old syntax still *registers* in
  ScriptManager (`getItem` returns it) but fails at *instantiation*: B42's
  `InventoryItemFactory` builds the object from the `ItemType` system, so without
  it `AddItem` returns nil and `AddWorldInventoryItem` throws `NullPointerException`
  at `createItemInternal`/`setAlcoholPower`. **Always template a new custom item
  from a working vanilla one** (e.g. `…/ProjectZomboid/media/scripts/generated/items/key.txt`)
  so it inherits every required property — see `42/media/scripts/WHO_Items.txt`.
- **Debugging a missing/broken custom item: `getScriptManager():getItem(fullType)`**
  distinguishes the two failure classes. Returns `nil` → the script isn't being
  loaded/parsed (structure / path / syntax). Returns non-nil but spawning still
  fails → the item *is* registered and the problem is definition completeness /
  B42 compliance (see the `ItemType` lesson above), **not** script loading.
