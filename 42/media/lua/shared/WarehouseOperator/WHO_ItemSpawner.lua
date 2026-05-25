-- Warehouse Operator - Generic Item Spawner
-- Utility für das Spawnen von Items an Welt-Koordinaten.
-- Findet Container am Ziel und legt Items rein. Falls kein Container: auf den Boden.

local WHO_ItemSpawner = {}

-- =========================================================================
-- HELPER: Erstes Container-Objekt auf einem Square finden
-- =========================================================================

local function findContainerOnSquare(square)
    if not square then return nil end

    local objects = square:getObjects()
    if not objects then return nil end

    -- Java-ArrayList: 0-indiziert!
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj then
            local container = obj:getContainer()
            if container then
                return container
            end
        end
    end

    return nil
end

-- =========================================================================
-- HELPER: Nächsten Container eines bestimmten Typs im Umkreis finden
-- =========================================================================
-- Scannt ein (2r+1)x(2r+1)-Raster um (x,y,z) und liefert den per Manhattan-
-- Distanz nächsten Container, dessen getType() preferredType entspricht.
-- Vergleich case-insensitive (PZ-Konvention ist lowercase, z.B. "cashregister",
-- aber defensiv). Sammelt alle gefundenen Container-Typen fürs Debug-Logging.
-- Rückgabe: container, distance, foundTypes
local function findNearestContainerOfType(cell, x, y, z, preferredType, radius)
    local want = string.lower(preferredType)
    local best, bestDist = nil, nil
    local foundTypes = {}   -- alle im Radius gesichteten Typen (Debug)

    for dx = -radius, radius do
        for dy = -radius, radius do
            local square = cell:getGridSquare(x + dx, y + dy, z)
            if square then
                local objects = square:getObjects()
                if objects then
                    -- Java-ArrayList: 0-indiziert!
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        local container = obj and obj:getContainer()
                        if container then
                            local ctype = container:getType() or "?"
                            foundTypes[#foundTypes + 1] = ctype
                            if string.lower(ctype) == want then
                                local dist = math.abs(dx) + math.abs(dy)
                                if not bestDist or dist < bestDist then
                                    best, bestDist = container, dist
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return best, bestDist, foundTypes
end

-- =========================================================================
-- MAIN: Items an einer Welt-Position spawnen
-- =========================================================================

function WHO_ItemSpawner.spawnAt(x, y, z, itemType, count)
    local cell = getCell()
    if not cell then
        print("[WHO] Spawner: getCell() returned nil")
        return false
    end

    local square = cell:getGridSquare(x, y, z)
    if not square then
        print("[WHO] Spawner: no square at " .. x .. "/" .. y .. "/" .. z)
        return false
    end

    local container = findContainerOnSquare(square)

    if container then
        for n = 1, count do
            container:AddItem(itemType)
        end
        print("[WHO] Spawner: " .. count .. "x " .. itemType .. " into container at "
            .. x .. "/" .. y .. "/" .. z)
        return true
    else
        for n = 1, count do
            square:AddWorldInventoryItem(itemType, 0.5, 0.5, 0.0)
        end
        print("[WHO] Spawner: " .. count .. "x " .. itemType .. " on floor at "
            .. x .. "/" .. y .. "/" .. z .. " (no container found)")
        return true
    end
end

-- =========================================================================
-- TARGETED: Item in einen bestimmten Container-Typ im Umkreis spawnen
-- =========================================================================
-- Sucht den nächsten Container vom Typ preferredContainerType im Umkreis von
-- searchRadius Tiles (Default 3 => 7x7). Gefunden: Item rein + Log mit Distanz.
-- Nichts gefunden: Fallback auf spawnAt() (Container am Ziel-Tile, sonst Boden).
-- count ist optional (Default 1) und erweitert die skizzierte Signatur
-- rückwärtskompatibel um Mehrfach-Items.
function WHO_ItemSpawner.spawnInContainerType(itemType, x, y, z, preferredContainerType, searchRadius, count)
    searchRadius = searchRadius or 3
    count = count or 1

    local cell = getCell()
    if not cell then
        print("[WHO] Spawner: getCell() returned nil")
        return false
    end

    local container, dist, foundTypes =
        findNearestContainerOfType(cell, x, y, z, preferredContainerType, searchRadius)

    if container then
        for n = 1, count do
            container:AddItem(itemType)
        end
        print("[WHO] Spawned " .. count .. "x " .. itemType .. " in " .. preferredContainerType
            .. " at (" .. x .. "," .. y .. "," .. z .. ") - distance " .. dist .. " from target")
        return true
    end

    -- Kein passender Container im Radius: gesichtete Typen loggen (Debug-Hilfe),
    -- dann auf spawnAt() zurückfallen (Container am Ziel-Tile, sonst Boden).
    local typesStr = (#foundTypes > 0) and table.concat(foundTypes, ", ") or "none"
    print("[WHO] Spawner: no '" .. preferredContainerType .. "' container within "
        .. searchRadius .. " tiles of (" .. x .. "," .. y .. "," .. z .. ")"
        .. " - container types found: " .. typesStr)
    print("[WHO] Spawner: falling back to spawnAt()")
    return WHO_ItemSpawner.spawnAt(x, y, z, itemType, count)
end

-- =========================================================================
-- BATCH: Mehrere verschiedene Items auf einmal spawnen
-- =========================================================================

function WHO_ItemSpawner.spawnBatchAt(x, y, z, items)
    local successCount = 0
    for _, entry in ipairs(items) do
        if WHO_ItemSpawner.spawnAt(x, y, z, entry.itemType, entry.count) then
            successCount = successCount + 1
        end
    end
    return successCount
end

return WHO_ItemSpawner