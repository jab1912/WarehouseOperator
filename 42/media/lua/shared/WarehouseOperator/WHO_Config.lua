-- Warehouse Operator - Central Configuration
-- Hier liegen alle festen Werte (Koordinaten, IDs, Konstanten),
-- damit wir sie an einer Stelle anpassen können statt im ganzen Code rumzusuchen.

-- Modul-Table: das ist unser "Namespace"
-- Andere Files können `require "WarehouseOperator/WHO_Config"` machen
-- und kommen dann an WHO_Config.WAREHOUSE.SPAWN_POS heran.
local WHO_Config = {}

-- =========================================================================
-- WAREHOUSE LOCATIONS (Louisville)
-- =========================================================================

WHO_Config.WAREHOUSE = {
    -- Spawn-Position für neue Operatoren (Vorhof vor Eingang)
    -- Wird in Phase 1.4 und Phase 6 (Insertion-Cutscene) genutzt
    SPAWN_POS = { x = 12619, y = 4686, z = 0 },

    -- Position des 90s-Terminals (Tisch im Chefbüro)
    -- Wird in Phase 3 (Terminal-UI) genutzt
    TERMINAL_POS = { x = 12607, y = 4728, z = 0 },

    -- Position der Extraction-Kiste (Lagerbereich)
    -- Hier landen Quest-Belohnungen, hier wird Loot abgegeben
    -- Wird in Phase 2 genutzt
    EXTRACTION_POS = { x = 12626, y = 4700, z = 0 },
}

-- =========================================================================
-- MOD METADATA
-- =========================================================================

WHO_Config.MOD = {
    ID = "WarehouseOperator",
    VERSION = "0.0.3",
    BUILD_TARGET = "42.18.0",
}

-- =========================================================================
-- DEBUG / DEVELOPMENT
-- =========================================================================

-- Schaltet Debug-Features ein (Teleport-Keys, Verbose-Logging, etc.)
-- Auf false setzen vor Release.
WHO_Config.DEBUG = {
    ENABLED = true,
    TELEPORT_KEY = 67,  -- F9: teleport to SPAWN_POS
    LOG_POS_KEY  = 68,  -- F10: log current position
}

-- Modul zurückgeben, damit `require` es als Wert bekommt
return WHO_Config