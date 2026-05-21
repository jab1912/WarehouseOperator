# Warehouse Operator

Project Zomboid mod (Build 42). Extraction-Shooter-Mechanik: Operator-Charakter erhält Loot-Aufträge über ein 90s-Style-Terminal in einem Lagerhaus in Louisville.

**Status:** Phase 1 — Spawn System ✅  
**Target Build:** PZ 42.18.0 (Unstable)  
**Mode:** Single-Player only  

## Phasen-Fortschritt

- [x] **Phase 0** — Setup (mod skeleton, mod.info, Git)
- [x] **Phase 1** — Spawn System (Warehouse spawn, starter kit, equip)
- [ ] **Phase 2** — Quest-Logik (MVP, ohne UI)
- [ ] **Phase 3** — Terminal UI
- [ ] **Phase 4** — Extraction & Reward
- [ ] **Phase 5** — Multiple Quests
- [ ] **Phase 6** — Polish (Insertion-Cutscene, Death-Handling)

## Struktur

\`\`\`
WarehouseOperator/
├── mod.info                            # B41-Marker
├── common/
│   └── mod.info                        # B42-Marker
└── 42/media/                           # B42-spezifischer Code
    └── lua/
        ├── client/
        │   ├── WHO_HelloWorld.lua      # Load-Test + OnGameStart-Log
        │   ├── WHO_Teleport.lua        # F9/F10 Debug-Teleporter
        │   └── WHO_Spawn.lua           # OnNewGame: Warehouse-Spawn + Starter-Kit
        └── shared/WarehouseOperator/
            └── WHO_Config.lua          # Zentrale Konstanten (Koordinaten etc.)
\`\`\`

## Development

Mod liegt direkt in `%USERPROFILE%\Zomboid\mods\WarehouseOperator` — Änderungen sind nach PZ-Neustart sofort aktiv.

**Dev-Tooling:**
- VSCode + EmmyLua-Extension (Tangzx)
- Umbrella Type Stubs (lokal in `C:\Users\manta\dev\Umbrella`)
- `.emmyrc.json` mit Umbrella-Pfad