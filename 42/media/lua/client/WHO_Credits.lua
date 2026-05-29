-- Warehouse Operator - WHO Credits Ledger
-- Persistenter, spielergebundener Kontostand fuer die einzige Shop-Waehrung des
-- Mods: WHO Credits. Abstrakter ModData-Wert (md.WHO_Credits), KEIN physisches
-- Item. Ueberlebt Save/Load (getModData() persistiert automatisch).
--
-- Einkommensquelle (Fusion-Washer: Kleidung -> Credits) kommt erst mit Q2
-- (Phase 5c). Bis dahin gibt es nur den Starter-Grant beim Shop-Unlock (5b,
-- Betrag TBD) und den Debug-Grant (siehe WHO_Teleport).
--
-- SCOPE (Fundament-Baustein): nur das Ledger/Konto. KEINE Shop-UI, KEIN Stock,
-- KEINE Kauf-Logik, KEINE Wasch-/Conversion-Mechanik, KEIN MP-Sync (Single-Player).

local WHO_Credits = {}

-- Stellt sicher, dass der Kontostand existiert; nil-sicher, Default 0.
-- player kann z.B. beim Laden nil sein -> defensiv abfangen (gibt dann nil
-- zurueck, die Public-API faellt auf neutrale Werte zurueck).
local function ensureBalance(player)
    if not player then return nil end
    local md = player:getModData()
    if md.WHO_Credits == nil then
        md.WHO_Credits = 0
    end
    return md
end

-- Aktueller Kontostand (Default 0).
function WHO_Credits.get(player)
    local md = ensureBalance(player)
    if not md then return 0 end
    return md.WHO_Credits
end

-- Schreibt Credits gut, gibt den neuen Kontostand zurueck.
-- Guard: nur positive Zahlen; sonst Kontostand unveraendert zurueck (kein stiller
-- Saldo-Schaden durch negative/ungueltige Betraege, z.B. bei einem Refund-Bug).
function WHO_Credits.add(player, amount)
    local md = ensureBalance(player)
    if not md then return 0 end
    if type(amount) ~= "number" or amount <= 0 then
        print("[WHO] Credits: add() rejected invalid amount (" .. tostring(amount) .. ")")
        return md.WHO_Credits
    end
    md.WHO_Credits = md.WHO_Credits + amount
    print("[WHO] Credits +" .. amount .. " -> balance " .. md.WHO_Credits)
    return md.WHO_Credits
end

-- Bucht Credits ab, WENN gedeckt. true = gebucht, false = zu wenig Guthaben.
-- Guard: nur positive Zahlen; ungueltige Betraege werden abgelehnt (return false),
-- damit ein Kauf mit kaputtem Preis nicht versehentlich Guthaben gutschreibt.
function WHO_Credits.spend(player, amount)
    local md = ensureBalance(player)
    if not md then return false end
    if type(amount) ~= "number" or amount <= 0 then
        print("[WHO] Credits: spend() rejected invalid amount (" .. tostring(amount) .. ")")
        return false
    end
    if md.WHO_Credits < amount then
        print("[WHO] Credits: insufficient funds (have " .. md.WHO_Credits
            .. ", need " .. amount .. ")")
        return false
    end
    md.WHO_Credits = md.WHO_Credits - amount
    print("[WHO] Credits -" .. amount .. " -> balance " .. md.WHO_Credits)
    return true
end

-- Setzt den Kontostand direkt (nur Debug/Tooling).
function WHO_Credits.set(player, amount)
    local md = ensureBalance(player)
    if not md then return 0 end
    md.WHO_Credits = amount or 0
    print("[WHO] Credits set to " .. md.WHO_Credits)
    return md.WHO_Credits
end

-- Init bei Spieler-Load: stellt sicher, dass das Feld existiert (neue UND
-- geladene Saves). OnGameStart feuert in beiden Faellen, sobald der Spieler in
-- der Welt ist (gleiche Konvention wie WHO_HelloWorld).
Events.OnGameStart.Add(function()
    local player = getPlayer()
    if not player then
        print("[WHO] Credits: no player on OnGameStart - balance init deferred")
        return
    end
    local balance = WHO_Credits.get(player)
    print("[WHO] Credits ledger ready. Balance: " .. balance)
end)

print("[WHO] Credits ledger loaded.")

return WHO_Credits
