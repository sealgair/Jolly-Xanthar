require 'menu.abstractMenu'

HUD = Menu:extend('HUD')

local PlayerColors = {
  { 255, 0, 0 },
  { 0, 0, 255 },
  { 0, 255, 0 },
  { 255, 255, 0 },
}

local hudBorder = 4

function HUD:init(player, playerIndex)
  HUD.super.init(self)
  self.player = player
  self.index = playerIndex
  self.barHeight = 11
  self.menuHeight = 64
  self.active = true

  self.rect = Rect(hudBorder, hudBorder, 64, self.barHeight)
  if self.index == 2 or self.index == 4 then
    self.rect.x = GameSize.w - self.rect.w - hudBorder
  end
  if self.index == 3 or self.index == 4 then
    self.rect.y = GameSize.h - self.rect.h - hudBorder
  end

  self.color = PlayerColors[self.index]
  self.shadowColor = map(self.color, function(c)
    return c * 0.5
  end)

  if self.player then
    self.prevHealth = math.max(self.player.health / self.player.maxHealth, 0)
  else
    self.prevHealth = 0
  end

  love.graphics.push()
  love.graphics.origin()
  self.canvas = love.graphics.newCanvas()
  love.graphics.setCanvas(self.canvas)
  self:drawBase()
  love.graphics.setCanvas()
  love.graphics.pop()

  self.menuCanvas = love.graphics.newCanvas(self.rect.w, GameSize.h)
  self.menuOffset = 0
  self.newMenuOffset = self.menuOffset
end


function HUD:drawBase()
  love.graphics.push()

  love.graphics.setColor(self.shadowColor)
  local x = self.rect.x
  local y = self.rect.y
  local w = self.rect.w
  local h = self.barHeight
  if self.index > 2 then
    y = self.rect.y + self.rect.h - h
  end
  love.graphics.rectangle("fill", x, y, w, h)

  love.graphics.setColor(self.color)
  x = x + 1
  y = y + 1
  w = w - 2
  h = h - 2
  love.graphics.rectangle("fill", x, y, w, h)

  love.graphics.setColor(0, 0, 0)
  x = x + 1
  y = y + 1
  w = w - 2
  h = h - 2
  love.graphics.rectangle("fill", x, y, w, h)

  love.graphics.setColor(255, 255, 255)
  love.graphics.pop()

  self.healthRect = Rect{ x = x, y = y, w = w, h = h, }
end

function HUD:drawMenuCanvas()
  love.graphics.push()
  love.graphics.setCanvas(self.menuCanvas)
  love.graphics.origin()
  love.graphics.setBackgroundColor(0, 0, 0, 127)
  love.graphics.clear()

  local y = 1
  local w = self.rect.w
  local font = Fonts[10]
  love.graphics.setFont(font)
  local fh = font:getHeight()

  local offset = 0
  for r, row in ipairs(self.itemGrid) do
    local item = row[1]

    local rowHeight = fh * math.ceil(font:getWidth(item.name) / w)

    if r == self.selected.y then
      love.graphics.setColor(255, 0, 0)
      offset = y
    else
      love.graphics.setColor(255, 255, 255)
    end
    love.graphics.printf(item.name, 0, y, w, "center")
    y = y + rowHeight + 1
  end

  love.graphics.setCanvas()
  love.graphics.pop()
  love.graphics.setColor(255, 255, 255)

  self.newMenuOffset = math.min(offset, y - self.menuHeight)
end

function HUD:controlStop(action)
  if self.player then
  else
    if action == 'start' then
      local p = self:selectedItem()
      if p then
        World:addPlayer(p, self.index)
        self.itemGrid = {}
      else
        self.itemGrid = map(World:remainingRoster(), function(n) return {n} end)
        self:drawMenuCanvas()
      end
    end
  end
end

function HUD:setDirection(direction)
  HUD.super.setDirection(self, direction)
  if #self.itemGrid > 0 then
    self:drawMenuCanvas()
  end
end

function HUD:update(dt)
  if self.player then
    local newHealth = math.max(self.player.health / self.player.maxHealth, 0)
    if self.prevHealth > newHealth then
      self.prevHealth = self.prevHealth - dt / 3
    end
  end

  if #self.itemGrid > 0 then
    local move = 150 * dt
    if self.menuOffset > self.newMenuOffset then
      self.menuOffset = math.max(
        self.menuOffset - move,
        self.newMenuOffset
      )
    elseif self.menuOffset < self.newMenuOffset then
      self.menuOffset = math.min(
        self.menuOffset + move,
        self.newMenuOffset
      )
    end
    local sw, sh = self.menuCanvas:getDimensions()
    self.menuQuad = love.graphics.newQuad(0, self.menuOffset, sw, self.menuHeight, sw, sh)
  end
end

function HUD:draw()
  love.graphics.push()

  love.graphics.draw(self.canvas)

  local x = self.healthRect.x
  local y = self.healthRect.y
  local w = self.healthRect.w
  local h = self.healthRect.h

  if self.player then
    local healthPercent = math.max(self.player.health / self.player.maxHealth, 0)
    if healthPercent < self.prevHealth then
      local healthColor = {
        255 * math.min(2 + (self.prevHealth * -2), 1),
        255 * math.min(self.prevHealth * 2, 1),
        0
      }
      healthColor = map(healthColor, function(c) return c * 0.75 end)
      love.graphics.setColor(healthColor)
      love.graphics.rectangle("fill", x, y, w * self.prevHealth, h)
    end

    local healthColor = {
      255 * math.min(2 + (healthPercent * -2), 1),
      255 * math.min(healthPercent * 2, 1),
      0
    }
    love.graphics.setColor(healthColor)
    love.graphics.rectangle("fill", x, y, w * healthPercent, h)

    local barWidth = w / self.player.maxHealth
    if barWidth >= 4 then
      healthColor = map(healthColor, function(c) return c * 0.75 end)
      love.graphics.setColor(healthColor)
      local barX = x
      for i = 1, self.player.health - 1 do
        barX = barX + barWidth
        love.graphics.rectangle("fill", barX, y, 1, h)
      end
    end
  else
    love.graphics.setColor(255, 255, 255)
    love.graphics.setFont(Fonts[10])
    love.graphics.printf("Press Start", x, y, w, "center")
  end
  if #self.itemGrid > 0 then
    love.graphics.draw(self.menuCanvas, self.menuQuad, self.rect.x, self.rect:bottom())
  end

  love.graphics.setColor(255, 255, 255)
  love.graphics.pop()
end