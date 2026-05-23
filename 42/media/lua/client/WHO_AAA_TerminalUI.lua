-- Warehouse Operator - Terminal UI
-- Phase 3c: Dynamisches Fenster (75% des Screens) + Anchor-basiertes Layout.
-- Datei heißt WHO_AAA_TerminalUI.lua wegen alphabetischer Lade-Reihenfolge in client/
--
-- Layout-Prinzip (siehe PROJEKTPLAN "Phase 3c"):
--   * Fenstergröße = 75% des Screens, geclamped.
--   * PZ-Fonts skalieren NICHT -> Text nutzt feste Zeilenhöhen, aber Regionen
--     werden an Kanten verankert (Header oben, Footer unten, Content dazwischen).
--   * Das Logo skaliert proportional (Textur).
--   * ACTION- und CLOSE-Button sind aneinander verankert -> kein Overlap möglich.
--   * ALLE interaktiven Geometrien leben in getXxx...Rect-Helpern, die self.width/
--     self.height lesen, damit Render UND Maus-Hit-Test synchron bleiben.

require "ISUI/ISPanel"

local WHO_Config           = require "WarehouseOperator/WHO_Config"
local WHO_Quests           = require "WarehouseOperator/WHO_Quests"
local WHO_QuestState       = require "WarehouseOperator/WHO_QuestState"
local WHO_RewardDispatcher = require "WHO_RewardDispatcher"

WHO_TerminalUI = ISPanel:derive("WHO_TerminalUI")

-- =========================================================================
-- COLOR PALETTE (DOS-Phosphor)
-- =========================================================================

local COLOR_BG          = {r=0,    g=0,    b=0,    a=1}
local COLOR_BORDER      = {r=0.2,  g=0.8,  b=0.2,  a=1}
local COLOR_TEXT_BRIGHT = {r=0.4,  g=1.0,  b=0.4,  a=1}
local COLOR_TEXT_DIM    = {r=0.15, g=0.5,  b=0.15, a=1}
local COLOR_TEXT_HOVER  = {r=0.7,  g=1.0,  b=0.7,  a=1}
local COLOR_TEXT_GRAY   = {r=0.3,  g=0.3,  b=0.3,  a=1}
local COLOR_TEXT_AMBER  = {r=1.0,  g=0.7,  b=0.0,  a=1}
local COLOR_BLOCK_ON    = {r=0.4,  g=1.0,  b=0.4,  a=1}
local COLOR_BLOCK_OFF   = {r=0.1,  g=0.3,  b=0.1,  a=1}

-- =========================================================================
-- WINDOW SIZE (dynamisch, zur Konstruktionszeit aus dem Screen berechnet)
-- =========================================================================

local WINDOW_SCALE = 0.75
local WINDOW_MIN_W = 900
local WINDOW_MIN_H = 680
local WINDOW_MAX_W = 1920   -- für 4K angehoben, damit es nicht winzig wirkt
local WINDOW_MAX_H = 1200

-- =========================================================================
-- FOOTER-LAYOUT (feste px; CLOSE unten verankert, ACTION darüber)
-- =========================================================================

local FOOTER_PAD_MIN = 36   -- Mindest-Abstand CLOSE-Unterkante -> Fenster-Unterkante
local BTN_GAP_MIN    = 44   -- Mindest-Abstand ACTION -> CLOSE
local BTN_TEXT_VPAD  = 8    -- vertikales Padding um Button-Text (Hit-Fläche)
local BTN_HIT_PAD    = 28   -- horizontales Padding um Label (Hit-Fläche; deckt Hover-Arrow ab)
-- FOOTER_PAD/BTN_GAP skalieren mit der Fensterhöhe. BACK/ACCEPT/CONFIRM/CLOSE
-- sind randlose Menü-Text-Buttons (wie das Hauptmenü): Label an fester Position,
-- "> " erscheint nur bei Hover links davon. Hit-Fläche = Textbreite + Padding.

-- =========================================================================
-- GENERIC HELPERS
-- =========================================================================

