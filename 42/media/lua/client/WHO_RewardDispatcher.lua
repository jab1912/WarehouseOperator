-- Warehouse Operator - Reward Dispatcher
-- Phase 4a: Verteilt Belohnungen wenn der Spieler die Extraction am Terminal bestätigt.
-- Tauscht Required-Items gegen Reward-Items in der Extraction-Kiste.

local WHO_Config     = require "WarehouseOperator/WHO_Config"
local WHO_QuestState = require "WarehouseOperator/WHO_QuestState"

local WHO_RewardDispatcher = {}

-- =========================================================================
-- HELPER: Extraction-Container holen
-- =========================================================================

local function getExtractionContainer()
    local pos = WHO_Config.WAREHOUSE.EXTRACTION_POS

    local cell = getCell()
    if not cell then return nil end

    local square = cell:getGridSquare(pos.x, pos.y, pos.z)
    if not square then return nil end

    local objects = square:getObjects()
    if not objects then return nil end

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
-- HELPER: Required-Items aus Container entfernen
-- =========================================================================

local function removeItemsOfType(container, itemType, count)
    if not container then return 0 end

    local removed = 0
    local items = container:getItems()
    if not items then return 0 end

    -- Rückwärts iterieren weil wir während des Loops entfernen
    -- (Vorwärts würde Indizes verschieben und Items überspringen)
    for i = items:size() - 1, 0, -1 do
        if removed >= count then break end

        local item = items:get(i)
        if item and item:getFullType() == itemType then
            container:Remove(item)
            removed = removed + 1
        end
    end

    return removed
end

-- =========================================================================
-- HELPER: Rewards in Container legen
-- =========================================================================

local function addRewardsToContainer(container, rewards)
    if not container then return 0 end

    local added = 0
    for _, reward in ipairs(rewards) do
        for n = 1, reward.count do
            container:AddItem(reward.itemType)
            added = added + 1
        end
    end

    return added
end

-- =========================================================================
-- PUBLIC: Reward-Dispatch
-- Wird vom Context-Menu aufgerufen wenn Spieler "Confirm Extraction" klickt.
-- =========================================================================

function WHO_RewardDispatcher.dispatch(player)
    if WHO_QuestState.getCurrentStatus(player) ~= WHO_QuestState.STATUS.COMPLETE then
        print("[WHO] Reward: cannot dispatch - quest is not in COMPLETE state")
        return false
    end

    local quest = WHO_QuestState.getCurrentQuest(player)
    if not quest then
        print("[WHO] Reward: no quest to dispatch")
        return false
    end

    local container = getExtractionContainer()
    if not container then
        print("[WHO] Reward: extraction container not found!")
        return false
    end

    -- Schritt 1: Required-Items rausnehmen (Truck holt Loot ab)
    print("[WHO] Reward: removing extracted items...")
    for _, req in ipairs(quest.requirements) do
        local removed = removeItemsOfType(container, req.itemType, req.count)
        print("[WHO]   Removed " .. removed .. "/" .. req.count .. " " .. req.itemType)
    end

    -- Schritt 2: Reward-Items reinlegen (Supply Drop)
    print("[WHO] Reward: adding reward items...")
    local rewardCount = addRewardsToContainer(container, quest.rewards)
    print("[WHO]   Added " .. rewardCount .. " reward items total")

    -- Schritt 3: Quest finalisieren (Status zurück auf IDLE)
    WHO_QuestState.finishQuest(player)

    print("[WHO] Extraction confirmed. Convoy received pickup, supplies delivered.")
    return true
end

return WHO_RewardDispatcher