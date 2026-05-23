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
--
-- =========================================================================

WHO_Quests.list = {
    {
        id = "WHO_Q001",
        name = "First Delivery",
        tier = 1,
        handler = "COMMAND",
        briefing = {
            "Operator, this is COMMAND.",
            "Logistics personnel report critical food shortage at the depot.",
            "Acquire five units of canned beans from any source.",
            "Deliver them to the extraction crate in our facility.",
            "Standard compensation will be provided. COMMAND out.",
        },
        description = "Acquire 5x canned beans and deliver to the extraction crate.",
        requirements = {
            { itemType = "Base.TinnedBeans", count = 5 },
        },
        rewards = {
            { itemType = "Base.Bullets9mm", count = 30 },
            { itemType = "Base.Bandage",    count = 3 },
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