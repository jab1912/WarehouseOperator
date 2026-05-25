# Code Review — Phase 5 Baseline

Non-destructive review pass. **No code was changed** — this is a findings-only
report for triage.

**Scope:** `WHO_AAA_TerminalUI.lua` (client) and the shared modules
`WHO_Config`, `WHO_Quests`, `WHO_QuestState`, `WHO_ItemSpawner`.

**Severity tags:** `CRITICAL` (bug / breaks behavior) · `NICE-TO-HAVE`
(maintainability / polish) · `NITPICK` (cosmetic / trivial).

**Effort scale:** trivial (<5 min) · low (~15–30 min) · medium (~1–2 h).

**Triage — 2026-05-24 (Bucket 1 done):** display names (`7ca864c`), UI button +
line-block DRY (`0017f47`), and `DEBUG.ENABLED` default `false` (`e28ed57`) are
resolved — see the ✅ annotations below.

**Triage — 2026-05-25 (Bucket 2):** `container:AddItem` return now checked with a
floor-drop fallback (`90b608d`) — see the ✅ annotation under WHO_ItemSpawner.lua.
All other findings remain open.

## Overall verdict

The codebase is in good shape. **There are no CRITICAL findings.** The terminal
UI was recently reworked (3b.5 / 3c) and is well-structured: it follows the
manual hit-test pattern, 0-indexed Java iteration, and load-marker conventions
described in CLAUDE.md. The `print("[WHO] …")` calls throughout are intentional
state logging per CLAUDE.md — **not** leftover debug, and not flagged as such.

Almost everything below is maintainability cleanup (mostly in the large UI file)
and a handful of stale comments. The shared modules are small and defensive.

---

## WHO_Config.lua

Clean. Pure data, consistent `UPPER_SNAKE` keys, coordinates centralized exactly
as intended. The `WHO_Q001` spawn coordinate is an **intentional, well-documented
placeholder** (TODO marker, lines 28–33) — not a finding.

- **NITPICK — `DEBUG.ENABLED = true` is committed (line 53).** Fine for active
  dev, but it ships the F9/F10 debug hooks live.
  *Fix:* add to the Phase 9 release checklist to flip it to `false` (or drive it
  from a sandbox option). *Effort:* trivial.
  > **✅ RESOLVED (`e28ed57`):** default flipped to `false`, with a "set true for
  > local dev" comment above it.

---

## WHO_Quests.lua

Clean static-data module. Helpers are simple and correct. `getByTier` **is** used
(WHO_TerminalDebugMenu.lua:55), so it is not dead code. Three stale comments only:

- **NITPICK — line 15 references "Phase 3b.7".** No such phase exists in
  PROJEKTPLAN (handler/`DOC`/`OVERSEER` work is now Phase 8 after the renumber).
  *Fix:* drop the parenthetical or point it at Phase 8. *Effort:* trivial.

- **NITPICK — lines 16–17 describe superseded behavior.** "Phase 3b zeigt nur die
  erste Zeile als 'Mission Briefing' statisch" is no longer true: the 3b.5 codec
  typewriters all lines and the detail pane renders multiple lines.
  *Fix:* update or remove the note. *Effort:* trivial.

- **NITPICK — line 101 comment is phase-stale.** "Später (Phase 5): nach
  Progression filtern" — `getAvailable()` still returns everything; tier-gated
  progression is now Phase 6 (City) per the renumber, while Phase 5 Probation
  only sequences T1. *Fix:* clarify the phase reference. *Effort:* trivial.

---

## WHO_QuestState.lua

Solid little state machine; naming consistent; ModData migration for `flags`
handled defensively (lines 121, 128). `hasFlag` (line 126) is currently unused —
that is **expected** (Phase 5b will read it), not dead code.

- **NICE-TO-HAVE — `canAcceptQuest` (lines 45–48) has no callers** anywhere in
  the repo (verified by grep). `acceptQuest` already enforces the IDLE
  precondition internally (lines 53–56), so this is redundant public API.
  *Fix:* remove it, or wire it into the UI's accept-gating if that was the intent.
  *Effort:* low.

- **NICE-TO-HAVE — `ensureModData` has no nil-guard on `player` (lines 15–16).**
  It calls `player:getModData()` directly. Callers use `self.player or
  getPlayer()`, and `getPlayer()` can return nil (e.g. early load), which would
  crash here. Low real-world probability (the terminal only opens with a valid
  player), hence not CRITICAL.
  *Fix:* `if not player then return nil end` guard, and let callers tolerate nil.
  *Effort:* low.

- **NITPICK — lazy `require` inside `acceptQuest` (lines 69–70).** `WHO_Config`
  and `WHO_ItemSpawner` are required mid-function, while `WHO_Quests` is required
  at file top (line 5). No circular-dependency reason is apparent.
  *Fix:* hoist both to the top for consistency, or add a one-line comment if the
  lazy load is deliberate. *Effort:* trivial.

---

## WHO_ItemSpawner.lua

Small, focused, and defensive (nil-checks `getCell()` and the grid square; documents
the 0-indexed Java list). Two trivial items plus one robustness gap:

