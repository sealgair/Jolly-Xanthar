class = require 'lib/30log/30log'

HUD = class('HUD')

local PlayerColors = {
  { 255, 0, 0 },
  { 0, 0, 255 },
  { 0, 255, 0 },
  { 255, 255, 0 },
}

function HUD:init(player, playerIndex)
  self.player = player

  self.rect = {
    x = 0,
    y = 0,
    w = 64,
    h = 32
  }
  if playerIndex == 2 or playerIndex == 4 then
    self.rect.x = Size.w - self.rect.w
  end
  if playerIndex == 3 or playerIndex == 4 then
    self.rect.y = Size.h - self.rect.h
  end
  self.color = PlayerColors[playerIndex]
  self.shadowColor = map(self.color, function(c)
    return c * 0.5
  end)
end

function HUD:draw()
  love.graphics.push()

  love.graphics.setColor(self.shadowColor)
  local x = self.rect.x + 2
  local y = self.rect.y + 2
  local w = self.rect.w - 4
  local h = 8
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

  local healthPercent = math.max(self.player.health / self.player.maxHealth, 0)
  love.graphics.setColor(
    255 * math.min(2 + (healthPercent * -2), 1),
    255 * math.min(healthPercent * 2, 1),
    0
  )
  w = w * healthPercent
  love.graphics.rectangle("fill", x, y, w, h)

  love.graphics.setColor(255, 255, 255)
  love.graphics.pop()
end