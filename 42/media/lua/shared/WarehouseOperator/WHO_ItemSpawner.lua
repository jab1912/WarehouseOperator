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