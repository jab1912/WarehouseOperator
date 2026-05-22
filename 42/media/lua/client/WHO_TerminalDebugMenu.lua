-- Warehouse Operator - Debug Context Menu for Quest Acceptance & Extraction & Terminal
-- Phase 2.3 + 4a + 3a: Rechtsklick am PC → state-abhängiges Menü + Terminal-Open

local WHO_Config           = require "WarehouseOperator/WHO_Config"
local WHO_Quests           = require "WarehouseOperator/WHO_Quests"
local WHO_QuestState       = require "WarehouseOperator/WHO_QuestState"
local WHO_RewardDispatcher = require "WHO_RewardDispatcher"
-- WHO_TerminalUI wird automatisch von PZ geladen (in client/ Ordner)

-- Radius in Tiles um TERMINAL_POS, in dem das Menü angezeigt wird.
local INTERACTION_RADIUS = 2

-- =========================================================================
-- HELPER
-- =========================================================================

local function isNearTerminal(worldObjects)
    if not worldObjects or #worldObjects == 0 then
        return false
    end

    local firstObj = worldObjects[1]
    if not firstObj then return false end

    local square = firstObj:getSquare()
    if not square then return false end

    local clickX = square:getX()
    local clickY = square:getY()
    local clickZ = square:getZ()

    local termPos = WHO_Config.WAREHOUSE.TERMINAL_POS

    if clickZ ~= termPos.z then return false end

    local dx = math.abs(clickX - termPos.x)
    local dy = math.abs(clickY - termPos.y)

    return dx <= INTERACTION_RADIUS and dy <= INTERACTION_RADIUS
end

-- =========================================================================
-- MENU ACTIONS
-- =========================================================================

local function onBootTerminalClicked(worldObjects, player)
    if WHO_TerminalUI and WHO_TerminalUI.openTerminal then
        WHO_TerminalUI.openTerminal(player)
    else
        print("[WHO] ERROR: WHO_TerminalUI not loaded properly!")
    end
end

local function onAcceptMissionClicked(worldObjects, player)
    local availableQuests = WHO_Quests.getByTier(1)
    if #availableQuests == 0 then
        print("[WHO] No quests available")
        return
    end

    local firstQuest = availableQuests[1]
    WHO_QuestState.acceptQuest(player, firstQuest.id)
end

local function onConfirmExtractionClicked(worldObjects, player)
    WHO_RewardDispatcher.dispatch(player)
end

-- =========================================================================
-- CONTEXT MENU HOOK
-- =========================================================================

local function onFillContextMenu(playerIndex, context, worldObjects, test)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    if not isNearTerminal(worldObjects) then return end

    context:addOption(
        "Boot Terminal",
        worldObjects,
        onBootTerminalClicked,
        player
    )

    local status = WHO_QuestState.getCurrentStatus(player)

    if status == WHO_QuestState.STATUS.IDLE then
        context:addOption(
            "Accept Mission [DEBUG]",
            worldObjects,
            onAcceptMissionClicked,
            player
        )
    elseif status == WHO_QuestState.STATUS.ACTIVE then
        local quest = WHO_QuestState.getCurrentQuest(player)
        local label = "Active Mission: " .. (quest and quest.name or "?") .. " [DEBUG]"
        local option = context:addOption(label, worldObjects, nil)
        option.notAvailable = true
    elseif status == WHO_QuestState.STATUS.COMPLETE then
        context:addOption(
            "Confirm Extraction [DEBUG]",
            worldObjects,
            onConfirmExtractionClicked,
            player
        )
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillContextMenu)

print("[WHO] Debug context menu loaded (right-click near terminal table).")