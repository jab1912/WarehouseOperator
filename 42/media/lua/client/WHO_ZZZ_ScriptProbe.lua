-- Warehouse Operator - TEMP DIAGNOSTIC (remove after test)
-- =========================================================================
-- Probes the ScriptManager at boot to confirm whether our custom item actually
-- registered. ZZZ-prefix => loads after every other client file; OnGameBoot
-- fires once scripts have been parsed.
--   subject  Base.WHO_PumpKey  -> NIL means 42/media/scripts was never scanned.
--   control  Base.TinnedBeans  -> vanilla; REGISTERED proves the probe itself works
--            (and the TinnedBeans diagnostic swap is still in place).

local function reportItem(label, fullType)
    local sm = getScriptManager()
    if not sm then
        print("[WHO] ScriptProbe: getScriptManager() == nil (cannot check " .. fullType .. ")")
        return
    end
    local ok, item = pcall(function() return sm:getItem(fullType) end)
    if not ok then
        print("[WHO] ScriptProbe: " .. label .. " " .. fullType .. " -> getItem() ERROR")
        return
    end
    print("[WHO] ScriptProbe: " .. label .. " " .. fullType .. " -> "
        .. (item ~= nil and "REGISTERED" or "NIL (not loaded)"))
end

local function probe()
    print("[WHO] ===== SCRIPT PROBE (temp diagnostic) =====")
    reportItem("subject", "Base.WHO_PumpKey")
    reportItem("control", "Base.TinnedBeans")
    print("[WHO] ===== end script probe =====")
end

Events.OnGameBoot.Add(probe)
