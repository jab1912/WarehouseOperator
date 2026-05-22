-- Warehouse Operator - Quest Definitions
-- Hier liegen ALLE Quests als statische Daten.
-- Kein Verhalten in dieser Datei - nur Definitionen.
-- Andere Module greifen via require darauf zu.

local WHO_Quests = {}

-- =========================================================================
-- QUEST DEFINITIONS
-- =========================================================================
--
-- Jede Quest hat folgende Felder:
--   id           : eindeutiger String, beginnt mit "WHO_Q" + 3-stellige Nummer
--   name         : Anzeigename (wird später im Terminal angezeigt)
--   description  : Mission-Briefing-Text
--   tier         : 1=easy, 2=medium, 3=hard
--   requirements : Liste von Items die in die Extraction-Kiste müssen
--                  Format: { { itemType="Base.X", count=N }, ... }
--   rewards      : Liste von Items die als Belohnung erscheinen
--                  Format: { { itemType="Base.X", count=N }, ... }
--
-- WICHTIG: itemType MUSS exakt der PZ-Item-ID entsprechen.
-- "Base.TinnedBeans" etc. — siehe scripts/items.txt der Vanilla-Files
-- oder PZWiki. Falsche IDs führen zu silent failures!
--
-- =========================================================================

WHO_Quests.list = {
    -- ---------------------------------------------------------------------
    -- TIER 1: Beginner Quests
    -- ---------------------------------------------------------------------
    {
        id = "WHO_Q001",
        name = "First Delivery",
        description = "Logistics needs rations. Drop 5 cans of beans into the extraction crate.",
        tier = 1,
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

-- Findet eine Quest anhand ihrer ID
-- Gibt die Quest-Table zurück, oder nil wenn nicht gefunden
function WHO_Quests.getById(questId)
    for _, quest in ipairs(WHO_Quests.list) do
        if quest.id == questId then
            return quest
        end
    end
    return nil
end

-- Liefert alle Quests eines bestimmten Tiers
-- Gibt eine Liste zurück (kann leer sein)
function WHO_Quests.getByTier(tier)
    local result = {}
    for _, quest in ipairs(WHO_Quests.list) do
        if quest.tier == tier then
            table.insert(result, quest)
        end
    end
    return result
end

return WHO_Quests