local function clampNum(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- =========================================================================
-- ASSETS
-- =========================================================================

local LOGO_TEXTURE = getTexture("media/textures/who_logo_boot.png")

-- =========================================================================
-- STATES
-- =========================================================================

local STATE_BOOTING       = "booting"
local STATE_READY         = "ready"
local STATE_MISSIONS_VIEW = "missions_view"

-- =========================================================================
-- BOOT-SEQUENZ-KONFIGURATION
-- =========================================================================

local BOOT_DURATION_MS = 4000

local BOOT_MESSAGES = {
    { atPercent = 0.00, text = "WHO TERMINAL v2.1.4 (c) 1994" },
    { atPercent = 0.10, text = "POST: Memory check... 640K OK" },
    { atPercent = 0.25, text = "Initializing tactical uplink..." },
    { atPercent = 0.40, text = "Connecting to satellite array..." },
    { atPercent = 0.55, text = "Authenticating operator credentials..." },
    { atPercent = 0.70, text = "Loading mission database..." },
    { atPercent = 0.85, text = "Synchronizing logistics network..." },
    { atPercent = 0.95, text = "Ready." },
}

-- =========================================================================
-- MAIN MENU CONFIGURATION
-- =========================================================================

local MAIN_MENU_ITEMS = {
    { label = "MISSIONS",  enabled = true,  action = "open_missions" },
    { label = "INVENTORY", enabled = false, action = "open_inventory" },
    { label = "STATUS",    enabled = false, action = "open_status" },
    { label = "SHUTDOWN",  enabled = true,  action = "shutdown" },
}

-- =========================================================================
-- LIFECYCLE
-- =========================================================================

function WHO_TerminalUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

function WHO_TerminalUI:create()
    -- Keine ISButton-Children mehr: BACK/ACCEPT/CONFIRM/CLOSE sind randlose
    -- Menü-Text-Buttons, manuell gezeichnet und per Hit-Test angesteuert.
    self.hoveredMenuIndex   = 0
    self.hoveredQuestIndex  = 0
    self.hoveredBack        = false
    self.hoveredAction      = false
    self.hoveredClose       = false
    self.selectedQuestIndex = 1
end

-- =========================================================================
-- BOOT-LOGIK
-- =========================================================================

function WHO_TerminalUI:getBootProgress()
    if self.bootStartMs == nil then return 0 end

    local elapsed = getTimestampMs() - self.bootStartMs
    local progress = elapsed / BOOT_DURATION_MS

    if progress > 1.0 then progress = 1.0 end
    return progress
end

function WHO_TerminalUI:getCurrentBootMessage(progress)
    local currentMsg = BOOT_MESSAGES[1].text
    for _, msg in ipairs(BOOT_MESSAGES) do
        if progress >= msg.atPercent then
            currentMsg = msg.text
        else
            break
        end
    end
    return currentMsg
end

-- =========================================================================
-- LAYOUT-HELPERS (alle relativ zu self.width / self.height)
-- =========================================================================

function WHO_TerminalUI:getMargin()
    return math.max(28, math.floor(self.width * 0.03))
end

-- CLOSE-Button: unten zentriert, feste Größe, FOOTER_PAD über dem Rand.
-- Einzige Quelle für CLOSE-Geometrie (create() UND getActionButtonRect()).
function WHO_TerminalUI:getCloseRect()
    local tm   = getTextManager()
    local pad  = math.max(FOOTER_PAD_MIN, math.floor(self.height * 0.04))
    local hitH = tm:getFontHeight(UIFont.Medium) + BTN_TEXT_VPAD * 2
    local hitW = self.closeHitW or 200
    local x    = math.floor((self.width / 2) - (hitW / 2))
    local y    = self.height - pad - hitH
    return x, y, hitW, hitH
end

-- ACTION-Button (ACCEPT/CONFIRM): immer BTN_GAP über dem CLOSE-Button.
-- Dadurch ist Overlap mit CLOSE strukturell unmöglich.
function WHO_TerminalUI:getActionButtonRect()
    local tm   = getTextManager()
    local _, closeY = self:getCloseRect()
    local gap  = math.max(BTN_GAP_MIN, math.floor(self.height * 0.06))
    local hitH = tm:getFontHeight(UIFont.Medium) + BTN_TEXT_VPAD * 2
    local hitW = self.actionHitW or 360
    local x    = math.floor((self.width / 2) - (hitW / 2))
    local y    = closeY - gap - hitH
    return x, y, hitW, hitH
end

-- Hauptmenü-Layout (READY). Wird von Render UND Hit-Test geteilt.
function WHO_TerminalUI:getReadyLayout()
    local logoSize   = clampNum(math.floor(self.height * 0.30), 220, 400)
    local logoTop    = math.floor(self.height * 0.06)
    local subY       = logoTop + logoSize + 16
    local menuStartY = subY + getTextManager():getFontHeight(UIFont.Small) + 40
    return logoSize, logoTop, subY, menuStartY
end

function WHO_TerminalUI:getMenuItemRect(index)
    local _, _, _, menuStartY = self:getReadyLayout()
    local lineHeight = 46
    local itemWidth  = clampNum(math.floor(self.width * 0.32), 300, 460)
    local itemHeight = 36
    local itemX      = (self.width / 2) - (itemWidth / 2)
    local itemY      = menuStartY + (index - 1) * lineHeight
    return itemX, itemY, itemWidth, itemHeight
end

-- Missions-View-Layout. Zentrale Anker für Header, Spalten und Content-Grenzen.
-- Wird von Render UND Hit-Test geteilt, damit alles synchron bleibt.
function WHO_TerminalUI:getMissionsLayout()
    local tm     = getTextManager()
    local M      = self:getMargin()
    local thLg   = tm:getFontHeight(UIFont.Large)
    local thMed  = tm:getFontHeight(UIFont.Medium)
    local thSm   = tm:getFontHeight(UIFont.Small)

    local titleY   = math.floor(M * 0.5)
    local dividerY = titleY + thLg + 14
    local backX    = M
    local backY    = dividerY + 14
    local backH    = thMed + BTN_TEXT_VPAD * 2  -- Höhe der BACK-Text-Hit-Fläche
    local labelY   = backY + backH + 16       -- "AVAILABLE MISSIONS:"-Zeile
    local listY    = labelY + thSm + 12       -- Quest-Liste darunter

    local _, actionY = self:getActionButtonRect()
    local contentTop    = dividerY + 14
    local contentBottom = actionY - 18        -- Detail/Liste müssen darüber bleiben

    local innerW  = self.width - 2 * M
    local splitX  = M + math.floor(innerW * 0.34)
    local detailX = splitX + 22

    return {
        M = M, titleY = titleY, dividerY = dividerY,
        backX = backX, backY = backY, backH = backH,
        labelY = labelY, listY = listY,
        splitX = splitX, detailX = detailX,
        contentTop = contentTop, contentBottom = contentBottom,
        thSm = thSm, thMed = thMed,
    }
end

function WHO_TerminalUI:getQuestListItemRect(index)
    local L = self:getMissionsLayout()
    local listStartX = L.M
    local itemWidth  = L.splitX - L.M - 12    -- bis kurz vor den Spalten-Divider
    local itemHeight = 30
    local itemY      = L.listY + (index - 1) * itemHeight
    return listStartX, itemY, itemWidth, itemHeight
end

function WHO_TerminalUI:getBackButtonRect()
    local L = self:getMissionsLayout()
    -- Box wird zur Render-Zeit nach echter Text-Breite dimensioniert.
    -- Fallback-Defaults für Mouse-Hover vor dem ersten Render.
    local btnWidth  = self.backButtonActualWidth  or 100
    local btnHeight = self.backButtonActualHeight or L.backH
    return L.backX, L.backY, btnWidth, btnHeight
end

-- =========================================================================
-- RENDERING - SHARED
-- =========================================================================

function WHO_TerminalUI:prerender()
    self:drawRect(0, 0, self.width, self.height,
        COLOR_BG.a, COLOR_BG.r, COLOR_BG.g, COLOR_BG.b)

    self:drawRectBorder(0, 0, self.width, self.height,
        COLOR_BORDER.a, COLOR_BORDER.r, COLOR_BORDER.g, COLOR_BORDER.b)
    self:drawRectBorder(2, 2, self.width - 4, self.height - 4,
        COLOR_BORDER.a, COLOR_BORDER.r, COLOR_BORDER.g, COLOR_BORDER.b)
end

function WHO_TerminalUI:render()
    if self.state == STATE_BOOTING then
        self:renderBootingState()
    elseif self.state == STATE_READY then
        self:renderReadyState()
    elseif self.state == STATE_MISSIONS_VIEW then
        self:renderMissionsView()
    end
end

function WHO_TerminalUI:renderLogo(scaledWidth, scaledHeight, yOffset)
    if LOGO_TEXTURE then
        local logoX = (self.width / 2) - (scaledWidth / 2)
        self:drawTextureScaled(LOGO_TEXTURE, logoX, yOffset, scaledWidth, scaledHeight, 1)
    end
end

function WHO_TerminalUI:drawTextCentered(text, y, color, font)
    local width = getTextManager():MeasureStringX(font, text)
    self:drawText(text, (self.width / 2) - (width / 2), y,
        color.r, color.g, color.b, color.a, font)
end

-- =========================================================================
-- RENDERING - BOOTING STATE
-- =========================================================================

function WHO_TerminalUI:renderBootingState()
    local W, H = self.width, self.height
    local tm   = getTextManager()

    local logoSize = clampNum(math.floor(H * 0.50), 300, 560)
    local logoTop  = math.floor(H * 0.08)
    self:renderLogo(logoSize, logoSize, logoTop)

    local progress = self:getBootProgress()

    local msgY = logoTop + logoSize + 28
    local msg  = self:getCurrentBootMessage(progress)
    self:drawTextCentered(msg, msgY, COLOR_TEXT_BRIGHT, UIFont.Small)

    local barWidth   = math.floor(W * 0.5)
    local barHeight  = clampNum(math.floor(H * 0.03), 18, 30)
    local barX       = (W / 2) - (barWidth / 2)
    local barY       = msgY + tm:getFontHeight(UIFont.Small) + 22
    local blockCount = 20
    local blockGap   = 2
    local blockWidth = (barWidth - (blockCount - 1) * blockGap) / blockCount

    local activeBlocks = math.floor(progress * blockCount)

    for i = 0, blockCount - 1 do
        local blockX = barX + i * (blockWidth + blockGap)
        local color = (i < activeBlocks) and COLOR_BLOCK_ON or COLOR_BLOCK_OFF

        self:drawRect(blockX, barY, blockWidth, barHeight,
            color.a, color.r, color.g, color.b)
    end

    if progress >= 1.0 then
        self.state = STATE_READY
        WHO_TerminalUI.hasBootedThisSession = true
        print("[WHO] Terminal boot complete - now READY")
    end
end

-- =========================================================================
-- RENDERING - READY STATE (Hauptmenü)
-- =========================================================================

function WHO_TerminalUI:renderReadyState()
    local logoSize, logoTop, subY = self:getReadyLayout()
    self:renderLogo(logoSize, logoSize, logoTop)
    self:drawTextCentered("// LOGISTICS UPLINK ESTABLISHED", subY, COLOR_TEXT_DIM, UIFont.Small)

    for i, item in ipairs(MAIN_MENU_ITEMS) do
        local itemX, itemY, itemWidth, itemHeight = self:getMenuItemRect(i)

        local color
        if not item.enabled then
            color = COLOR_TEXT_GRAY
        elseif self.hoveredMenuIndex == i then
            color = COLOR_TEXT_HOVER
        else
            color = COLOR_TEXT_BRIGHT
        end

        local arrowX = itemX + 50
        local labelX = itemX + 100
        local textY  = itemY + 5

        if self.hoveredMenuIndex == i and item.enabled then
            self:drawText(">", arrowX, textY,
                color.r, color.g, color.b, color.a, UIFont.Medium)
        end

        self:drawText(item.label, labelX, textY,
            color.r, color.g, color.b, color.a, UIFont.Medium)
    end

    self:renderClose()
end

-- =========================================================================
-- RENDERING - MISSIONS VIEW
-- =========================================================================

function WHO_TerminalUI:renderMissionsView()
    local L = self:getMissionsLayout()

    self:drawTextCentered("// MISSION DATABASE", L.titleY, COLOR_TEXT_BRIGHT, UIFont.Large)

    self:drawRect(L.M, L.dividerY, self.width - 2 * L.M, 1,
        COLOR_BORDER.a, COLOR_BORDER.r, COLOR_BORDER.g, COLOR_BORDER.b)

    self:renderBackButton()

    local player = self.player or getPlayer()
    local status = WHO_QuestState.getCurrentStatus(player)

    if status == WHO_QuestState.STATUS.IDLE then
        self:renderMissionsListView(player)
    elseif status == WHO_QuestState.STATUS.ACTIVE then
        self:renderActiveMissionView(player)
    elseif status == WHO_QuestState.STATUS.COMPLETE then
        self:renderCompletedMissionView(player)
    end

    self:renderClose()
end

function WHO_TerminalUI:renderBackButton()
    local L  = self:getMissionsLayout()
    local tm = getTextManager()
    local color = self.hoveredBack and COLOR_TEXT_HOVER or COLOR_TEXT_BRIGHT

    local label    = "BACK"
    local labelW   = tm:MeasureStringX(UIFont.Medium, label)
    local arrowCol = tm:MeasureStringX(UIFont.Medium, "> ")
    local labelX   = L.backX + arrowCol       -- feste Label-Position; Arrow-Spalte links
    local textY    = L.backY + BTN_TEXT_VPAD

    if self.hoveredBack then
        self:drawText(">", L.backX, textY, color.r, color.g, color.b, color.a, UIFont.Medium)
    end
    self:drawText(label, labelX, textY, color.r, color.g, color.b, color.a, UIFont.Medium)

    -- Hit-Fläche (Arrow-Spalte + Label + Padding) für getBackButtonRect speichern.
    self.backButtonActualWidth  = arrowCol + labelW + BTN_HIT_PAD
    self.backButtonActualHeight = tm:getFontHeight(UIFont.Medium) + BTN_TEXT_VPAD * 2
end

-- IDLE
function WHO_TerminalUI:renderMissionsListView(player)
    local L = self:getMissionsLayout()
    local available = WHO_Quests.getAvailable()

    if #available == 0 then
        self:drawTextCentered("No missions available.",
            math.floor((L.contentTop + L.contentBottom) / 2), COLOR_TEXT_DIM, UIFont.Medium)
        return
    end

    if self.selectedQuestIndex < 1 then self.selectedQuestIndex = 1 end
    if self.selectedQuestIndex > #available then self.selectedQuestIndex = #available end

    -- Label auf eigener Zeile unter dem BACK-Button, linksbündig mit der Liste.
    self:drawText("AVAILABLE MISSIONS:", L.M, L.labelY,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)

    for i, quest in ipairs(available) do
        local itemX, itemY = self:getQuestListItemRect(i)

        local color
        local prefix
        if self.selectedQuestIndex == i then
            color = COLOR_TEXT_HOVER
            prefix = "> "
        else
            color = COLOR_TEXT_BRIGHT
            prefix = "  "
        end

        local label = prefix .. "[T" .. quest.tier .. "] " .. quest.name
        self:drawText(label, itemX, itemY + 5,
            color.r, color.g, color.b, color.a, UIFont.Medium)
    end

    self:renderQuestDetailPane(available[self.selectedQuestIndex])
    self:renderActionButton("ACCEPT MISSION", true)
end

function WHO_TerminalUI:renderQuestDetailPane(quest)
    if not quest then return end

    local L = self:getMissionsLayout()
    local detailX = L.detailX
    local detailY = L.contentTop

    -- Spalten-Divider: vom Content-Top bis Content-Bottom (über dem Action-Button).
    self:drawRect(L.splitX, L.contentTop, 1, L.contentBottom - L.contentTop,
        COLOR_BORDER.a, COLOR_BORDER.r, COLOR_BORDER.g, COLOR_BORDER.b)

    self:drawText(quest.name, detailX, detailY,
        COLOR_TEXT_HOVER.r, COLOR_TEXT_HOVER.g, COLOR_TEXT_HOVER.b, COLOR_TEXT_HOVER.a, UIFont.Large)

    self:drawText("TIER " .. quest.tier .. " // Handler: " .. (quest.handler or "COMMAND"),
        detailX, detailY + 35,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)

    local y = detailY + 80
    self:drawText("BRIEFING:", detailX, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
    y = y + 22

    local lineH = 20

    if quest.briefing then
        -- Anzahl Briefing-Zeilen dynamisch an die verfügbare Höhe binden:
        -- Platz für OBJECTIVES + REWARD reservieren, Rest geht ans Briefing.
        local objCount = #quest.requirements
        local rewCount = #quest.rewards
        local reserved = 20 + (22 + objCount * lineH) + 15 + (22 + rewCount * lineH)
        local briefingSpace = (L.contentBottom - y) - reserved
        local maxLines = math.max(1, math.floor(briefingSpace / lineH))
        local shown = math.min(#quest.briefing, maxLines)

        for i = 1, shown do
            self:drawText(quest.briefing[i], detailX, y,
                COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
            y = y + lineH
        end
        if #quest.briefing > shown then
            self:drawText("[...]", detailX, y,
                COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
            y = y + lineH
        end
    elseif quest.description then
        self:drawText(quest.description, detailX, y,
            COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
        y = y + lineH
    end

    y = y + 20
    self:drawText("OBJECTIVES:", detailX, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
    y = y + 22

    for _, req in ipairs(quest.requirements) do
        local line = "  > Deliver " .. req.count .. "x " .. req.itemType
        self:drawText(line, detailX, y,
            COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
        y = y + lineH
    end

    y = y + 15
    self:drawText("REWARD:", detailX, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
    y = y + 22

    for _, rew in ipairs(quest.rewards) do
        local line = "  + " .. rew.count .. "x " .. rew.itemType
        self:drawText(line, detailX, y,
            COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
        y = y + lineH
    end
end

-- ACTIVE
function WHO_TerminalUI:renderActiveMissionView(player)
    local quest = WHO_QuestState.getCurrentQuest(player)
    if not quest then return end

    local L  = self:getMissionsLayout()
    local indentX = math.floor(self.width * 0.15)
    local y  = L.contentTop + 20

    self:drawTextCentered("MISSION IN PROGRESS", y, COLOR_TEXT_AMBER, UIFont.Medium)
    y = y + 50
    self:drawTextCentered(quest.name, y, COLOR_TEXT_HOVER, UIFont.Large)
    y = y + 44
    self:drawTextCentered("TIER " .. quest.tier .. " // Handler: " .. (quest.handler or "COMMAND"),
        y, COLOR_TEXT_DIM, UIFont.Small)
    y = y + 56

    self:drawText("OBJECTIVES:", indentX, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
    y = y + 28

    for _, req in ipairs(quest.requirements) do
        local line = "  > Deliver " .. req.count .. "x " .. req.itemType
        self:drawText(line, indentX, y,
            COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
        y = y + 22
    end

    y = y + 40
    self:drawText("// Deliver items to the EXTRACTION CRATE in the warehouse.", indentX, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
    y = y + 20
    self:drawText("// Return to this terminal once complete.", indentX, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
end

-- COMPLETE
function WHO_TerminalUI:renderCompletedMissionView(player)
    local quest = WHO_QuestState.getCurrentQuest(player)
    if not quest then return end

    local L  = self:getMissionsLayout()
    local indentX = math.floor(self.width * 0.15)
    local y  = L.contentTop + 20

    self:drawTextCentered("MISSION COMPLETE", y, COLOR_TEXT_AMBER, UIFont.Large)
    y = y + 50
    self:drawTextCentered("Awaiting extraction confirmation", y, COLOR_TEXT_DIM, UIFont.Small)
    y = y + 60
    self:drawTextCentered(quest.name, y, COLOR_TEXT_HOVER, UIFont.Medium)
    y = y + 60

    self:drawText("INCOMING REWARDS:", indentX, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
    y = y + 28

    for _, rew in ipairs(quest.rewards) do
        local line = "  + " .. rew.count .. "x " .. rew.itemType
        self:drawText(line, indentX, y,
            COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
        y = y + 22
    end

    self:renderActionButton("CONFIRM EXTRACTION", true)
end

function WHO_TerminalUI:renderActionButton(label, enabled)
    local tm     = getTextManager()
    local labelW = tm:MeasureStringX(UIFont.Medium, label)
    self.actionHitW = labelW + BTN_HIT_PAD * 2   -- Hit-Fläche = Text + Padding

    local x, y  = self:getActionButtonRect()
    local color = enabled and (self.hoveredAction and COLOR_TEXT_HOVER or COLOR_TEXT_BRIGHT) or COLOR_TEXT_GRAY

    local labelX = math.floor((self.width / 2) - (labelW / 2))
    local textY  = y + BTN_TEXT_VPAD

    if enabled and self.hoveredAction then
        local arrowCol = tm:MeasureStringX(UIFont.Medium, "> ")
        self:drawText(">", labelX - arrowCol, textY, color.r, color.g, color.b, color.a, UIFont.Medium)
    end
    self:drawText(label, labelX, textY, color.r, color.g, color.b, color.a, UIFont.Medium)
end

function WHO_TerminalUI:renderClose()
    local tm     = getTextManager()
    local label  = "CLOSE"
    local labelW = tm:MeasureStringX(UIFont.Medium, label)
    self.closeHitW = labelW + BTN_HIT_PAD * 2

    local x, y  = self:getCloseRect()
    local color = self.hoveredClose and COLOR_TEXT_HOVER or COLOR_TEXT_BRIGHT

    local labelX = math.floor((self.width / 2) - (labelW / 2))
    local textY  = y + BTN_TEXT_VPAD

    if self.hoveredClose then
        local arrowCol = tm:MeasureStringX(UIFont.Medium, "> ")
        self:drawText(">", labelX - arrowCol, textY, color.r, color.g, color.b, color.a, UIFont.Medium)
    end
    self:drawText(label, labelX, textY, color.r, color.g, color.b, color.a, UIFont.Medium)
end

-- =========================================================================
-- INPUT HANDLING
-- =========================================================================

function WHO_TerminalUI:isPointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

function WHO_TerminalUI:onMouseMove(dx, dy)
    local mouseX = self:getMouseX()
    local mouseY = self:getMouseY()

    self.hoveredMenuIndex  = 0
    self.hoveredQuestIndex = 0
    self.hoveredBack       = false
    self.hoveredAction     = false
    self.hoveredClose      = false

    if self.state == STATE_READY then
        for i, item in ipairs(MAIN_MENU_ITEMS) do
            if item.enabled then
                local itemX, itemY, itemWidth, itemHeight = self:getMenuItemRect(i)
                if self:isPointInRect(mouseX, mouseY, itemX, itemY, itemWidth, itemHeight) then
                    self.hoveredMenuIndex = i
                    break
                end
            end
        end
    elseif self.state == STATE_MISSIONS_VIEW then
        local bx, by, bw, bh = self:getBackButtonRect()
        if self:isPointInRect(mouseX, mouseY, bx, by, bw, bh) then
            self.hoveredBack = true
        end

        local player = self.player or getPlayer()
        local status = WHO_QuestState.getCurrentStatus(player)

        if status == WHO_QuestState.STATUS.IDLE then
            local available = WHO_Quests.getAvailable()
            for i, _ in ipairs(available) do
                local ix, iy, iw, ih = self:getQuestListItemRect(i)
                if self:isPointInRect(mouseX, mouseY, ix, iy, iw, ih) then
                    self.hoveredQuestIndex = i
                    break
                end
            end
        end

        if status == WHO_QuestState.STATUS.IDLE or status == WHO_QuestState.STATUS.COMPLETE then
            local ax, ay, aw, ah = self:getActionButtonRect()
            if self:isPointInRect(mouseX, mouseY, ax, ay, aw, ah) then
                self.hoveredAction = true
            end
        end
    end

    -- CLOSE ist in READY und MISSIONS sichtbar/klickbar (nicht beim Booten).
    if self.state ~= STATE_BOOTING then
        local cx, cy, cw, ch = self:getCloseRect()
        if self:isPointInRect(mouseX, mouseY, cx, cy, cw, ch) then
            self.hoveredClose = true
        end
    end
end

function WHO_TerminalUI:onMouseDown(x, y)
    -- CLOSE zuerst prüfen (sichtbar in READY + MISSIONS, nicht beim Booten).
    if self.state ~= STATE_BOOTING then
        local cx, cy, cw, ch = self:getCloseRect()
        if self:isPointInRect(x, y, cx, cy, cw, ch) then
            self:close()
            return true
        end
    end

    if self.state == STATE_READY then
        for i, item in ipairs(MAIN_MENU_ITEMS) do
            if item.enabled then
                local itemX, itemY, itemWidth, itemHeight = self:getMenuItemRect(i)
                if self:isPointInRect(x, y, itemX, itemY, itemWidth, itemHeight) then
                    self:handleMenuAction(item.action)
                    return true
                end
            end
        end
    elseif self.state == STATE_MISSIONS_VIEW then
        local bx, by, bw, bh = self:getBackButtonRect()
        if self:isPointInRect(x, y, bx, by, bw, bh) then
            self.state = STATE_READY
            return true
        end

        local player = self.player or getPlayer()
        local status = WHO_QuestState.getCurrentStatus(player)

        if status == WHO_QuestState.STATUS.IDLE then
            local available = WHO_Quests.getAvailable()
            for i, _ in ipairs(available) do
                local ix, iy, iw, ih = self:getQuestListItemRect(i)
                if self:isPointInRect(x, y, ix, iy, iw, ih) then
                    self.selectedQuestIndex = i
                    return true
                end
            end

            local ax, ay, aw, ah = self:getActionButtonRect()
            if self:isPointInRect(x, y, ax, ay, aw, ah) then
                local selected = available[self.selectedQuestIndex]
                if selected then
                    WHO_QuestState.acceptQuest(player, selected.id)
                end
                return true
            end
        elseif status == WHO_QuestState.STATUS.COMPLETE then
            local ax, ay, aw, ah = self:getActionButtonRect()
            if self:isPointInRect(x, y, ax, ay, aw, ah) then
                WHO_RewardDispatcher.dispatch(player)
                return true
            end
        end
    end

    return ISPanel.onMouseDown(self, x, y)
end

function WHO_TerminalUI:handleMenuAction(action)
    print("[WHO] Menu action: " .. action)

    if action == "open_missions" then
        self.state = STATE_MISSIONS_VIEW
        self.selectedQuestIndex = 1
    elseif action == "shutdown" then
        self:close()
    end
end

-- =========================================================================
-- EVENT
-- =========================================================================

function WHO_TerminalUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    WHO_TerminalUI.instance = nil
    print("[WHO] Terminal closed")
end

-- =========================================================================
-- CONSTRUCTOR
-- =========================================================================

function WHO_TerminalUI:new(player)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    -- Fenster = 75% des Screens, geclamped (Min für kleine Screens, Max für 4K).
    local w = clampNum(math.floor(screenW * WINDOW_SCALE), WINDOW_MIN_W, WINDOW_MAX_W)
    local h = clampNum(math.floor(screenH * WINDOW_SCALE), WINDOW_MIN_H, WINDOW_MAX_H)
    local x = (screenW - w) / 2
    local y = (screenH - h) / 2

    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.moveWithMouse = true

    if WHO_TerminalUI.hasBootedThisSession then
        o.state = STATE_READY
        print("[WHO] Terminal opened (already booted, skipping boot sequence)")
    else
        o.state = STATE_BOOTING
        o.bootStartMs = getTimestampMs()
        print("[WHO] Terminal opened (starting boot sequence)")
    end

    print("[WHO] Terminal window sized to " .. w .. "x" .. h ..
          " (screen " .. screenW .. "x" .. screenH .. ")")

    WHO_TerminalUI.instance = o

    return o
end

-- =========================================================================
-- PUBLIC API
-- =========================================================================

function WHO_TerminalUI.openTerminal(player)
    if WHO_TerminalUI.instance and WHO_TerminalUI.instance:getIsVisible() then
        return WHO_TerminalUI.instance
    end

    local terminal = WHO_TerminalUI:new(player)
    terminal:initialise()
    terminal:addToUIManager()
    return terminal
end

print("[WHO] Terminal UI module loaded. v" .. WHO_Config.MOD.VERSION)
