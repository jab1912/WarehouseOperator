-- Warehouse Operator - Hello World + Player Position Logger
-- Phase 1.1: lernt getPlayer() und Koordinaten

local WHO_Config = require "WarehouseOperator/WHO_Config"

print("======================================")
print("[WHO] Warehouse Operator loaded successfully!")
print("[WHO] Mod version: " .. WHO_Config.MOD.VERSION)
print("[WHO] Build target: 42.18.0")
print("======================================")

-- Hook auf OnGameStart:
-- Feuert wenn der Spieler einen Save lädt oder neu startet
Events.OnGameStart.Add(function()
    print("[WHO] OnGameStart fired - player is now in-game")

    -- TEMP DIAGNOSTIC (remove after test): is our custom item registered?
    -- subject = Base.WHO_PumpKey (NIL => 42/media/scripts never scanned by
    -- ScriptManager); control = Base.TinnedBeans (vanilla, must be REGISTERED to
    -- prove the probe itself works). Placed here because HelloWorld is proven to
    -- load and OnGameStart is proven to fire (the OnGameBoot probe printed nothing).
    local sm = getScriptManager()
    if sm then
        local pk = sm:getItem("Base.WHO_PumpKey")
        local tb = sm:getItem("Base.TinnedBeans")
        print("[WHO] ScriptProbe: Base.WHO_PumpKey  -> " .. (pk ~= nil and "REGISTERED" or "NIL (not loaded)"))
        print("[WHO] ScriptProbe: Base.TinnedBeans  -> " .. (tb ~= nil and "REGISTERED" or "NIL"))
    else
        print("[WHO] ScriptProbe: getScriptManager() == nil at OnGameStart")
    end

    -- Hol dir das Spieler-Objekt
    -- getPlayer() ist eine freie Funktion (kein Punkt/Doppelpunkt davor)
    -- Sie gibt das IsoPlayer-Objekt zurück
    local player = getPlayer()

    -- Sicherheits-Check: wenn aus irgendeinem Grund kein Player da ist, abbrechen
    -- (sollte nicht passieren, aber defensiv programmieren ist gut)
    if not player then
        print("[WHO] WARNING: no player found in OnGameStart")
        return
    end

    -- Koordinaten abfragen
    -- :getX() :getY() :getZ() sind Methoden auf dem IsoPlayer-Objekt
    -- (Doppelpunkt, weil Methodenaufruf - übergibt 'self' automatisch)
    -- Wir runden auf ganze Zahlen, weil PZ intern Float-Werte verwendet
    --   und wir es übersichtlich im Log haben wollen
    local x = math.floor(player:getX())
    local y = math.floor(player:getY())
    local z = math.floor(player:getZ())

    -- Im Log ausgeben.
    -- '..' verkettet Strings. Zahlen werden automatisch zu Strings konvertiert.
    print("[WHO] Player position: x=" .. x .. ", y=" .. y .. ", z=" .. z)
end)

-- ===================================================================
-- Phase 2.1 Test: Quest-Definitionen laden und ausgeben
-- ===================================================================
local WHO_Quests = require "WarehouseOperator/WHO_Quests"
print("[WHO] Quest module loaded. Total quests: " .. #WHO_Quests.list)

local firstQuest = WHO_Quests.getById("WHO_Q001")
if firstQuest then
    print("[WHO] First quest: " .. firstQuest.name)
    print("[WHO]   Tier: " .. firstQuest.tier)
    print("[WHO]   Required: " .. firstQuest.requirements[1].count .. "x " .. firstQuest.requirements[1].itemType)
end

