class = require 'lib/30log/30log'
require 'utils'
require 'direction'

Player = class('Player')
AnimateInterval = 0.15 --seconds

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
  self.direction = Direction(0, 0)
  self.animationQueue = {}
  self.quad = self.quads.down
  self.animDelay = 0
  self.animLength = 1
end

function Player:advanceQuad()
  if self.animationQueue then
    local newQuad = table.remove(self.animationQueue, 1)
    if newQuad and self.quads[newQuad] then
      self.quad = self.quads[newQuad]
    end
  end
end

function Player:setDirection(newDirection)
  self.direction = newDirection
  if newDirection ~= Direction(0, 0) then
    local oldDirectionKey = invert(self.quads)[self.quad]
    local oldDirection = Direction[oldDirectionKey]

    local ldir = oldDirection
    local rdir = oldDirection
    local lqueue = {}
    local rqueue = {}
    self.animDelay = 0
    while true do
      ldir = ldir:turnLeft()
      rdir = rdir:turnRight()
      table.insert(lqueue, ldir:key())
      table.insert(rqueue, rdir:key())
      if ldir == newDirection then
        self.animationQueue = lqueue
        break
      end
      if rdir == newDirection then
        self.animationQueue = rqueue
        break
      end
    end
    self.animLength = # self.animationQueue
  end
end

function Player:controlStart(action)
  self.actions[action] = true
end

function Player:controlStop(action)
  self.actions[action] = nil
end

function Player:update(dt)
  self.animDelay = self.animDelay - dt

  if self.animDelay <= 0 then
    self:advanceQuad()
    self.animDelay = AnimateInterval / self.animLength
  end
  local distance = dt * self.speed

  self.position.x = self.position.x + (self.direction.x * distance)
  self.position.y = self.position.y + (self.direction.y * distance)
end

function Player:draw()
  love.graphics.draw(
    self.image, self.quad,
    round(self.position.x), round(self.position.y)
  )
end
