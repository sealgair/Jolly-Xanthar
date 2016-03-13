class = require 'lib/30log/30log'
require "controller"
require "direction"
require "save"
require "utils"

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
    'controls',
    'quit',
  }
  self.opts = {
    new = "Name Your Ship",
    galaxy = 123456,  -- TODO: generate static seed
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

  graphicsContext({color=Colors.white, font=Fonts.large}, function()
    for i, item in ipairs(self.items) do
      if item == "continue" and not canContinue() then
        love.graphics.setColor(Colors.menuGray)
      end
      if self.activeItem == i then
        love.graphics.setColor(Colors.red)
      else
        love.graphics.setColor(Colors.white)
      end
      i = i - 1
      local y = 48 + (i * 16)
      love.graphics.printf(item:upper(), 160, y, 80, "center")
    end
  end)
end
