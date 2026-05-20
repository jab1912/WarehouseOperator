-- Warehouse Operator - Hello World
-- Beweist dass unser Mod sauber geladen wird

print("======================================")
print("[WHO] Warehouse Operator loaded successfully!")
print("[WHO] Mod version: 0.0.1")
print("[WHO] Build target: 42.18.0")
print("======================================")

-- Hook auf das OnGameStart-Event:
-- Feuert wenn der Spieler einen Save lädt oder neu startet
Events.OnGameStart.Add(function()
    print("[WHO] OnGameStart fired - player is now in-game")
end)