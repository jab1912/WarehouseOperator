-- Warehouse Operator - Generic Item Spawner
-- Utility für das Spawnen von Items an Welt-Koordinaten.
-- Findet Container am Ziel und legt Items rein. Falls kein Container: auf den Boden.

local WHO_ItemSpawner = {}

-- Diagnose: letzter Container, in den (versucht wurde zu) gespawnt wurde. Vom
-- F7-Container-Report (WHO_Teleport) für das MATCH/DIFFERENT-Urteil genutzt.
-- Nur Session-lokal, nicht persistiert.
WHO_ItemSpawner.lastSpawnDebug = nil

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
    local matches = {}      -- alle passenden Container (D2): { container, dist, x, y, z }

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
                                matches[#matches + 1] =
                                    { container = container, dist = dist, x = x + dx, y = y + dy, z = z }
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

    return best, bestDist, foundTypes, matches
end

-- =========================================================================
-- DIAGNOSE-HELFER (Container-Identität, verifiziertes AddItem, Boden-Drop)
-- =========================================================================

-- PZ-Methoden defensiv aufrufen: Diagnose darf NIE crashen (nil-Rückgaben oder
-- in den Stubs fehlende Methoden abfangen).
local function safe(fn)
    local ok, val = pcall(fn)
    if ok then return val end
    return nil
end

-- Kompakte Identitäts-Beschreibung eines Containers für Logs + F7-Report:
-- Typ, Instanz (tostring = Java-Referenz/Hashcode, eindeutig pro Objekt),
-- besitzendes Objekt (Index + Sprite), dessen tatsächliches Tile, Item-Anzahl.
-- Exportiert, damit WHO_Teleport (F7) dieselbe Beschreibung nutzen kann.
function WHO_ItemSpawner.describeContainer(container)
    if not container then return "container=nil" end
    local ctype = safe(function() return container:getType() end) or "?"
    local items = safe(function() return container:getItems() end)
    local count = (items and items:size()) or 0

    local objIdx, sprite, sx, sy, sz = "?", "?", "?", "?", "?"
    local obj = safe(function() return container:getParent() end)
    if obj then
        objIdx = safe(function() return obj:getObjectIndex() end) or "?"
        local spr = safe(function() return obj:getSprite() end)
        if spr then sprite = safe(function() return spr:getName() end) or "?" end
        local sq = safe(function() return obj:getSquare() end)
        if sq then
            sx = safe(function() return sq:getX() end) or "?"
            sy = safe(function() return sq:getY() end) or "?"
            sz = safe(function() return sq:getZ() end) or "?"
        end
    end

    return "type=" .. ctype .. " inst=" .. tostring(container)
        .. " obj#" .. tostring(objIdx) .. " sprite=" .. tostring(sprite)
        .. " sq=" .. tostring(sx) .. "/" .. tostring(sy) .. "/" .. tostring(sz)
        .. " items=" .. count
end

-- Items auf den Boden des Tiles legen (Tile-Mitte = 0.5/0.5 relativer Offset).
local function dropOnFloor(square, itemType, count)
    for _ = 1, count do
        square:AddWorldInventoryItem(itemType, 0.5, 0.5, 0.0)
    end
end

-- Items in container legen und VERIFIZIEREN, dass sie ankamen: getItems():size()
-- vorher/nachher vergleichen (AddItem-Rückgabe wird zusätzlich geloggt — sie
-- wurde früher ignoriert, daher konnten Items still verschwinden). Merkt sich den
-- Container fürs F7-Report. Gibt true zurück, wenn die Anzahl tatsächlich stieg.
local function addItemsVerified(container, itemType, count, x, y, z)
    local items  = safe(function() return container:getItems() end)
    local before = (items and items:size()) or 0
    local lastReturn
    for _ = 1, count do
        lastReturn = container:AddItem(itemType)
    end
    items = safe(function() return container:getItems() end)
    local after = (items and items:size()) or 0
    local ok = after > before

    WHO_ItemSpawner.lastSpawnDebug = {
        containerId = tostring(container),
        itemType    = itemType,
        x = x, y = y, z = z,
        ok = ok,
    }

    print("[WHO] Spawner: add " .. count .. "x " .. itemType
        .. " -> " .. WHO_ItemSpawner.describeContainer(container)
        .. " | before=" .. before .. " after=" .. after
        .. " AddItem=" .. (lastReturn ~= nil and "non-nil" or "nil"))
    return ok
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

    if container and addItemsVerified(container, itemType, count, x, y, z) then
        print("[WHO] Spawner: " .. count .. "x " .. itemType .. " into container at "
            .. x .. "/" .. y .. "/" .. z)
        return true
    end

    -- Kein Container ODER AddItem hat nichts hinzugefügt -> auf den Boden.
    if container then
        print("[WHO] Spawner: container AddItem added nothing at " .. x .. "/" .. y .. "/" .. z
            .. " - dropping on floor instead")
    end
    dropOnFloor(square, itemType, count)
    print("[WHO] Spawner: " .. count .. "x " .. itemType .. " on floor at "
        .. x .. "/" .. y .. "/" .. z
        .. (container and " (container add failed)" or " (no container found)"))
    return true
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

    local container, dist, foundTypes, matches =
        findNearestContainerOfType(cell, x, y, z, preferredContainerType, searchRadius)

    -- D2: ALLE passenden Container im Radius protokollieren (nicht nur den
    -- nächsten) - so sieht man sofort, ob mehrere existieren (Mehrdeutigkeit).
    if matches and #matches > 0 then
        print("[WHO] Spawner: " .. #matches .. " '" .. preferredContainerType
            .. "' container(s) within " .. searchRadius .. " tiles of ("
            .. x .. "," .. y .. "," .. z .. "):")
        for _, m in ipairs(matches) do
            print("[WHO]   - dist " .. m.dist .. " @ " .. m.x .. "/" .. m.y .. "/" .. m.z
                .. " | " .. WHO_ItemSpawner.describeContainer(m.container))
        end
    end

    if container and addItemsVerified(container, itemType, count, x, y, z) then
        print("[WHO] Spawned " .. count .. "x " .. itemType .. " in " .. preferredContainerType
            .. " at (" .. x .. "," .. y .. "," .. z .. ") - distance " .. dist .. " from target")
        return true
    end

    if container then
        -- Container gefunden, aber AddItem hat nichts hinzugefügt (H1) -> Boden.
        print("[WHO] AddItem failed (returned nil / count unchanged) in " .. preferredContainerType
            .. " at (" .. x .. "," .. y .. "," .. z .. ") - falling back to floor drop")
        local square = cell:getGridSquare(x, y, z)
        if square then
            dropOnFloor(square, itemType, count)
            print("[WHO] Spawner: " .. count .. "x " .. itemType .. " on floor at "
                .. x .. "/" .. y .. "/" .. z .. " (container add failed)")
            return true
        end
        return false
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