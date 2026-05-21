-- Warehouse Operator - Test-Teleport + Position-Logger
-- Phase 1.2: per Tastendruck zu fester Koordinate springen, plus Position ablesen
-- Wird in Phase 1.4 wieder entfernt, ist nur fürs Entwickeln da

-- Ziel-Koordinaten (Warehouse-Eingang in Louisville)
local TARGET_X = 12606
local TARGET_Y = 4711
local TARGET_Z = 0

-- Tasten-Codes (LWJGL-Konstanten)
local TELEPORT_KEY = 67  -- F9
local LOG_POS_KEY  = 68  -- F10

local function logPosition(prefix)
    local player = getPlayer()
    if not player then return end
    local x = math.floor(player:getX())
    local y = math.floor(player:getY())
    local z = math.floor(player:getZ())
    print("[WHO] " .. prefix .. ": x=" .. x .. ", y=" .. y .. ", z=" .. z)
end

local function teleportToTarget()
    local player = getPlayer()
    if not player then return end

    logPosition("Teleport from")

    -- Saubere B42-API: setPosition(x, y, z) auf IsoMovingObject
    -- Das ist die offizielle Methode und kümmert sich intern um alle
    -- nötigen Side-Effects (Last-Position, Square-Update, etc.)
    player:setPosition(TARGET_X, TARGET_Y, TARGET_Z)

    -- "Last"-Position auch updaten, damit das Movement-System nicht
    -- denkt wir wären gerade auf einem riesigen Weg unterwegs (Pathing)
    player:setLastX(TARGET_X)
    player:setLastY(TARGET_Y)
    player:setLastZ(TARGET_Z)

    print("[WHO] Teleported to: x=" .. TARGET_X .. ", y=" .. TARGET_Y)
end

local function onKeyPressed(key)
    if key == TELEPORT_KEY then
        teleportToTarget()
    elseif key == LOG_POS_KEY then
        logPosition("Current position")
    end
end

Events.OnKeyPressed.Add(onKeyPressed)

print("[WHO] Teleport module loaded.")
print("[WHO]   F9  = teleport to target (" .. TARGET_X .. "/" .. TARGET_Y .. ")")
print("[WHO]   F10 = log current position")