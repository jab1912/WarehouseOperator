-- Warehouse Operator - Lazy Spawn Queue
-- Spawnt vorgemerkte Quest-Items (WHO_QuestState.pendingSpawns), sobald das
-- Ziel-Tile geladen ist. Notwendig, weil das Spawn-Ziel beim Quest-Accept meist
-- außerhalb der geladenen Chunks liegt (PZ streamt nur Chunks um den Spieler;
-- getGridSquare liefert dort nil). Läuft jede Spielminute, gleicher Takt wie
-- WHO_QuestCheck.

local WHO_QuestState  = require "WarehouseOperator/WHO_QuestState"
local WHO_ItemSpawner = require "WarehouseOperator/WHO_ItemSpawner"

-- Einen Pending-Eintrag tatsächlich spawnen. Mit preferredContainer via
-- spawnInContainerType (Umkreis-Suche, eigener Boden-Fallback), sonst spawnAt.
local function spawnEntry(p)
    if p.preferredContainer then
        return WHO_ItemSpawner.spawnInContainerType(
            p.itemType, p.x, p.y, p.z, p.preferredContainer, nil, p.count)
    end
    return WHO_ItemSpawner.spawnAt(p.x, p.y, p.z, p.itemType, p.count)
end

local function onEveryOneMinute()
    local player = getPlayer()
    if not player then return end

    local pending = WHO_QuestState.getPendingSpawns(player)
    if #pending == 0 then return end   -- Normalfall: nichts zu tun, billiger Early-Out

    local cell = getCell()
    if not cell then return end

    -- Rückwärts iterieren: sicheres Entfernen ohne Index-Verschiebung.
    for i = #pending, 1, -1 do
        local p = pending[i]
        -- Ziel-Tile als Readiness-Gate: ist es geladen, ist auch der Umkreis da
        -- (Spieler steht in der Nähe). Sonst diesen Tick überspringen.
        if cell:getGridSquare(p.x, p.y, p.z) then
            if spawnEntry(p) then
                WHO_QuestState.removePendingSpawn(player, i)
                print("[WHO] SpawnQueue: fulfilled " .. p.itemType .. " for " .. p.questId
                    .. " at " .. p.x .. "/" .. p.y .. "/" .. p.z)
            else
                print("[WHO] SpawnQueue: spawn failed for " .. p.itemType
                    .. " at " .. p.x .. "/" .. p.y .. "/" .. p.z .. " - keeping in queue")
            end
        end
        -- Tile nicht geladen: in der Queue lassen, nächster Tick versucht es erneut.
    end
end

Events.EveryOneMinute.Add(onEveryOneMinute)

print("[WHO] Spawn queue loaded (lazy spawn, runs every game minute).")
