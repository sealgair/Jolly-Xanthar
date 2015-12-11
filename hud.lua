class = require 'lib/30log/30log'

HUD = class('HUD')

local PlayerColors = {
  { 255, 0, 0 },
  { 0, 0, 255 },
  { 0, 255, 0 },
  { 255, 255, 0 },
}

local hudBorder = 6

function HUD:init(player, playerIndex)
  self.player = player
  self.index = playerIndex
  self.barHeight = 8

  self.rect = Rect(hudBorder, hudBorder, 64, 32)
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

  self.prevHealth = math.max(self.player.health / self.player.maxHealth, 0)

  love.graphics.push()
  love.graphics.origin()
  self.canvas = love.graphics.newCanvas()
  love.graphics.setCanvas(self.canvas)
  self:drawBase()
  love.graphics.setCanvas()
  love.graphics.pop()
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

function HUD:update(dt)
  local newHealth = math.max(self.player.health / self.player.maxHealth, 0)
  if self.prevHealth > newHealth then
    self.prevHealth = self.prevHealth - dt / 3
  end
end

function HUD:draw()
  love.graphics.push()

  love.graphics.draw(self.canvas)

  local x = self.healthRect.x
  local y = self.healthRect.y
  local w = self.healthRect.w
  local h = self.healthRect.h

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

  love.graphics.setColor(255, 255, 255)
  love.graphics.pop()
end