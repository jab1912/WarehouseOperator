-- Warehouse Operator - Terminal UI
-- Phase 3a.2: Boot-Sequenz mit Logo + Block-Ladebalken + wechselnde Status-Texte
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
local COLOR_BLOCK_ON    = {r=0.4,  g=1.0,  b=0.4,  a=1}    -- Helle Blöcke
local COLOR_BLOCK_OFF   = {r=0.1,  g=0.3,  b=0.1,  a=1}    -- Dunkle Blöcke

-- =========================================================================
-- ASSETS
-- =========================================================================

local LOGO_TEXTURE = getTexture("media/textures/who_logo_boot.png")
local LOGO_WIDTH   = 400
local LOGO_HEIGHT  = 400

-- =========================================================================
-- BOOT-SEQUENZ-KONFIGURATION
-- =========================================================================
-- Status-Codes für die UI-State-Machine
local STATE_BOOTING = "booting"
local STATE_READY   = "ready"

-- Boot dauert ca. 4 Sekunden (240 Frames bei 60fps; render-Loop ist FPS-abhängig)
-- Wir nutzen aber Echtzeit via getTimestampMs() für Frame-rate-Unabhängigkeit.
local BOOT_DURATION_MS = 4000   -- 4 Sekunden

-- Status-Meldungen die während des Boots durchgeschaltet werden
-- Jede Meldung hängt am erreichten Prozent-Wert
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
-- LIFECYCLE
-- =========================================================================

function WHO_TerminalUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

function WHO_TerminalUI:create()
    -- Close-Button anlegen (existiert immer, wird aber im BOOTING-State versteckt)
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
end

-- =========================================================================
-- BOOT-LOGIK: Prozent berechnen + aktuelle Message ermitteln
-- =========================================================================

function WHO_TerminalUI:getBootProgress()
    if self.bootStartMs == nil then return 0 end

    local elapsed = getTimestampMs() - self.bootStartMs
    local progress = elapsed / BOOT_DURATION_MS

    if progress > 1.0 then progress = 1.0 end
    return progress
end

function WHO_TerminalUI:getCurrentBootMessage(progress)
    -- Finde die jüngste Message deren atPercent <= progress ist
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
    -- LOGO zentriert oben (in beiden States gleich)
    if LOGO_TEXTURE then
        local logoX = (self.width / 2) - (LOGO_WIDTH / 2)
        local logoY = 40
        self:drawTextureScaled(LOGO_TEXTURE, logoX, logoY, LOGO_WIDTH, LOGO_HEIGHT, 1)
    end

    -- State-spezifisches Rendering
    if self.state == STATE_BOOTING then
        self:renderBootingState()
    else
        self:renderReadyState()
    end
end

function WHO_TerminalUI:renderBootingState()
    -- Close-Button während Boot verstecken
    if self.closeBtn then self.closeBtn:setVisible(false) end

    -- Prozent berechnen
    local progress = self:getBootProgress()

    -- Status-Message
    local msg = self:getCurrentBootMessage(progress)
    local msgWidth = getTextManager():MeasureStringX(UIFont.Small, msg)
    self:drawText(msg,
        (self.width / 2) - (msgWidth / 2),
        470,
        COLOR_TEXT_BRIGHT.r, COLOR_TEXT_BRIGHT.g, COLOR_TEXT_BRIGHT.b, COLOR_TEXT_BRIGHT.a,
        UIFont.Small
    )

    -- Block-Ladebalken
    local barWidth     = 400
    local barHeight    = 20
    local barX         = (self.width / 2) - (barWidth / 2)
    local barY         = 515
    local blockCount   = 20      -- 20 Blöcke
    local blockGap     = 2       -- 2 Pixel zwischen Blöcken
    local blockWidth   = (barWidth - (blockCount - 1) * blockGap) / blockCount

    local activeBlocks = math.floor(progress * blockCount)

    for i = 0, blockCount - 1 do
        local blockX = barX + i * (blockWidth + blockGap)
        local color = (i < activeBlocks) and COLOR_BLOCK_ON or COLOR_BLOCK_OFF

        self:drawRect(blockX, barY, blockWidth, barHeight,
            color.a, color.r, color.g, color.b)
    end

    -- Transition zu READY wenn fertig
    if progress >= 1.0 then
        self.state = STATE_READY
        WHO_TerminalUI.hasBootedThisSession = true
        print("[WHO] Terminal boot complete - now READY")
    end
end

function WHO_TerminalUI:renderReadyState()
    -- Close-Button im Ready-State sichtbar
    if self.closeBtn then self.closeBtn:setVisible(true) end

    -- Subtitle unter dem Logo
    local subtitle = "// LOGISTICS UPLINK ESTABLISHED"
    local subtitleWidth = getTextManager():MeasureStringX(UIFont.Small, subtitle)
    self:drawText(subtitle,
        (self.width / 2) - (subtitleWidth / 2),
        470,
        COLOR_TEXT_DIM.r, COLOR_TEXT_DIM.g, COLOR_TEXT_DIM.b, COLOR_TEXT_DIM.a,
        UIFont.Small
    )
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

    -- State setzen: wenn schon mal gebootet wurde, direkt zu READY
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