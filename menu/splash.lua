require "controller"
require "direction"

Splash = {
  items = {
    'start',
    'controls'
  },
  SplashQuads = {}
}

function Splash:load(fsm)
  self.fsm = fsm
  self.background = love.graphics.newImage('assets/Splash.png')
  self.menuImg = love.graphics.newImage('assets/Menu.png')

  local sw, sh = self.menuImg:getWidth(), self.menuImg:getHeight()
  local w, h = 64, 16
  for i, item in ipairs(self.items) do
    y = (i - 1) * h
    self.SplashQuads[i] = {
      inactive = love.graphics.newQuad(0, y, w, h, sw, sh),
      active   = love.graphics.newQuad(w, y, w, h, sw, sh)
    }
  end

  self.activeItem = 1
  Controller:register(self)
  self.controlDirection = Direction(0, 0)
end

function Splash:update(dt)
end

function Splash:setDirection(direction)
  if direction ~= self.controlDirection then
    self.controlDirection = direction
    self.activeItem = wrapping(self.activeItem + self.controlDirection.y, # self.items)
  end
end

function Splash:controlStop(action)
  if action == 'attack' or action == 'pause' then
    self.fsm:advance(self.items[self.activeItem])
  end
end

function Splash:draw()
  love.graphics.draw(self.background, 0, 0)
  for i, quads in ipairs(self.SplashQuads) do
    local state = 'inactive'
    if self.activeItem == i then
      state = 'active'
    end
    i = i - 1
    y = 48 + (i * 16)
    love.graphics.draw(self.menuImg, quads[state], 160, y)
  end
end
