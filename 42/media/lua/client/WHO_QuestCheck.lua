-- Warehouse Operator - Quest Progress Check Loop
-- Phase 2.4: Prüft jede Spielminute ob die Quest-Requirements erfüllt sind.
-- Wenn ja: Quest-Status auf COMPLETE setzen.

local WHO_Config     = require "WarehouseOperator/WHO_Config"
local WHO_QuestState = require "WarehouseOperator/WHO_QuestState"

-- =========================================================================
-- HELPER: Extraction-Container finden
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
-- HELPER: Items eines Typs zählen
-- =========================================================================

local function countItemsOfType(container, itemType)
    if not container then return 0 end

    local count = 0
    local items = container:getItems()
    if not items then return 0 end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getFullType() == itemType then
            count = count + 1
        end
    end

    return count
end

-- =========================================================================
-- CORE: Requirements prüfen
-- =========================================================================

local function checkRequirements(container, quest)
    for _, req in ipairs(quest.requirements) do
        local found = countItemsOfType(container, req.itemType)
        if found < req.count then
            return false, req.itemType, found, req.count
        end
    end
    return true
end

-- =========================================================================
-- MAIN: wird jede Spielminute aufgerufen
-- =========================================================================

local function onEveryOneMinute()
    local player = getPlayer()
    if not player then return end

    if WHO_QuestState.getCurrentStatus(player) ~= WHO_QuestState.STATUS.ACTIVE then
        return
    end

    local quest = WHO_QuestState.getCurrentQuest(player)
    if not quest then return end

    local container = getExtractionContainer()
    if not container then
        print("[WHO] Quest-Check: extraction container not found at EXTRACTION_POS!")
        return
    end

    local complete, missingType, found, required = checkRequirements(container, quest)

    if complete then
        print("[WHO] Quest requirements MET! Marking complete.")
        WHO_QuestState.markComplete(player)
    else
        print("[WHO] Quest-Check: need " .. (required - found) .. " more " .. missingType
            .. " (have " .. found .. "/" .. required .. ")")
    end
end

Events.EveryOneMinute.Add(onEveryOneMinute)

print("[WHO] Quest check loop loaded (runs every game minute).")