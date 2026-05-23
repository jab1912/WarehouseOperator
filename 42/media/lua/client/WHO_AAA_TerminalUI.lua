-- Warehouse Operator - Terminal UI
-- Phase 3a.3: Hauptmenü mit DOS-Style-Buttons (vertikal, Pfeil bei Hover)
-- Datei heißt WHO_AAA_TerminalUI.lua wegen alphabetischer Lade-Reihenfolge in client/

require "ISUI/ISPanel"

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
local COLOR_BLOCK_ON    = {r=0.4,  g=1.0,  b=0.4,  a=1}
local COLOR_BLOCK_OFF   = {r=0.1,  g=0.3,  b=0.1,  a=1}

-- =========================================================================
-- ASSETS
-- =========================================================================

local LOGO_TEXTURE = getTexture("media/textures/who_logo_boot.png")
local LOGO_WIDTH   = 250
local LOGO_HEIGHT  = 250

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
-- MENU CONFIGURATION
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
    local padBottom = 20

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

    self.hoveredMenuIndex = 0
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
-- MENU LAYOUT
-- =========================================================================

function WHO_TerminalUI:getMenuItemRect(index)
    local menuStartY  = 350
    local lineHeight  = 35
    local itemWidth   = 300
    local itemHeight  = 30
    local itemX       = (self.width / 2) - (itemWidth / 2)
    local itemY       = menuStartY + (index - 1) * lineHeight

    return itemX, itemY, itemWidth, itemHeight
end

-- =========================================================================
-- RENDERING
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

function WHO_TerminalUI:renderBootingState()
    if self.closeBtn then self.closeBtn:setVisible(false) end

    self:renderLogo(400, 400, 40)

    local progress = self:getBootProgress()

    local msg = self:getCurrentBootMessage(progress)
    local msgWidth = getTextManager():MeasureStringX(UIFont.Small, msg)
    self:drawText(msg,
        (self.width / 2) - (msgWidth / 2),
        470,
        COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a,
        UIFont.Small
    )

    local barWidth   = 400
    local barHeight  = 20
    local barX       = (self.width / 2) - (barWidth / 2)
    local barY       = 515
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

function WHO_TerminalUI:renderReadyState()
    if self.closeBtn then self.closeBtn:setVisible(true) end

    -- Logo oben (kleiner)
    self:renderLogo(LOGO_WIDTH, LOGO_HEIGHT, 30)

    -- Subtitle unter dem Logo
    local subtitle = "// LOGISTICS UPLINK ESTABLISHED"
    local subtitleWidth = getTextManager():MeasureStringX(UIFont.Small, subtitle)
    self:drawText(subtitle,
        (self.width / 2) - (subtitleWidth / 2),
        300,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a,
        UIFont.Small
    )

    -- Hauptmenü-Buttons vertikal
    -- Pfeil und Label werden getrennt gezeichnet, damit das Label
    -- beim Hover NICHT seine X-Position wechselt
    for i, item in ipairs(MAIN_MENU_ITEMS) do
        local itemX, itemY, itemWidth, itemHeight = self:getMenuItemRect(i)

        -- Farbe je nach Status
        local color
        if not item.enabled then
            color = COLOR_TEXT_GRAY
        elseif self.hoveredMenuIndex == i then
            color = COLOR_TEXT_HOVER
        else
            color = COLOR_TEXT_BRIGHT
        end

        -- Fixe X-Positionen: Pfeil bei +40, Label bei +80
        local arrowX = itemX + 40
        local labelX = itemX + 80
        local textY  = itemY + 5

        -- Pfeil nur zeichnen wenn dieses Item gehovered ist
        if self.hoveredMenuIndex == i and item.enabled then
            self:drawText(">", arrowX, textY,
                color.r, color.g, color.b, color.a,
                UIFont.Medium)
        end

        -- Label immer an der gleichen Position
        self:drawText(item.label, labelX, textY,
            color.r, color.g, color.b, color.a,
            UIFont.Medium)
    end
end

function WHO_TerminalUI:renderMissionsView()
    if self.closeBtn then self.closeBtn:setVisible(true) end

    local header = "// MISSION DATABASE"
    local headerWidth = getTextManager():MeasureStringX(UIFont.Large, header)
    self:drawText(header,
        (self.width / 2) - (headerWidth / 2),
        40,
        COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a,
        UIFont.Large)

    local placeholder = "Mission view will be implemented in Phase 3b"
    local placeholderWidth = getTextManager():MeasureStringX(UIFont.Small, placeholder)
    self:drawText(placeholder,
        (self.width / 2) - (placeholderWidth / 2),
        100,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a,
        UIFont.Small)

    local backHint = "[ CLICK ANYWHERE TO RETURN ]"
    local backWidth = getTextManager():MeasureStringX(UIFont.Small, backHint)
    self:drawText(backHint,
        (self.width / 2) - (backWidth / 2),
        450,
        COLOR_TEXT_HOVER.r, COLOR_TEXT_HOVER.g, COLOR_TEXT_HOVER.b, COLOR_TEXT_HOVER.a,
        UIFont.Small)
end

-- =========================================================================
-- INPUT HANDLING
-- =========================================================================

function WHO_TerminalUI:onMouseMove(dx, dy)
    if self.state ~= STATE_READY then
        self.hoveredMenuIndex = 0
        return
    end

    local mouseX = self:getMouseX()
    local mouseY = self:getMouseY()

    self.hoveredMenuIndex = 0
    for i, item in ipairs(MAIN_MENU_ITEMS) do
        if item.enabled then
            local itemX, itemY, itemWidth, itemHeight = self:getMenuItemRect(i)
            if mouseX >= itemX and mouseX <= itemX + itemWidth
                and mouseY >= itemY and mouseY <= itemY + itemHeight then
                self.hoveredMenuIndex = i
                break
            end
        end
    end
end

function WHO_TerminalUI:onMouseDown(x, y)
    if self.state == STATE_READY then
        for i, item in ipairs(MAIN_MENU_ITEMS) do
            if item.enabled then
                local itemX, itemY, itemWidth, itemHeight = self:getMenuItemRect(i)
                if x >= itemX and x <= itemX + itemWidth
                    and y >= itemY and y <= itemY + itemHeight then
                    self:handleMenuAction(item.action)
                    return true
                end
            end
        end
    elseif self.state == STATE_MISSIONS_VIEW then
        self.state = STATE_READY
        return true
    end

    return ISPanel.onMouseDown(self, x, y)
end

function WHO_TerminalUI:handleMenuAction(action)
    print("[WHO] Menu action: " .. action)

    if action == "open_missions" then
        self.state = STATE_MISSIONS_VIEW
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
    local width  = 800
    local height = 600

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2

    local o = ISPanel:new(x, y, width, height)
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