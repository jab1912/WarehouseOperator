-- Warehouse Operator - Debug Context Menu for Quest Acceptance
-- Phase 2.3: Rechtsklick auf den Tisch im Bürozimmer → "Accept Mission [DEBUG]"
-- Wird in Phase 3 durch das richtige Terminal-UI ersetzt.

local WHO_Config     = require "WarehouseOperator/WHO_Config"
local WHO_Quests     = require "WarehouseOperator/WHO_Quests"
local WHO_QuestState = require "WarehouseOperator/WHO_QuestState"

-- Radius in Tiles um TERMINAL_POS, in dem das Menü angezeigt wird.
-- 2 Tiles = 1.5m Reichweite ungefähr.
local INTERACTION_RADIUS = 2

-- =========================================================================
-- HELPER: Check ob der geklickte Square nahe genug am Terminal ist
-- =========================================================================
local function isNearTerminal(worldObjects)
    if not worldObjects or #worldObjects == 0 then
        return false
    end

    -- Wir nehmen das erste Objekt um den Square zu finden
    local firstObj = worldObjects[1]
    if not firstObj then return false end

    local square = firstObj:getSquare()
    if not square then return false end

    local clickX = square:getX()
    local clickY = square:getY()
    local clickZ = square:getZ()

    local termPos = WHO_Config.WAREHOUSE.TERMINAL_POS

    -- Z muss exakt stimmen (gleicher Stockwerk)
    if clickZ ~= termPos.z then return false end

    -- Distanz auf X/Y-Ebene
    local dx = math.abs(clickX - termPos.x)
    local dy = math.abs(clickY - termPos.y)

    return dx <= INTERACTION_RADIUS and dy <= INTERACTION_RADIUS
end

-- =========================================================================
-- MENU ACTIONS
-- =========================================================================

-- Wird aufgerufen wenn der Spieler "Accept Mission" im Context-Menü klickt
local function onAcceptMissionClicked(worldObjects, player)
    -- Hole die erste verfügbare Quest (später: Liste anzeigen)
    -- Für Phase 2 reicht: nur Tier-1-Quests, davon die erste
    local availableQuests = WHO_Quests.getByTier(1)
    if #availableQuests == 0 then
        print("[WHO] No quests available")
        return
    end

    local firstQuest = availableQuests[1]
    WHO_QuestState.acceptQuest(player, firstQuest.id)
end

-- =========================================================================
-- CONTEXT MENU HOOK
-- =========================================================================

local function onFillContextMenu(playerIndex, context, worldObjects, test)
    -- 'test' = true bedeutet: PZ prüft nur ob das Menü später angezeigt werden würde.
    -- Wir verhalten uns gleich, aber sparen uns evtl. teure Operationen.

    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    -- Sind wir nahe genug am Terminal-Platz?
    if not isNearTerminal(worldObjects) then return end

    -- Spieler hat schon eine aktive Quest? Dann anderen Status-Text zeigen
    local status = WHO_QuestState.getCurrentStatus(player)

    if status == WHO_QuestState.STATUS.IDLE then
        -- Quest annehmen erlaubt
        context:addOption(
            "Accept Mission [DEBUG]",
            worldObjects,
            onAcceptMissionClicked,
            player
        )
    elseif status == WHO_QuestState.STATUS.ACTIVE then
        -- Schon eine Quest aktiv, nur Info anzeigen (kein Click-Handler)
        local quest = WHO_QuestState.getCurrentQuest(player)
        local label = "Active Mission: " .. (quest and quest.name or "?") .. " [DEBUG]"
        local option = context:addOption(label, worldObjects, nil)
        -- Eintrag deaktivieren (nicht klickbar)
        option.notAvailable = true
    elseif status == WHO_QuestState.STATUS.COMPLETE then
        -- Mission complete - awaiting reward (für Phase 4)
        local option = context:addOption("Mission Complete - Awaiting Reward [DEBUG]", worldObjects, nil)
        option.notAvailable = true
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillContextMenu)

print("[WHO] Debug context menu loaded (right-click near terminal table).")