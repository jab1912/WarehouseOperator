# Project Zomboid Mod: "Warehouse Operator"

**Arbeitstitel** | Single-Player | Build 42

---

## Konzept

Extraction-Shooter-Mechanik für Project Zomboid. Der Spieler ist ein "Operator" einer fiktiven Organisation, die ein Lagerhaus am Rande von Louisville betreibt. Über ein 90s-Style-Terminal (MS-DOS / Win 3.11 Mockup) bekommt er Loot-Aufträge zugewiesen. Erfüllte Aufträge werden von einem Truck abgeholt, als Belohnung gibt es Waffen und Ausrüstung für den nächsten Auftrag.

**Death & Respawn:** Vanilla-Mechanik bleibt erhalten – stirbt der Operator, wandert seine Leiche samt mitgeführter Ausrüstung als Zombie weiter. Ein neuer Operator wird per Insertion-Cutscene eingeflogen/abgesetzt und übernimmt im Warehouse. Was im Stash war, bleibt erhalten. Was draußen war, ist verloren (oder kann von der eigenen Leiche zurückgeholt werden → "Scav Run").

## Lore

**WHO - Warehouse Hazmat Outfitters**

Fiktive Logistik-/Tarnfirma die offiziell auf "hazardous materials handling" 
spezialisiert ist, tatsächlich aber ein Netzwerk von Operatoren steuert die 
in gefährliche Gebiete entsandt werden um wertvolle Materialien zu bergen.

**Tone:** 90s Action-Movie. Bruce-Willis-Vibe. Self-aware aber 
committed - wir nehmen unsere eigenen Klischees ernst. Cheesy ja, aber 
konsistent cheesy. Vergleichbar mit Die Hard, Total Recall, Demolition Man.

**In-Game-Verwendung:**
- Logo erscheint im Terminal-Boot (Phase 3a)
- Quest-Briefings als Absender: "WHO Logistics Division"
- Audio: "Operator [N], this is WHO Command..." bei Funksprüchen (Phase 6)
- Workshop-Branding: "WHO - Warehouse Operator" als Mod-Name
- Konsistente fake-Corporate-Sprache: "containment", "asset recovery", 
  "extraction protocol", "operator deployment"

---

## Tech Stack

- **Sprache:** Lua (Project Zomboid Modding API)
- **Target Build:** 42.18.0 (Unstable, Stand Mai 2026)
- **Map:** Bestehende Vanilla-Location in Louisville Industrial Warehouse
- **Repo:** GitHub `jab1912/WarehouseOperator` (public)
- **Test-Setup:** Lokale PZ-Instanz, F9/F10-Debug-Keys, alle anderen Mods deaktiviert für Dev
- **Multiplayer:** NEIN – komplett client-side

---

## Locations (Louisville Warehouse)

| Position | Koordinaten | Zweck |
|---|---|---|
| SPAWN_POS | 12619 / 4686 / 0 | Vorhof, vor Eingang (Operator-Spawn + Phase-6-Insertion) |
| TERMINAL_POS | 12607 / 4728 / 0 | Tisch im Chefbüro (Phase 3) |
| EXTRACTION_POS | 12626 / 4700 / 0 | Kiste im Lagerbereich (Phase 2+) |

---

## Architektur

