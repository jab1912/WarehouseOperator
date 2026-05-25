-- Warehouse Operator - Central Configuration

local WHO_Config = {}

-- =========================================================================
-- WAREHOUSE LOCATIONS (Louisville)
-- =========================================================================

WHO_Config.WAREHOUSE = {
    -- Spawn-Position für neue Operatoren (Vorhof vor Eingang)
    SPAWN_POS = { x = 12619, y = 4686, z = 0 },

    -- Position des 90s-Terminals (Tisch im Chefbüro)
    TERMINAL_POS = { x = 12607, y = 4728, z = 0 },

    -- Position der Extraction-Kiste (Lagerbereich)
    EXTRACTION_POS = { x = 12628, y = 4701, z = 0 },
}

-- =========================================================================
-- QUEST ITEM SPAWN POSITIONS
-- =========================================================================
-- Wenn eine Quest angenommen wird, werden die Required-Items
-- an diesen Positionen in der Welt gespawnt.
-- Pro Quest-ID eine Koordinate.

WHO_Config.QUEST_ITEM_SPAWNS = {
    -- WHO_Q001: "Prime the Pump" - Pump Key in der Tankstelle südlich des Warehouse.
    -- Verified in-game: gas station general store, behind/under the cash register.
    WHO_Q001 = { x = 12740, y = 5037, z = 0 },
    -- WHO_Q002: Medical Supplies - leicht versetzt im selben Lagerbereich
    WHO_Q002 = { x = 12623, y = 4710, z = 0 },
}

-- =========================================================================
-- MOD METADATA
-- =========================================================================

WHO_Config.MOD = {
    ID = "WarehouseOperator",
    VERSION = "0.0.4",
    BUILD_TARGET = "42.18.0",
}

-- =========================================================================
-- DEBUG / DEVELOPMENT
-- =========================================================================

WHO_Config.DEBUG = {
    -- true during development. Set to false before Workshop release
    -- (see Phase 9 checklist in PROJEKTPLAN.md).
    ENABLED = true,
    TELEPORT_KEY = 67,  -- F9: teleport to SPAWN_POS
    LOG_POS_KEY  = 68,  -- F10: log current position
}

return WHO_Config