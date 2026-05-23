-- Warehouse Operator - Terminal UI
-- Phase 3b: Mission-View mit echter Quest-Liste + Accept + State-Anzeige
-- Datei heißt WHO_AAA_TerminalUI.lua wegen alphabetischer Lade-Reihenfolge in client/

require "ISUI/ISPanel"

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
-- WINDOW SIZE
-- =========================================================================

local WINDOW_WIDTH  = 1000
local WINDOW_HEIGHT = 750

-- =========================================================================
-- ASSETS
-- =========================================================================

local LOGO_TEXTURE = getTexture("media/textures/who_logo_boot.png")
local LOGO_WIDTH   = 300
local LOGO_HEIGHT  = 300

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
    local btnWidth  = 100
    local btnHeight = 25
    local padBottom = 50    -- Genug Luft zum unteren Rand

    local closeBtn = ISButton:new(
        (self:getWidth() / 2) - (btnWidth / 2),
        self:getHeight() - padBottom - btnHeight,
        btnWidth,
        btnHeight,
        "CLOSE",
        self,
        WHO_TerminalUI.onCloseClicked
    )
    closeBtn.borderColor = COLOR_BORDER
    closeBtn:initialise()
    closeBtn:instantiate()
    self:addChild(closeBtn)
    self.closeBtn = closeBtn

    self.hoveredMenuIndex   = 0
    self.hoveredQuestIndex  = 0
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
-- LAYOUT-HELPERS
-- =========================================================================

function WHO_TerminalUI:getMenuItemRect(index)
    local menuStartY  = 430
    local lineHeight  = 40
    local itemWidth   = 350
    local itemHeight  = 32
    local itemX       = (self.width / 2) - (itemWidth / 2)
    local itemY       = menuStartY + (index - 1) * lineHeight

    return itemX, itemY, itemWidth, itemHeight
end

function WHO_TerminalUI:getQuestListItemRect(index)
    local listStartX = 30
    local listStartY = 110
    local itemWidth  = 320
    local itemHeight = 28
    local itemY      = listStartY + (index - 1) * itemHeight

    return listStartX, itemY, itemWidth, itemHeight
end

function WHO_TerminalUI:getActionButtonRect()
    local btnWidth  = 280
    local btnHeight = 35
    local btnX      = (self.width / 2) - (btnWidth / 2)
    local btnY      = self.height - 140   -- Mehr Luft zum CLOSE-Button
    return btnX, btnY, btnWidth, btnHeight
end

function WHO_TerminalUI:getBackButtonRect()
    local btnX = 25
    local btnY = 70
    -- Box wird zur Render-Zeit nach echter Text-Breite dimensioniert.
    -- Fallback-Defaults für Mouse-Hover vor dem ersten Render.
    local btnWidth  = self.backButtonActualWidth  or 100
    local btnHeight = self.backButtonActualHeight or 32
    return btnX, btnY, btnWidth, btnHeight
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
    if self.closeBtn then self.closeBtn:setVisible(false) end

    self:renderLogo(450, 450, 60)

    local progress = self:getBootProgress()

    local msg = self:getCurrentBootMessage(progress)
    self:drawTextCentered(msg, 570, COLOR_TEXT_BRIGHT, UIFont.Small)

    local barWidth   = 500
    local barHeight  = 24
    local barX       = (self.width / 2) - (barWidth / 2)
    local barY       = 615
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
    if self.closeBtn then self.closeBtn:setVisible(true) end

    self:renderLogo(LOGO_WIDTH, LOGO_HEIGHT, 50)
    self:drawTextCentered("// LOGISTICS UPLINK ESTABLISHED", 380, COLOR_TEXT_DIM, UIFont.Small)

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
end

-- =========================================================================
-- RENDERING - MISSIONS VIEW
-- =========================================================================