- **NICE-TO-HAVE — `container:AddItem` return value is ignored (line 52).** A full
  container would silently drop items while `spawnAt` still returns `true` and
  `spawnBatchAt` counts it as success — quest-critical items could fail to spawn
  invisibly. Ties into the existing PROJEKTPLAN "scan nearby tiles for container"
  TODO. *Fix:* check the `AddItem` result; on failure fall back to the floor drop.
  *Effort:* low–medium.
  > **✅ RESOLVED (`90b608d`):** `spawnAt` and `spawnInContainerType` now compare
  > `getItems():size()` before vs after `AddItem` (and log the `AddItem` return); on
  > no increase they log the failure and fall through to the floor drop instead of
  > reporting false success. Added `describeContainer()` and an enumerate-all-matches
  > log for diagnosis. (The related "scan nearby tiles" TODO was already covered by
  > `spawnInContainerType`'s radius search and removed separately.)

- **NITPICK — unused loop variable `n` (lines 51 and 58).** Also flagged by LuaLS.
  *Fix:* `for _ = 1, count do`. *Effort:* trivial.

- **NITPICK — magic numbers `0.5, 0.5, 0.0` (line 59).** Tile-relative drop offset
  (tile center). *Fix:* name a constant or add an inline comment. *Effort:* trivial.

---

## WHO_AAA_TerminalUI.lua

Large (1194 lines) but coherent. Layout-helper / hit-test split is exactly the
pattern CLAUDE.md prescribes, and the recent 3c rework eliminated the old overlap
glitches. **No CRITICAL issues.** The findings are duplication, magic numbers, and
one dead field — i.e. maintainability, not correctness.

- **NICE-TO-HAVE (player-facing) — objectives/rewards print the raw `itemType`.**
  The mission views render strings like `Deliver 1x Base.WHO_PumpKey` /
  `+ 30x Base.Bullets9mm` instead of display names. Affects
  `renderQuestDetailPane` (685, 697), `renderActiveMissionView` (726),
  `renderCompletedMissionView` (761), and `renderBriefingObjectives` (914, 925).
  *Fix:* resolve a display name once
  (`getScriptManager():getItem(type):getDisplayName()`, with a fallback to the raw
  type) and reuse it. *Effort:* low–medium.
  > **✅ RESOLVED (`7ca864c`):** added a cached `itemDisplayName()` helper
  > (pcall-guarded, raw-id fallback); routed all four render paths through it.

- **NICE-TO-HAVE — duplicated "menu text button" rendering.** The same pattern
  (label + hover `>`/`<` arrow + stored hit-width) is copy-pasted across
  `renderClose` (788), `renderActionButton` (770), `renderBackButton` (567), and
  `renderBriefingAbort` (836). *Fix:* one `drawMenuTextButton(label, x, y, hovered,
  align, arrowChar)` helper. *Effort:* medium.
  > **✅ RESOLVED (`0017f47`):** extracted `drawMenuTextButton(...)`; all four
  > renderers delegate to it. Behaviour verified by trace + LuaLS `--check`.

- **NICE-TO-HAVE — duplicated objectives/rewards loops.** The "objectives" loop
  and the "rewards" loop each appear in three render paths (detail pane / active /
  complete / briefing). *Fix:* extract `renderObjectives(x, y, quest, lineH)` and
  `renderRewards(x, y, quest, lineH)`. *Effort:* medium. (Folds in the display-name
  fix above.)
  > **✅ RESOLVED (`0017f47`):** extracted `renderObjectiveLines()` /
  > `renderRewardLines()`; all six loops now delegate.

- **NICE-TO-HAVE — `color.r, color.g, color.b, color.a` repeated ~30×.** Every
  left-aligned `drawText` spells out all four channels. *Fix:* a
  `drawTextColored(text, x, y, color, font)` wrapper alongside the existing
  `drawTextCentered`. *Effort:* low.

- **NICE-TO-HAVE — pervasive magic layout numbers.** Line heights (20 / 22 / 30 /
  36 / 46) and spacing (14 / 16 / 22 / 28 / 35 / 40 / 44 / 50 / 56 / 80) are inline
  literals across the render functions. `lineH = 20` is redefined locally (651,
  906); visually similar lists use different heights (20 vs 22 vs 30); the
  reserved-space math at line 658 hardcodes section gaps that also recur below it.
  Some constants already exist (`FOOTER_PAD_MIN`, `BTN_GAP_MIN`, …) — this would
  extend that. *Fix:* hoist a small spacing-constant block (`LINE_H`,
  `SECTION_GAP`, `LABEL_GAP`, …) and reuse. *Effort:* medium.

- **NICE-TO-HAVE — long multi-state input dispatchers.** `onMouseDown`
  (1027–1116, ~90 lines) and `onMouseMove` (952–1025, ~73 lines) branch over every
  state inline. *Fix:* split per-state handlers (`handleMissionsMouseDown`,
  `handleBriefingMouseDown`, …) mirroring the render-function split. *Effort:* medium.

- **NITPICK — `hoveredQuestIndex` is dead state.** Written at 152 / 957 / 989 but
  never read (the list highlight uses `selectedQuestIndex`). Verified: no reads
  anywhere. *Fix:* either use it to show a hover highlight in
  `renderMissionsListView`, or remove the field and its three writes.
  *Effort:* low.

- **NITPICK — `self.player or getPlayer()` without a follow-up nil-guard** (553,
  981, 1055, 1096). Implies defensive intent that isn't completed; pairs with the
  `ensureModData` nil-check note above. In practice `self.player` is always set at
  construction. *Effort:* low.

- **NITPICK — `LOGO_TEXTURE = getTexture(...)` at file-load (line 96)** can return
  nil if assets aren't ready yet. It's guarded at the use site (`renderLogo`, 447),
  so it's harmless — worth a one-line comment noting the guard is load-bearing.
  *Effort:* trivial.
