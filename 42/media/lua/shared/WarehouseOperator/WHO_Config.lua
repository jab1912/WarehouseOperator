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
    -- WHO_Q001: "Prime the Pump" - Pump Key in der Tankstelle südlich/südwestlich
    -- des Warehouse.
    -- TODO Phase 5a: UNVERIFIZIERTER Platzhalter! Exakte Tankstellen-Koordinaten
    -- in-game per Tile-Report bestimmen (~2 Min südlich der SPAWN_POS, südwestlich).
    -- Bis dahin landet der Key per Boden-Fallback an dieser Näherungs-Position.
    WHO_Q001 = { x = 12595, y = 4780, z = 0 },
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
    -- Default false for Workshop builds (no debug hotkeys for players).
    -- Set true for LOCAL DEV to enable the F9/F10 hotkeys below.
    ENABLED = false,
    TELEPORT_KEY = 67,  -- F9: teleport to SPAWN_POS
    LOG_POS_KEY  = 68,  -- F10: log current position
}

return WHO_Config