\`\`\`
WarehouseOperator/
├── mod.info                            # B41-Marker
├── common/
│   └── mod.info                        # B42-Marker
└── 42/media/
    ├── lua/
    │   ├── client/                     # UI, Terminal, Quest-Anzeige, Cutscenes
    │   │   ├── WHO_HelloWorld.lua      # Load-Marker
    │   │   ├── WHO_Teleport.lua        # F9/F10 Debug
    │   │   └── WHO_Spawn.lua           # Forced spawn + starter kit
    │   └── shared/WarehouseOperator/   # Quest-Defs, Config, Loot-Tables
    │       └── WHO_Config.lua          # Zentrale Konstanten
    ├── scripts/                        # Custom Items (Terminal, Stash, Marker)
    ├── sounds/                         # Terminal, Truck, Funk
    └── textures/                       # UI-Sprites, Icons
\`\`\`

---

## Phasen

### Phase 0: Recherche & Setup ✅ COMPLETE

- [x] Build-42-Status geklärt, Target = 42.18.0
- [x] Dev-Setup: VSCode + EmmyLua + Umbrella Type Stubs
- [x] Mod-Ordner-Struktur (mod.info Root + common + 42/)
- [x] Git-Repo lokal + GitHub
- [x] "Hello World" lädt sauber, OnGameStart-Hook funktioniert
- [x] Warehouse-Location gewählt: Louisville Industrial Warehouse

---

### Phase 1: Custom Spawn ✅ COMPLETE

- [x] Forced-Spawn an SPAWN_POS via OnNewGame (NICHT OnGameStart, damit bestehende Saves unangetastet)
- [x] Starter-Kit: Pistol, 9mmClip, 30x Bullets9mm, Bandage, Crowbar
- [x] Pistole als Primary, Crowbar als Secondary (cinematisch beim Spawn)
- [x] Funkgerät verworfen (15kg-Brocken, niemand schleppt das)
- [x] Zentrale Config-Datei mit allen Koordinaten + DEBUG-Kill-Switch
- [x] F9/F10 Debug-Teleport für weitere Dev-Arbeit

---

### Phase 2: Quest-Logik MVP (2-3 Sessions) — NEXT

- [ ] Quest-Datenstruktur in Lua definieren (id, name, description, requirements, rewards, tier)
- [ ] EINE fest verdrahtete Quest: "Bring 5 Dosen Bohnen zur Extraction-Kiste"
- [ ] Extraction-Container im Warehouse (Vanilla-Kiste an EXTRACTION_POS markieren)
- [ ] Quest-State-Management (active/in-progress/complete) im Player-Object
- [ ] **Quest-Annahme:** Rechtsklick auf Tisch im Bürozimmer (an TERMINAL_POS-Tile) →
      Context-Menü-Eintrag "Mission annehmen [DEBUG]"
      (Wird in Phase 3 durch Terminal-UI ersetzt — dieselbe Backend-Mechanik, anderes Frontend)
- [ ] Check-Loop: prüft Extraction-Kisten-Inhalt jede Spielminute (EveryOneMinute-Event)
- [ ] Quest-Complete-Trigger: Items werden aus Kiste entfernt, Belohnung in Kiste gelegt
- [ ] Log-Events für jedes State-Change zum Debuggen

**Deliverable:** Eine Quest funktioniert end-to-end ohne UI. Nur Context-Menü + Logs.

---

### Phase 2.5: Persistenz / ModData (1-2 Sessions) — NEU

- [ ] Quest-State über Save/Load erhalten via ModData
- [ ] Operator-Counter persistieren (für Phase 6)
- [ ] OnSave / OnGameStart-Wiederherstellung implementieren
- [ ] Stash-Inhalt-Referenz (Extraction-Kiste): Wiedererkennen nach Reload
- [ ] Migration-Pattern: was wenn Spielstand älter als aktuelle Mod-Version ist
- [ ] Test: Quest aktiv → Save → Quit → Load → Quest noch da

**Deliverable:** Mod überlebt Save/Load. Bei Mod-Updates kein Daten-Verlust.

**Warum hier und nicht später:** Wenn wir das nach Phase 3-5 einbauen, müssen wir
viel Code anpassen. Hier ist's billig, weil nur Phase-2-State zu persistieren ist.

---

### Phase 3a: Terminal als Item + Statisches UI (2 Sessions)

- [ ] Custom-Item "Operator Terminal" in scripts/-Folder definieren
- [ ] Sprite/Texture für Terminal (alter Röhrenmonitor)
- [ ] Im Warehouse vorplatziert oder Platzier-Mechanik via Code
- [ ] Rechtsklick → "Boot Terminal"-Menüeintrag (ersetzt Phase-2-Debug-Eintrag)
- [ ] ISPanel-Subklasse: leeres Terminal-Fenster (DOS-Grün auf Schwarz oder Win-3.11)
- [ ] **Style-Entscheidung in 3a treffen**, nicht erst 3c
- [ ] Boot-Sequenz: simple Version (BIOS-Text, dann Hauptmenü)
- [ ] Hauptmenü: 4 Buttons (MISSIONS / INVENTORY / STATUS / SHUTDOWN), nur MISSIONS funktional

**Deliverable:** Terminal lässt sich öffnen, Hauptmenü ist da, sieht 90s-mäßig aus.

---

### Phase 3b: Mission-View funktional (2 Sessions)

- [ ] Mission-View: Liste verfügbarer Quests mit Tier-Anzeige
- [ ] Quest-Details: Description, Requirements, Reward-Preview
- [ ] "Accept Mission"-Button → triggert dieselbe Logik wie Phase-2-Debug-Eintrag
- [ ] Aktive Quest separater Bereich: Progress-Anzeige
- [ ] Mission-Complete-Notification im Terminal

**Deliverable:** Quest komplett übers Terminal annehmen, tracken, abschließen.

---

### Phase 3c: Polish & Atmosphäre (1-2 Sessions)

- [ ] Tipp-Animationen für Text-Output
- [ ] Sound: Tastatur-Klicken, Modem-Sounds, CRT-Brummen
- [ ] Boot-Sequenz aufmotzen (Memory-Check, Drive-Spinup-Sounds, "Starting OPERATOR.EXE...")
- [ ] CRT-Flicker / Scanlines-Overlay (optional, Performance-Check)
- [ ] STATUS-Page (Operator-Nummer, Total-Missions, Stash-Wert)
- [ ] SHUTDOWN-Animation (CRT-Off-Effekt)

**Deliverable:** Terminal fühlt sich richtig 90er-mäßig an.

---

### Phase 4: Truck-Extraction (2-4 Sessions)

- [ ] Bei Quest-Complete: Truck-Event triggern (Funkspruch-Sound, Terminal-Notification)
- [ ] **Variante A:** Echter Truck spawnt außerhalb, fährt zum Warehouse-Tor, hält an, fährt weg
- [ ] **Variante B:** Vereinfacht – Truck-Sound + Fade + Loot verschwindet aus Extraction-Container + Reward-Container erscheint
- [ ] Entscheidung A vs. B nach Komplexitäts-Check während Implementation (Default: B, weil Vehicle-AI in PZ wackelig ist)
- [ ] Reward-Container ist eindeutig markiert ("INCOMING SUPPLY DROP")
- [ ] Terminal zeigt "Mission complete. Next mission available."

**Deliverable:** Truck holt Loot, Reward erscheint, Loop schließt sich.

### Phase 4c (NEU): Mission Briefing Printer

**Konzept:** Dot-Matrix-Drucker im Bürozimmer neben dem Terminal. 
Beim Annehmen einer Mission spuckt er ein "Briefing"-Item aus, das der 
Operator ins Inventar nimmt und unterwegs lesen kann.

- [ ] Custom Item `WHO_MissionBriefing` (Papier-Sprite, leichtgewichtig)
- [ ] Drucker-Objekt im Warehouse platziert (Sprite-Sound-Event beim Drucken)
- [ ] Quest-Daten als ModData ins Item serialisieren (id, name, description, requirements, spawn location)
- [ ] Right-click Read → Custom-UI oder Konijima-Style Modal mit Briefing-Text
- [ ] Optional Tier 2+: Map-Sprite mit Quest-Spawn-Marker
- [ ] Sound: Dot-Matrix-Print-Sound (klassisches 90s-Sound-Effect)
- [ ] Beim Quest-Complete: Briefing-Item kann zerstört werden ("burn after reading")

**Lore-Note:** "Hardcopy required for field operations. Digital uplink 
classified beyond facility perimeter."

**Aufwand:** ~2-3 Sessions. Erfordert Custom-Item-Skripting (scripts/) - 
erstes Mal in diesem Mod dass wir das machen.

---

### Phase 5: Quest-Pool & Progression (3-5 Sessions)

- [ ] 10-15 handgeschriebene Quests in verschiedenen Tiers
- [ ] **Tier-System:**
  - T1: Food, Meds, Basic Tools (Anfänger, leicht zu finden)
  - T2: Ammo, bessere Werkzeuge, Mechanik-Teile (Mid-Game)
  - T3: Waffen, seltene Items, militärische Ausrüstung (End-Game, gefährliche Locations)
- [ ] Reward-Pools pro Tier, mit zufälliger Auswahl aus dem Pool
- [ ] Quest-Auswahl-Logik: nach Abschluss von X Quests in Tier N werden Tier-N+1-Quests freigeschaltet
- [ ] Optional: 2-3 Quests pro Tag verfügbar, dann Cooldown ("Convoy arrives tomorrow")

**Deliverable:** Spielbare Progression über mehrere Spiel-Tage, sichtbarer Schwierigkeitsanstieg.

---

### Phase 6: Death & Respawn Handling (2-3 Sessions)

- [ ] Death-Event abfangen
- [ ] Insertion-Cutscene bauen:
  - Schwarzer Screen + Funkspruch-Sound: "Operator [N] KIA. Deploying replacement."
  - Fade-In: neuer Operator steht neben Insertion-Vehicle vor dem Warehouse
  - Vehicle-Sprite fährt/fliegt weg (Sound + simple Sprite-Animation, kein echtes Pathing)
- [ ] Neuer Operator spawnt mit Basis-Equipment (wie Phase 1)
- [ ] Quest-State bleibt erhalten: aktive Mission wird übernommen
- [ ] Operator-Counter im Terminal hochzählen ("Operator 03 online")
- [ ] Terminal-Boot zeigt: "Previous operator status: MIA. Stash inventory preserved."
- [ ] Vanilla-Death-Mechanik bleibt unberührt: alte Leiche zombifiziert mit Loadout

**Deliverable:** Death → nahtloser Respawn-Loop mit narrativer Einbettung.

---

### Phase 7: Polish & Externe Dependencies

- [ ] Sound-Design vervollständigen: Truck, Terminal, Funksprüche, Mission-Notifications
- [ ] Icons und Texturen final
- [ ] Balance-Pass: Quest-Schwierigkeit vs. Reward-Wert, Tier-Übergänge
- [ ] Sandbox-Optionen (Quest-Frequenz, Reward-Qualität, Tier-Progression-Speed einstellbar)
- [ ] Bug-Fixing
- [ ] Optional: Lore-Texte im Terminal (E-Mails, "Tagesnachrichten" der fiktiven Organisation)

**Externe Mod-Dependencies (TBD nach MVP):**

- **GaelGunStore_B42** (Workshop ID: 3616176188) by Pen-Pen Pirulin
  - Lizenz: Copyright 2026, no repack/reupload/edit. Dependencies vermutlich ok.
  - **Permission-Workflow:**
    1. MVP fertigstellen (Phase 5+ abgeschlossen)
    2. Demo-Video/GIF erstellen
    3. Steam-Nachricht / Discord an Pen-Pen Pirulin:
       - Demo zeigen
       - Konkretes Integrations-Konzept beschreiben
       - Höflich anfragen
    4. Falls ok: Hard Dependency in mod.info, Workshop-Beschreibung erwähnt ihn prominent
  - Use-Case: Tier-3 / Boss-Tier-Belohnungen

**Workflow für weitere Mod-Kandidaten:**
- Soft Dependency bevorzugen wo möglich
- Immer Permission anfragen
- Credit in Workshop-Beschreibung + README

---

### Phase 8: Release

- [ ] Workshop-Beschreibung, Screenshots, Trailer-GIF
- [ ] mod.info finalisieren (Version, Dependencies, Author)
- [ ] Versions-Tagging im Git
- [ ] Upload auf Steam Workshop

---

## Bestätigte Entscheidungen

1. ✅ **Warehouse-Location:** Louisville Industrial Warehouse (Koordinaten oben)
2. ✅ **Quest-Geber:** 90s-Style-Terminal als Rechtsklick-Objekt im Bürozimmer
3. ✅ **Multiplayer:** Nein, Single-Player only
4. ✅ **Death-System:** Vanilla beibehalten + Insertion-Cutscene, Stash bleibt erhalten
5. ✅ **Build-Target:** 42.18.0 Unstable (defensiv coden, bei Stable testen)

## Offene Entscheidungen

- **Truck-Variante A oder B** (Entscheidung in Phase 4)
- **Terminal-Style:** DOS-Grün oder Win-3.11-Grau (Entscheidung in Phase 3a)
- **Externe Mod-Dependencies** (Permission-Anfragen in Phase 7)

---

## Risiken / Unbekannte

- ~~Build 42 API könnte stellenweise unterdokumentiert sein~~ → Umbrella deckt das ab
- Vehicle-Spawning für Insertion-Cutscene: muss eventuell durch reines Sprite-Overlay ersetzt werden, falls Vehicle-API zu sperrig ist
- Terminal-UI-Performance: ISPanel-Animationen können bei zu vielen Effekten ruckeln
- ModData-Migration zwischen Mod-Versionen: muss von Anfang an mitgedacht werden (Phase 2.5)


## Dev-Lessons Learned

- **Container-Koordinaten in-game verifizieren, nicht von Map ablesen.**
  Map-Site (map.projectzomboid.com) ist um 1-2 Tiles ungenau bei Container-Objekten.
  Workflow: ingame zur Stelle gehen → Rechtsklick → "Tile Report"-Tooltip
  zeigt die exakte Position (x/y/z). Diese ist verbindlich für den Code.
  Map ist trotzdem nützlich für Areale, Räume, Übersicht.

- **Spawner ist robust gegen falsche Tile-Koordinaten** durch Boden-Fallback:
  Wenn keine Container am Ziel-Tile, landen Items auf dem Boden statt zu
  verschwinden. Trotzdem: bei verschlossenen Häusern problematisch
  (siehe Phase 7 - "Verschlossene Häuser als Quest-Element").

- **TODO Phase 5+:** Spawner um "scan nearby tiles for container" erweitern
  (3x3 oder 5x5 Raster um das Ziel-Tile checken). Macht Quest-Design robuster
  bei Off-by-one-Tile-Fehlern.

- **Sporadische Startup-Crashes bei PZ 42.18 Unstable**
  Symptom: schwarzer Bildschirm beim Start, dann CTD. Beim 2. Versuch läuft's.
  Ursache: AMD-OpenGL/Display-Init-Race-Condition (verifiziert via DebugLog —
  PZ stirbt im OpenGL-Init, lange vor Lua-Loading).
  Konsequenz: nicht modspezifisch, kein Bugfix nötig. Vor Workshop-Release
  in Phase 8 auf PZ Stable verifizieren.


## Asset-Strategie (UPDATED 23.05.26)

**AI-Generation funktioniert besser als initial angenommen!**
Test mit Image GPT 2 / Grok zeigt: isometric pixel-art Sprites mit 
PZ-tauglichem Stil sind machbar. Workflow validiert mit Drucker-Sprite.

**Pipeline:**
- **UI-Bilder (Logos, Boot-Screens, CRT-Effekte):** OpenArt / Grok mit 
  klassischen Prompts
- **Pixel-Art-Sprites (Custom-Items, Möbel):** ChatGPT-Image / Grok mit 
  spezialisiertem Iso-Prompt-Pattern
- **Mod-Icon + Workshop-Banner:** OpenArt mit Marketing-Prompts

**Prompt-Template für PZ-Sprites:** (siehe Drucker-Test) — explizit nach
"Project Zomboid game sprite", "isometric pixel art", "transparent background",
"limited color palette" fragen.

**Empfehlung:** OpenArt-Abo (~30€/Monat) reaktivieren wenn Phase 4c oder 
Phase 5 anstehen. Bis dahin sammeln wir Asset-Ideen.

---

## Aufwandsschätzung (aktualisiert)

| Stufe | Stunden | Bei 10-15h/Woche |
|-------|---------|------------------|
| ✅ Setup + Spawn (Phase 0-1) | ~8h (done) | – |
| Quest-MVP + Persistenz (bis Phase 2.5) | +6-10h | 0.5-1 Woche |
| Terminal-UI komplett (bis Phase 3c) | +15-25h | 1.5-2 Wochen |
| Truck + Quest-Pool (bis Phase 5) | +15-25h | 1-2 Wochen |
| Death-Loop (bis Phase 6) | +8-15h | 1 Woche |
| Workshop-Release (bis Phase 8) | +25-50h | 2-4 Wochen |

**Total MVP-Release:** ~80-130h Restzeit, also 2-3 Monate bei 10-15h/Woche.