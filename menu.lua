require "PlayerController"
require "direction"

Menu = {
  items = {
    'start',
    'controls'
  },
  menuQuads = {}
}

function Menu:load(fsm)
  self.fsm = fsm
  self.background = love.graphics.newImage('assets/Splash.png')
  self.menuImg = love.graphics.newImage('assets/Menu.png')

  local sw, sh = self.menuImg:getWidth(), self.menuImg:getHeight()
  local w, h = 64, 16
  for i, item in ipairs(self.items) do
    y = (i - 1) * h
    self.menuQuads[i] = {
      inactive = love.graphics.newQuad(0, y, w, h, sw, sh),
      active   = love.graphics.newQuad(w, y, w, h, sw, sh)
    }
  end

  self.active = 1
  PlayerController:register(self)
  self.controlDirection = Direction(0, 0)
end

function Menu:update(dt)
end

function Menu:setDirection(direction)
  if direction ~= self.controlDirection then
    self.controlDirection = direction
    self.active = wrapping(self.active + self.controlDirection.y, # self.items)
  end
end

function Menu:controlStop(action)
  if action == 'attack' or action == 'pause' then
    self.fsm:advance(self.items[self.active])
  end
end

function Menu:draw()
  love.graphics.draw(self.background, 0, 0)
  for i, quads in ipairs(self.menuQuads) do
    local state = 'inactive'
    if self.active == i then
      state = 'active'
    end
    i = i - 1
    y = 48 + (i * 16)
    love.graphics.draw(self.menuImg, quads[state], 160, y)
  end
end
