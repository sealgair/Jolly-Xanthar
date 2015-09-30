class = require 'lib/30log/30log'

Player = class('Player')

function Player:init()
  self.position = {x=10, y=10}
  self.speed = 20
  self.actions = {}

  self.image = love.graphics.newImage('assets/human.png')
  self.image:setFilter("nearest", "nearest")
  local w, h = 16, 16
  local tw, th = self.image:getWidth(), self.image:getHeight()
  self.quads = {
    down = love.graphics.newQuad(0, 0, w, h, tw, th),
    downleft = love.graphics.newQuad(0, 16, w, h, tw, th),
    left = love.graphics.newQuad(0, 32, w, h, tw, th),
    upleft = love.graphics.newQuad(0, 48, w, h, tw, th),
    up = love.graphics.newQuad(0, 64, w, h, tw, th),
    upright = love.graphics.newQuad(0, 80, w, h, tw, th),
    right = love.graphics.newQuad(0, 96, w, h, tw, th),
    downright = love.graphics.newQuad(0, 112, w, h, tw, th),
  }
  self.quad = self.quads.down
end

function Player:updateQuad()
  local quadKey = ""
  if self.actions.up then
    quadKey = "up"
  elseif self.actions.down then
    quadKey = "down"
  end
  if self.actions.left then
    quadKey = quadKey .. "left"
  elseif self.actions.right then
    quadKey = quadKey .. "right"
  end
  if self.quads[quadKey] then
    self.quad = self.quads[quadKey]
  end
end

function Player:controlStart(action)
  self.actions[action] = true
  self:updateQuad()
end

function Player:controlStop(action)
  self.actions[action] = nil
  self:updateQuad()
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
