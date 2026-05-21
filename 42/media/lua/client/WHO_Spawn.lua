-- Warehouse Operator - Forced Spawn + Starting Equipment
-- Phase 1.4: Bei neuem Spiel wird der Spieler zur Warehouse-SPAWN_POS teleportiert
--            und erhält Basis-Equipment.
--            WICHTIG: Hängt an OnNewGame, NICHT OnGameStart.
--            Soll nur EINMAL pro Save-Erstellung feuern, nicht bei jedem Save-Laden.

local WHO_Config = require "WarehouseOperator/WHO_Config"

-- Items die der Operator beim Start im Inventar hat
-- Format: { itemType = "Base.ID", count = N }
local STARTER_KIT = {
    { itemType = "Base.Pistol",     count = 1 },  -- M9 Pistole (wird primary-handed)
    { itemType = "Base.9mmClip",    count = 1 },  -- 1 leeres Magazin
    { itemType = "Base.Bullets9mm", count = 30 }, -- 30 Schuss 9mm
    { itemType = "Base.Bandage",    count = 1 },  -- 1 Verband
    { itemType = "Base.Crowbar",    count = 1 },  -- Brecheisen (wird secondary-handed)
}

-- Welches Item soll der Operator beim Spawn equipped haben?
-- Wir behalten uns die IDs, damit wir sie nach dem Hinzufügen direkt equippen können.
local PRIMARY_WEAPON_ID   = "Base.Pistol"
local SECONDARY_WEAPON_ID = "Base.Crowbar"

local function teleportToSpawn(player)
    local pos = WHO_Config.WAREHOUSE.SPAWN_POS

    player:setPosition(pos.x, pos.y, pos.z)
    player:setLastX(pos.x)
    player:setLastY(pos.y)
    player:setLastZ(pos.z)

    print("[WHO] Forced spawn: teleported to SPAWN_POS x=" .. pos.x .. ", y=" .. pos.y)
end

local function giveStarterKit(player)
    local inventory = player:getInventory()
    if not inventory then
        print("[WHO] WARNING: player inventory is nil, skipping starter kit")
        return
    end

    -- Über die STARTER_KIT-Liste iterieren und Items hinzufügen.
    -- AddItem gibt das frisch erzeugte InventoryItem zurück, also können wir
    -- es uns "merken" für späteres Equippen.
    local equipTargets = {}  -- merkt sich Items die wir equippen wollen

    for i, entry in ipairs(STARTER_KIT) do
        for n = 1, entry.count do
            local item = inventory:AddItem(entry.itemType)

            -- Wenn das Item eines unserer "soll equipped sein"-Items ist
            -- und wir noch keine Referenz davon haben, merken
            if item and entry.itemType == PRIMARY_WEAPON_ID and not equipTargets.primary then
                equipTargets.primary = item
            elseif item and entry.itemType == SECONDARY_WEAPON_ID and not equipTargets.secondary then
                equipTargets.secondary = item
            end
        end
        print("[WHO] Starter kit: added " .. entry.count .. "x " .. entry.itemType)
    end

    -- Items in die Hände nehmen
    -- setPrimaryHandItem = "rechte Hand", setSecondaryHandItem = "linke Hand"
    -- (Convention für Rechtshänder; Pistole rechts, Crowbar links)
    if equipTargets.primary then
        player:setPrimaryHandItem(equipTargets.primary)
        print("[WHO] Equipped primary: " .. PRIMARY_WEAPON_ID)
    end
    if equipTargets.secondary then
        player:setSecondaryHandItem(equipTargets.secondary)
        print("[WHO] Equipped secondary: " .. SECONDARY_WEAPON_ID)
    end
end

Events.OnNewGame.Add(function()
    print("[WHO] OnNewGame fired - setting up new operator")

    local player = getPlayer()
    if not player then
        print("[WHO] WARNING: no player found in OnNewGame")
        return
    end

    teleportToSpawn(player)
    giveStarterKit(player)

    print("[WHO] New operator ready for deployment.")
end)

print("[WHO] Spawn module loaded (hooked to OnNewGame).")