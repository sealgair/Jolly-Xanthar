class = require 'lib/30log/30log'
require "controller"
require "direction"
require "save"

Splash = class("Splash")

function canContinue()
  return #Save:shipNames() > 0
end

function Splash:init(fsm)
  self.fsm = fsm
  self.background = love.graphics.newImage('assets/Splash.png')
  self.items = {
    'continue',
    'new',
    'galaxy',
    'controls',
  }
  self.opts = {
    new = "Name Your Ship"
  }

  if canContinue() then
    self.activeItem = 1
  else
    self.activeItem = 2
  end
  Controller:register(self, 1)
  self.controlDirection = Direction(0, 0)
end

function Splash:update(dt)
end

function Splash:setDirection(direction)
  if direction ~= self.controlDirection then
    self.controlDirection = direction
    self.activeItem = wrapping(self.activeItem + self.controlDirection.y, # self.items)
    if self.activeItem == 1 and not canContinue() then
      -- advance one more
      self.activeItem = wrapping(self.activeItem + self.controlDirection.y, # self.items)
    end
  end
end

function Splash:controlStop(action)
  if action == 'a' or action == 'start' then
    local item = self.items[self.activeItem]
    local opt = self.opts[item]
    self.fsm:advance(item, opt)
  end
end

function Splash:draw()
  love.graphics.draw(self.background, 0, 0)
  local pos = Point(160, 48)
  local w = 64
  for i, item in ipairs(self.items) do
    local color = Colors.white
    if self.activeItem == i then
      color = Colors.red
    end
    graphicsContext({color=color, font=Fonts.large}, function()
      love.graphics.printf(item:upper(), pos.x, pos.y, w, "center")
    end)
    pos = pos + Point(0, 16)
  end
end