function WHO_TerminalUI:renderMissionsView()
    if self.closeBtn then self.closeBtn:setVisible(true) end

    self:drawTextCentered("// MISSION DATABASE", 25, COLOR_TEXT_BRIGHT, UIFont.Large)

    self:drawRect(20, 55, self.width - 40, 1,
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
end

function WHO_TerminalUI:renderBackButton()
    local x, y, w, h = self:getBackButtonRect()
    local color = (self.hoveredBack) and COLOR_TEXT_HOVER or COLOR_TEXT_BRIGHT

    -- Text-Breite + Höhe messen und Box-Größe dynamisch berechnen
    local text = "< BACK"
    local tw = getTextManager():MeasureStringX(UIFont.Medium, text)
    local th = getTextManager():getFontHeight(UIFont.Medium)

    -- Padding: 15px links/rechts, 6px oben/unten
    local boxWidth  = tw + 30
    local boxHeight = th + 12

    self:drawRectBorder(x, y, boxWidth, boxHeight, color.a, color.r, color.g, color.b)
    self:drawText(text, x + 15, y + 6,
        color.r, color.g, color.b, color.a, UIFont.Medium)

    -- Echte Box-Größe für Hit-Detection speichern
    self.backButtonActualWidth  = boxWidth
    self.backButtonActualHeight = boxHeight
end

-- IDLE
function WHO_TerminalUI:renderMissionsListView(player)
    local available = WHO_Quests.getAvailable()

    if #available == 0 then
        self:drawTextCentered("No missions available.", 300, COLOR_TEXT_DIM, UIFont.Medium)
        return
    end

    if self.selectedQuestIndex < 1 then self.selectedQuestIndex = 1 end
    if self.selectedQuestIndex > #available then self.selectedQuestIndex = #available end

    self:drawText("AVAILABLE MISSIONS:", 30, 80,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)

    for i, quest in ipairs(available) do
        local itemX, itemY, itemWidth, itemHeight = self:getQuestListItemRect(i)

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
    self:renderActionButton("[ ACCEPT MISSION ]", true)
end

function WHO_TerminalUI:renderQuestDetailPane(quest)
    if not quest then return end

    local detailX = 380
    local detailY = 80

    self:drawRect(365, 80, 1, 530,
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

    if quest.briefing then
        for _, line in ipairs(quest.briefing) do
            self:drawText(line, detailX, y,
                COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
            y = y + 20
        end
    elseif quest.description then
        self:drawText(quest.description, detailX, y,
            COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
        y = y + 20
    end

    y = y + 20
    self:drawText("OBJECTIVES:", detailX, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
    y = y + 22

    for _, req in ipairs(quest.requirements) do
        local line = "  > Deliver " .. req.count .. "x " .. req.itemType
        self:drawText(line, detailX, y,
            COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
        y = y + 20
    end

    y = y + 15
    self:drawText("REWARD:", detailX, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
    y = y + 22

    for _, rew in ipairs(quest.rewards) do
        local line = "  + " .. rew.count .. "x " .. rew.itemType
        self:drawText(line, detailX, y,
            COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
        y = y + 20
    end
end

-- ACTIVE
function WHO_TerminalUI:renderActiveMissionView(player)
    local quest = WHO_QuestState.getCurrentQuest(player)
    if not quest then return end

    self:drawTextCentered("MISSION IN PROGRESS", 100, COLOR_TEXT_AMBER, UIFont.Medium)

    self:drawTextCentered(quest.name, 160, COLOR_TEXT_HOVER, UIFont.Large)
    self:drawTextCentered("TIER " .. quest.tier .. " // Handler: " .. (quest.handler or "COMMAND"),
        200, COLOR_TEXT_DIM, UIFont.Small)

    local y = 270
    self:drawText("OBJECTIVES:", 120, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
    y = y + 28

    for _, req in ipairs(quest.requirements) do
        local line = "  > Deliver " .. req.count .. "x " .. req.itemType
        self:drawText(line, 120, y,
            COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
        y = y + 22
    end

    y = y + 40
    self:drawText("// Deliver items to the EXTRACTION CRATE in the warehouse.", 120, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
    y = y + 20
    self:drawText("// Return to this terminal once complete.", 120, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
end

-- COMPLETE
function WHO_TerminalUI:renderCompletedMissionView(player)
    local quest = WHO_QuestState.getCurrentQuest(player)
    if not quest then return end

    self:drawTextCentered("MISSION COMPLETE", 100, COLOR_TEXT_AMBER, UIFont.Large)
    self:drawTextCentered("Awaiting extraction confirmation", 155, COLOR_TEXT_DIM, UIFont.Small)

    self:drawTextCentered(quest.name, 230, COLOR_TEXT_HOVER, UIFont.Medium)

    local y = 300
    self:drawText("INCOMING REWARDS:", 120, y,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a, UIFont.Small)
    y = y + 28

    for _, rew in ipairs(quest.rewards) do
        local line = "  + " .. rew.count .. "x " .. rew.itemType
        self:drawText(line, 120, y,
            COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a, UIFont.Small)
        y = y + 22
    end

    self:renderActionButton("[ CONFIRM EXTRACTION ]", true)
end

function WHO_TerminalUI:renderActionButton(label, enabled)
    local x, y, w, h = self:getActionButtonRect()
    local color = enabled and (self.hoveredAction and COLOR_TEXT_HOVER or COLOR_TEXT_BRIGHT) or COLOR_TEXT_GRAY

    self:drawRectBorder(x, y, w, h, color.a, color.r, color.g, color.b)

    local tw = getTextManager():MeasureStringX(UIFont.Medium, label)
    self:drawText(label, x + (w/2) - (tw/2), y + 8,
        color.r, color.g, color.b, color.a, UIFont.Medium)
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
end

function WHO_TerminalUI:onMouseDown(x, y)
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

function WHO_TerminalUI:onCloseClicked()
    self:close()
end

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
    local x = (screenW - WINDOW_WIDTH) / 2
    local y = (screenH - WINDOW_HEIGHT) / 2

    local o = ISPanel:new(x, y, WINDOW_WIDTH, WINDOW_HEIGHT)
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

print("[WHO] Terminal UI module loaded.")