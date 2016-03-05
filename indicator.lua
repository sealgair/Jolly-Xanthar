class = require 'lib/30log/30log'
require('utils')

Indicator = class("Indicator")

function Indicator:init(player)
  self.pid = player
  self.image = love.graphics.newImage("assets/indicator.png")
  self.w = 5
  self.h = 5

  local tw, th = self.image:getWidth(), self.image:getHeight()
  self.quads = {}
  for i, dir in ipairs(Direction.keys) do
    local y = (i - 1) * self.h
    self.quads[dir] = love.graphics.newQuad(0, y, self.w, self.h, tw, th)
  end
end

function Indicator:draw(x, y, dir)
  y = y - self.h/2
  dir = coalesce(dir, "down")

  if dir:find("up") then
    y = y + self.h
  elseif dir:find("down") then
    y = y - self.h
  end

  if dir:find("left") then
    x = x + self.w
  elseif dir:find("right") then
    x = x - self.w
  end
  graphicsContext({color=PlayerColors[self.pid]}, function()
    love.graphics.draw(self.image, self.quads[dir], x - self.w/2, y)
  end)
end