-- Warehouse Operator - Quest Definitions
-- Hier liegen ALLE Quests als statische Daten.
-- Kein Verhalten in dieser Datei - nur Definitionen.

local WHO_Quests = {}

-- =========================================================================
-- QUEST DEFINITIONS
-- =========================================================================
--
-- Jede Quest hat folgende Felder:
--   id           : eindeutiger String, beginnt mit "WHO_Q" + 3-stellige Nummer
--   name         : Anzeigename
--   tier         : 1=easy, 2=medium, 3=hard
--   handler      : ID des Auftraggebers (Phase 3b.7) - aktuell nur "COMMAND" verwendet
--   briefing     : Liste von Text-Zeilen für die Codec-Conversation (Phase 3b.5)
--                  Phase 3b zeigt nur die erste Zeile als "Mission Briefing" statisch
--   description  : Kurz-Beschreibung (fallback wenn briefing leer)
--   requirements : Liste: { { itemType="Base.X", count=N }, ... }
--   rewards      : Liste: { { itemType="Base.X", count=N }, ... }
--   rewardFlags  : optionale Liste von ModData-Flag-Namen, die beim Extraction-
--                  Confirm gesetzt werden (System-Unlocks). Vom WHO_RewardDispatcher
--                  via WHO_QuestState.setFlag gesetzt. Optional.
--
-- =========================================================================

WHO_Quests.list = {
    {
        id = "WHO_Q001",
        name = "Prime the Pump",
        tier = 1,
        handler = "COMMAND",
        briefing = {
            "Operator, this is COMMAND.",
            "Before our logistics network can support you, we need a refueling point.",
            "Gas station, two clicks south. Clear it, secure the pump key, bring it back.",
            "Once that pump runs, our trucks can resupply you daily.",
            "Don't get bit. COMMAND out.",
        },
        description = "Clear the gas station south of the warehouse and recover the fuel pump key.",
        requirements = {
            { itemType = "Base.WHO_PumpKey", count = 1 },
        },
        rewards = {
            { itemType = "Base.Bullets9mm", count = 30 },
            { itemType = "Base.Bandage",    count = 3 },
        },
        -- System-Unlock: setzt das Flag beim Extraction-Confirm; das SUPPLY-ORDER-
        -- Menü (Phase 5b) liest es aus, um sich freizuschalten.
        rewardFlags = {
            "supply_order_unlocked",
        },
    },
    {
        id = "WHO_Q002",
        name = "Medical Supplies",
        tier = 1,
        handler = "COMMAND",
        briefing = {
            "Operator, this is COMMAND.",
            "Field medics report depleted trauma supplies at staging area.",
            "Acquire three bandages from any pharmacy or medical site.",
            "Deliver them to the extraction crate. Standard protocol.",
            "Don't get bit out there. COMMAND out.",
        },
        description = "Acquire 3x bandages and deliver to the extraction crate.",
        requirements = {
            { itemType = "Base.Bandage", count = 3 },
        },
        rewards = {
            { itemType = "Base.Bullets9mm", count = 20 },
            { itemType = "Base.TinnedBeans", count = 2 },
        },
    },
}

-- =========================================================================
-- HELPER FUNCTIONS
-- =========================================================================

function WHO_Quests.getById(questId)
    for _, quest in ipairs(WHO_Quests.list) do
        if quest.id == questId then
            return quest
        end
    end
    return nil
end

function WHO_Quests.getByTier(tier)
    local result = {}
    for _, quest in ipairs(WHO_Quests.list) do
        if quest.tier == tier then
            table.insert(result, quest)
        end
    end
    return result
end

-- Liefert alle Quests die der Operator aktuell annehmen kann
-- Aktuell: einfach alle. Später (Phase 5): nach Progression filtern.
function WHO_Quests.getAvailable()
    local result = {}
    for _, quest in ipairs(WHO_Quests.list) do
        table.insert(result, quest)
    end
    return result
end

return WHO_Quests