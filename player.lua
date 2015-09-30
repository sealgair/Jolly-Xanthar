class = require 'lib/30log/30log'

Player = class('Player')

function Player:init()
  self.position = {x=10, y=10}
  self.speed = 20
  self.actions = {}

  self.image = love.graphics.newImage('assets/critters.png')
  self.image:setFilter("nearest", "nearest")
  local w, h = 32, 32
  local tw, th = self.image:getWidth(), self.image:getHeight()
  self.quads = {
    down = love.graphics.newQuad(0, 64, w, h, tw, th),
    up = love.graphics.newQuad(0, 96, w, h, tw, th),
    right = love.graphics.newQuad(0, 128, w, h, tw, th),
    left = love.graphics.newQuad(0, 160, w, h, tw, th),
  }
  self.quad = self.quads.down
end

function Player:controlStart(action)
  self.actions[action] = true

  if self.quads[action] then
    self.quad = self.quads[action]
  end
end

function Player:controlStop(action)
  self.actions[action] = nil

  if self.quads[action] then
    for action, v in pairs(self.actions) do
      if self.quads[action] then
        self.quad = self.quads[action]
        break
      end
    end
  end
end

function Player:update(dt)
  local distance = dt * self.speed
  for action, v in pairs(self.actions) do
    if action == "up" then
      self.position.y = self.position.y - distance
    elseif action == "down" then
      self.position.y = self.position.y + distance
    elseif action == "left" then
      self.position.x = self.position.x - distance
    elseif action == "right" then
      self.position.x = self.position.x + distance
    end
  end
end

function Player:draw()
  love.graphics.draw(self.image, self.quad, round(self.position.x), round(self.position.y))
end
