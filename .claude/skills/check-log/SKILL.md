---
name: check-log
description: Read the latest Project Zomboid console output and surface this mod's [WHO] state markers plus any Lua errors / stack traces. Use after restarting PZ to verify a change loaded and behaved, or to triage a crash. Invoke with /check-log.
disable-model-invocation: true
---

# check-log

The Warehouse Operator test loop is "restart Project Zomboid → watch the console
for `[WHO] …` lines." This skill does that reading for you: it pulls the most
recent session out of PZ's `console.txt`, then reports the mod's state markers
and any Lua errors.

## Where the log lives

PZ overwrites a single console file on each launch, with dated archives:

- **Current session:** `%USERPROFILE%\Zomboid\console.txt`
  (here: `C:\Users\manta\Zomboid\console.txt`)
- **Archived sessions:** `%USERPROFILE%\Zomboid\Logs\logs_<YYYY-MM-DD>\` and
  `logs.zip`

Default to `console.txt`. Only reach into `Logs\` if the user asks about an
earlier session or `console.txt` is missing.

## What a [WHO] line looks like

```
LOG  : Lua          f:10486> [WHO] Quest requirements MET! Marking complete.
LOG  : Lua          f:12307> [WHO]   Removed 1/1 Base.WHO_PumpKey
```

The `f:NNNN>` field is an in-game frame counter — useful for ordering and for
spotting the per-minute `Quest-Check` spam (collapse repeats; don't dump them
all).

## Steps

1. **Run the parser** (do NOT `Read` the whole file — it's tens of KB and the
   `EveryOneMinute` quest-check repeats hundreds of times). The script is
   Windows PowerShell 5.1-compatible, so run it with whichever PowerShell the
   harness exposes — via the PowerShell tool:

   ```
   & ".claude/skills/check-log/parse-log.ps1"
   ```

   or via Bash if only that is available:

   ```bash
   powershell -NoProfile -File .claude/skills/check-log/parse-log.ps1
   ```

   Pass `-Path <file>` to point at an archived log, or `-Tail <n>` to widen the
   error context window (default 8 lines).

2. **Read the parser output**, which is already grouped into:
   - **Load markers** — `… module loaded`, `Mod version`, boot completion.
     Confirms the file actually loaded after your edit.
   - **State transitions** — quest accept / requirements met / complete /
     reward / finish / flag-unlock lines (the IDLE→ACTIVE→COMPLETE→IDLE flow).
   - **Quest-Check** — collapsed to first + last + count, since it fires every
     in-game minute.
   - **Errors / stack traces** — any line containing `ERROR`, `Exception`,
     `stack traceback`, `caused by`, or a `.lua:NN` frame in an error block.

3. **Report concisely.** Lead with the verdict:
   - ✅ if load markers are present and there are no errors — name the version
     and the last state reached.
   - ❌ if there's an error — quote the stack trace, identify the offending
     `WHO_*.lua:line`, and (briefly) the likely cause, cross-referencing the PZ
     gotchas in `CLAUDE.md` (0-indexed Java collections, B42 `ItemType`,
     `NullPointerException` from a missing item def, etc.).
   - ⚠️ if load markers are absent — the file may not have loaded (check
     alphabetical `AAA` ordering / `require` path / `42/mod.info`).

## Notes

- This skill is read-only. It never edits the log or the mod.
- If the user just ran the game, the current `console.txt` IS that session — no
  need to hunt through `Logs\`.
- Java stack traces (`NullPointerException at InventoryItemFactory …`) are the
  signature of the B42 item-definition bug documented in `CLAUDE.md`; flag it
  explicitly if you see it.
