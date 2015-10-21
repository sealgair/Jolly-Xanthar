class = require 'lib/30log/30log'

Indicator = class("Indicator")

function Indicator:init(player)
  self.image = love.graphics.newImage("assets/indicator.png")
  self.w = 5
  self.h = 5

  local tw, th = self.image:getWidth(), self.image:getHeight()
  self.quads = {}
  local x = (player - 1) * self.w
  for i, dir in ipairs(Direction.keys) do
    local y = (i - 1) * self.h
    self.quads[dir] = love.graphics.newQuad(x, y, self.w, self.h, tw, th)
  end
end

function Indicator:draw(x, y, dir)
  if dir == nil then dir = "down" end
  love.graphics.draw(self.image, self.quads[dir], x - self.w/2, y - self.h - 3)
end