-- Warehouse Operator - Terminal UI
-- Phase 3a: Statisches DOS-Style Terminal-Fenster
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

-- =========================================================================
-- ASSETS
-- =========================================================================

local LOGO_TEXTURE = getTexture("media/textures/who_logo_boot.png")
local LOGO_WIDTH   = 400
local LOGO_HEIGHT  = 400

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
    -- LOGO zentriert oben
    if LOGO_TEXTURE then
        local logoX = (self.width / 2) - (LOGO_WIDTH / 2)
        local logoY = 40
        self:drawTextureScaled(LOGO_TEXTURE, logoX, logoY, LOGO_WIDTH, LOGO_HEIGHT, 1)
    end

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
    print("[WHO] Terminal opened")
    return terminal
end

print("[WHO] Terminal UI module loaded.")