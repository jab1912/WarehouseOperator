-- Warehouse Operator - Debug Hotkeys
-- Test-Tools fürs Entwickeln: Teleport, Position, Quest-State

local WHO_Config      = require "WarehouseOperator/WHO_Config"
local WHO_QuestState  = require "WarehouseOperator/WHO_QuestState"
local WHO_ItemSpawner = require "WarehouseOperator/WHO_ItemSpawner"

if not WHO_Config.DEBUG.ENABLED then
    return
end

-- Tasten-Codes (LWJGL)
local KEY_CONTAINER_REP = 65  -- F7
local KEY_TELEPORT_GAS  = 66  -- F8
local KEY_TELEPORT      = 67  -- F9
local KEY_LOG_POSITION  = 68  -- F10
local KEY_ACCEPT_QUEST  = 73  -- Numpad 9
local KEY_LOG_STATE     = 82  -- Numpad 0

local function logPosition(prefix)
    local player = getPlayer()
    if not player then return end
    local x = math.floor(player:getX())
    local y = math.floor(player:getY())
    local z = math.floor(player:getZ())
    print("[WHO] " .. prefix .. ": x=" .. x .. ", y=" .. y .. ", z=" .. z)
end

local function teleportToSpawn()
    local player = getPlayer()
    if not player then return end

    logPosition("Teleport from")

    local pos = WHO_Config.WAREHOUSE.SPAWN_POS
    player:setPosition(pos.x, pos.y, pos.z)
    player:setLastX(pos.x)
    player:setLastY(pos.y)
    player:setLastZ(pos.z)

    print("[WHO] Teleported to SPAWN_POS: x=" .. pos.x .. ", y=" .. pos.y)
end

-- Temp Q1-Test-Ziel: Tankstellen-General-Store an der Kasse. Leicht versetzt vom
-- WHO_Q001-Item-Spawn, damit man nicht auf dem Container landet. Lokales Literal
-- (nicht WHO_Config), weil es ein Wegwerf-Dev-Tool ist.
local GAS_STATION_POS = { x = 12744, y = 5047, z = 0 }

local function teleportToGasStation()
    local player = getPlayer()
    if not player then return end

    logPosition("Teleport from")

    local pos = GAS_STATION_POS
    player:setPosition(pos.x, pos.y, pos.z)
    player:setLastX(pos.x)
    player:setLastY(pos.y)
    player:setLastZ(pos.z)

    print("[WHO] Teleported to GAS_STATION: x=" .. pos.x .. ", y=" .. pos.y)
end

local function acceptTestQuest()
    local player = getPlayer()
    if not player then return end
    WHO_QuestState.acceptQuest(player, "WHO_Q001")
end

local function logQuestState()
    local player = getPlayer()
    if not player then return end

    local status = WHO_QuestState.getCurrentStatus(player)
    local quest  = WHO_QuestState.getCurrentQuest(player)

    print("[WHO] === Quest State ===")
    print("[WHO]   Status: " .. status)
    if quest then
        print("[WHO]   Active Quest: " .. quest.name .. " (" .. quest.id .. ")")
        print("[WHO]   Requirement: " .. quest.requirements[1].count .. "x " .. quest.requirements[1].itemType)
    else
        print("[WHO]   No active quest")
    end
end

-- F7 Container Report: dumpt alle Container auf dem Spieler-Tile + 8 Nachbarn
-- (Tile, Objekt-Index, Sprite, Typ, Instanz, Item-Anzahl + Item-Fulltypes) und
-- markiert pro Container MATCH/DIFFERENT gegen den zuletzt gespawnten Container.
-- So lässt sich prüfen, ob das gespawnte Item im selben Container landet, den man
-- per Rechtsklick öffnet (siehe spawnInContainerType-Diagnose).
local function containerReport()
    local player = getPlayer()
    if not player then return end
    local cell = getCell()
    if not cell then return end

    local px = math.floor(player:getX())
    local py = math.floor(player:getY())
    local pz = math.floor(player:getZ())

    print("[WHO] === Container Report @ " .. px .. "/" .. py .. "/" .. pz
        .. " (player tile + 8 neighbors) ===")

    local last = WHO_ItemSpawner.lastSpawnDebug
    if last and last.containerId then
        print("[WHO]   last spawn target: " .. tostring(last.containerId)
            .. " (" .. tostring(last.itemType) .. " @ " .. last.x .. "/" .. last.y .. "/" .. last.z
            .. ", ok=" .. tostring(last.ok) .. ")")
    else
        print("[WHO]   (no spawn recorded this session)")
    end

    local found = 0
    for dx = -1, 1 do
        for dy = -1, 1 do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            if sq then
                local objects = sq:getObjects()
                if objects then
                    -- Java-ArrayList: 0-indiziert!
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        local container = obj and obj:getContainer()
                        if container then
                            found = found + 1
                            local verdict = ""
                            if last and last.containerId then
                                verdict = (tostring(container) == last.containerId)
                                    and "  <<< MATCH (last spawn target)"
                                    or  "  (different from last spawn target)"
                            end
                            print("[WHO]   " .. WHO_ItemSpawner.describeContainer(container) .. verdict)
                            local items = container:getItems()
                            if items and items:size() > 0 then
                                for k = 0, items:size() - 1 do
                                    local it = items:get(k)
                                    if it then
                                        print("[WHO]       - " .. it:getFullType())
                                    end
                                end
                            else
                                print("[WHO]       (empty)")
                            end
                        end
                    end
                end
            end
        end
    end

    if found == 0 then
        print("[WHO]   no containers on player tile or neighbors")
    end
    print("[WHO] === end container report ===")
end

local function onKeyPressed(key)
    if key == KEY_CONTAINER_REP then
        containerReport()
    elseif key == KEY_TELEPORT_GAS then
        teleportToGasStation()
    elseif key == KEY_TELEPORT then
        teleportToSpawn()
    elseif key == KEY_LOG_POSITION then
        logPosition("Current position")
    elseif key == KEY_ACCEPT_QUEST then
        acceptTestQuest()
    elseif key == KEY_LOG_STATE then
        logQuestState()
    end
end

Events.OnKeyPressed.Add(onKeyPressed)

print("[WHO] Debug hotkeys loaded:")
print("[WHO]   F7         = container report (tile + neighbors)")
print("[WHO]   F8         = teleport to GAS_STATION (Q1)")
print("[WHO]   F9         = teleport to SPAWN_POS")
print("[WHO]   F10        = log current position")
print("[WHO]   Numpad 9   = accept test quest WHO_Q001")
print("[WHO]   Numpad 0   = log quest state")