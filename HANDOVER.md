# HANDOVER

Kurz-Briefing für den nächsten Chat. Quelle der Wahrheit für Scope/Roadmap bleibt
`PROJEKTPLAN.md`; Konventionen + B42-Gotchas stehen in `CLAUDE.md`.

**Stand:** 2026-05-29 · Mod-Version 0.0.4 · Branch `main` (alles committet + zu
`origin/main` gepusht).

## Aktueller Stand

**Phasen-Reihenfolge korrigiert:** Das Shop-Fundament (5b) kommt **vor** Q2. Die
alte To-do-Reihenfolge „Q2 zuerst" war falsch — es gilt der Roadmap-Order
**5b → 5c**. Q2 lebt in 5c und dockt an den fertigen Shop an.

**Ökonomie festgelegt:**
- Einzige Shop-Währung = **WHO Credits**, ein abstrakter ModData-Kontostand
  (`md.WHO_Credits`), **kein** physisches Item.
- Einkommensquelle = gewaschene Kleidung → WHO Credits über den **Fusion-Washer**
  (kommt erst mit Q2 / 5c).
- **Bootstrap (Henne-Ei):** beim Shop-Unlock erhält der Operator einen einmaligen
  Starter-Grant an Credits, um ein Q2-relevantes Item zu kaufen — überbrückt die
  Lücke, bis der Washer laufende Einnahmen liefert.

**Gebaut & in-game verifiziert (committet + gepusht):**
- **WHO Credits Ledger** (`WHO_Credits.lua`, commit `d3cbcee`):
  `get/add/spend/set`, nil-sicher, ModData-Auto-Persistenz über Save/Load.
  `spend()`/`add()` mit Typ-+Vorzeichen-Guard gehärtet. Debug: `Numpad 1` = +50
  Credits. Balance überlebt Save/Load (mehrfach getestet).
- **WHO-Shop** = Supply-Order-Terminal-Modus (Walking Skeleton, commit `985ec62`
  + Rename `d9053b0`): neuer Terminal-State `STATE_SUPPLY_ORDER`, übers Hauptmenü
  erreichbar, gegated über `supply_order_unlocked` (gesperrt = ausgegraut
  „[CLASSIFIED]"). Zeigt Saldo + **PLACEHOLDER-Katalog**. Kauf → `WHO_Credits.spend`
  → Lieferung in die Q1-Extraction-Kiste (`WHO_RewardDispatcher.deliverToCrate`,
  derselbe Pfad wie Q1-Rewards); zu wenig Credits = klares Feedback, kein Abzug.
  Debug: `Numpad 2` schaltet `supply_order_unlocked` um.

Beide Bausteine waren überwiegend **Verdrahtung bestehender Bricks** (Terminal-UI,
State-System, Spawn-Queue, Container-Delivery) — keine neue Technik.

## Offene Entscheidungen (TBD — JAB entscheidet, NICHT solo Claude Code)

- **Shop-Inhalt:** echter Katalog + Preise; Höhe des Starter-Grants; das konkrete
  Q2-Item, das der Starter-Grant kauft. (Aktuell nur PLACEHOLDER-Stock im Code.)
- **Q2-Design:** Drop-Site-Findung, Zombie-Encounter-Location, Washer-Lieferung.
  Der Fusion-Washer ist als **Custom-GPT-Image-World-Object** geplant; die B42
  Custom-Tile/Object-Pipeline muss noch recherchiert werden (Referenz: ein
  fokussierter Möbel-Mod + B42-Tile-Docs).
- **Ark-Mod** = Referenz für die **Quest-Architektur** später (NICHT für die
  Object-Pipeline).
- **„Warehouse Glow-up"** geparkt für Phase 8 (billig = Vanilla-Dressing /
  teuer = Custom-Build).

## Nächste Schritte

1. Shop-Inhalt entscheiden (Katalog/Preise/Starter-Grant/Q2-Item) → dann den
   PLACEHOLDER-Stock im WHO-Shop durch echte Werte ersetzen.
2. Q2 (5c) angehen: Quest-Definition + Washer-Mechanik — die
   Custom-Object-Pipeline vorher recherchieren.
3. Erst danach: weitere T1-Quests (Q3-Q5) + Vehicle-Drop (5c), siehe PROJEKTPLAN.

## Test-Hotkeys (nur bei `WHO_Config.DEBUG.ENABLED`)

`F7` Container-Report · `F8` Tankstelle · `F9` Spawn · `F10` Position ·
`Numpad 9` Quest WHO_Q001 annehmen · `Numpad 0` Quest-State ·
`Numpad 1` +50 Credits · `Numpad 2` `supply_order_unlocked` umschalten.
