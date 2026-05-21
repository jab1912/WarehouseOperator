-- Warehouse Operator - Hello World + Player Position Logger
-- Phase 1.1: lernt getPlayer() und Koordinaten

print("======================================")
print("[WHO] Warehouse Operator loaded successfully!")
print("[WHO] Mod version: 0.0.2")
print("[WHO] Build target: 42.18.0")
print("======================================")

-- Hook auf OnGameStart:
-- Feuert wenn der Spieler einen Save lädt oder neu startet
Events.OnGameStart.Add(function()
    print("[WHO] OnGameStart fired - player is now in-game")

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