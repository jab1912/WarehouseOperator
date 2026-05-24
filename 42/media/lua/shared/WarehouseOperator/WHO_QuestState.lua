-- Warehouse Operator - Quest State Management
-- Verwaltet den Quest-Zustand pro Spieler.
-- Nutzt IsoPlayer:getModData() für Persistenz über Save/Load.

local WHO_Quests = require "WarehouseOperator/WHO_Quests"

local WHO_QuestState = {}

WHO_QuestState.STATUS = {
    IDLE       = "idle",
    ACTIVE     = "active",
    COMPLETE   = "complete",
}

local function ensureModData(player)
    if not player then return nil end   -- defensiv: getPlayer() kann z.B. beim Laden nil liefern
    local modData = player:getModData()

    if not modData.WHO then
        modData.WHO = {
            currentQuestId = nil,
            currentStatus  = WHO_QuestState.STATUS.IDLE,
            completedCount = 0,
            operatorNumber = 1,
            flags          = {},
        }
        print("[WHO] ModData initialized for player")
    end

    return modData.WHO
end

function WHO_QuestState.getCurrentQuest(player)
    local state = ensureModData(player)
    if not state or not state.currentQuestId then
        return nil
    end
    return WHO_Quests.getById(state.currentQuestId)
end

function WHO_QuestState.getCurrentStatus(player)
    local state = ensureModData(player)
    if not state then return WHO_QuestState.STATUS.IDLE end
    return state.currentStatus
end

function WHO_QuestState.canAcceptQuest(player)
    local state = ensureModData(player)
    if not state then return false end
    return state.currentStatus == WHO_QuestState.STATUS.IDLE
end

function WHO_QuestState.acceptQuest(player, questId)
    local state = ensureModData(player)
    if not state then return false end

    if state.currentStatus ~= WHO_QuestState.STATUS.IDLE then
        print("[WHO] Cannot accept quest: another quest is already active (" .. state.currentQuestId .. ")")
        return false
    end

    local quest = WHO_Quests.getById(questId)
    if not quest then
        print("[WHO] Cannot accept quest: id '" .. questId .. "' not found")
        return false
    end

    state.currentQuestId = questId
    state.currentStatus  = WHO_QuestState.STATUS.ACTIVE
    print("[WHO] Quest accepted: " .. quest.name .. " (" .. questId .. ")")

    -- Quest-Items in der Welt spawnen
    local WHO_Config      = require "WarehouseOperator/WHO_Config"
    local WHO_ItemSpawner = require "WarehouseOperator/WHO_ItemSpawner"

    local spawnPos = WHO_Config.QUEST_ITEM_SPAWNS[questId]
    if spawnPos then
        WHO_ItemSpawner.spawnBatchAt(spawnPos.x, spawnPos.y, spawnPos.z, quest.requirements)
    else
        print("[WHO] No spawn position defined for quest " .. questId .. " - items not spawned")
    end

    return true
end

function WHO_QuestState.markComplete(player)
    local state = ensureModData(player)
    if not state then return false end

    if state.currentStatus ~= WHO_QuestState.STATUS.ACTIVE then
        print("[WHO] Cannot mark complete: no active quest")
        return false
    end

    state.currentStatus = WHO_QuestState.STATUS.COMPLETE
    print("[WHO] Quest marked complete: " .. state.currentQuestId)
    return true
end

function WHO_QuestState.finishQuest(player)
    local state = ensureModData(player)
    if not state then return false end

    if state.currentStatus ~= WHO_QuestState.STATUS.COMPLETE then
        print("[WHO] Cannot finish quest: not in COMPLETE state")
        return false
    end

    local questId = state.currentQuestId
    state.currentQuestId = nil
    state.currentStatus  = WHO_QuestState.STATUS.IDLE
    state.completedCount = state.completedCount + 1

    print("[WHO] Quest finished: " .. questId .. " (total completed: " .. state.completedCount .. ")")
    return true
end

-- =========================================================================
-- FLAGS (System-Unlocks, persistiert in ModData)
-- =========================================================================
-- Quest-Rewards können neben Items auch ModData-Flags setzen (siehe
-- quest.rewardFlags + WHO_RewardDispatcher). Phase 5b liest z.B.
-- "supply_order_unlocked", um das SUPPLY-ORDER-Menü freizuschalten.

function WHO_QuestState.setFlag(player, flag)
    local state = ensureModData(player)
    if not state then return end
    state.flags = state.flags or {}   -- Migration: alte Saves ohne flags-Tabelle
    state.flags[flag] = true
    print("[WHO] Flag set: " .. flag)
end

function WHO_QuestState.hasFlag(player, flag)
    local state = ensureModData(player)
    if not state then return false end
    return state.flags ~= nil and state.flags[flag] == true
end

return WHO_QuestState