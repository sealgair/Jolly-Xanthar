class = require 'lib/30log/30log'

Player = class('Player')

function Player:init()
  self.position = {x=10, y=10}
  self.speed = 10
  self.velocity = {x=0, y=0}

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
  if action == "up" then
    self.velocity.y = -self.speed
  elseif action == "down" then
    self.velocity.y = self.speed
  elseif action == "left" then
    self.velocity.x = -self.speed
  elseif action == "right" then
    self.velocity.x = self.speed
  end
  if self.quads[action] then
    self.quad = self.quads[action]
  end
end

function Player:controlStop(action)
  if action == "up" or action == "down" then
    self.velocity.y = 0
  elseif action == "left" or action == "right" then
    self.velocity.x = 0
  end
end

function Player:update(dt)
  self.position.x = self.position.x + dt * self.velocity.x
  self.position.y = self.position.y + dt * self.velocity.y
end

function Player:draw()
  love.graphics.draw(self.image, self.quad, round(self.position.x), round(self.position.y))
end
