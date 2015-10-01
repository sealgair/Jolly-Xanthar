class = require 'lib/30log/30log'
require 'utils'

Player = class('Player')
AnimateInterval = 0.1 --seconds

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
  self.clockwise = {
    down = 'downleft',
    downleft = 'left',
    left = 'upleft',
    upleft = 'up',
    up = 'upright',
    upright = 'right',
    right = 'downright',
    downright = 'down'
  }
  self.counterclockwise = invert(self.clockwise)
  self.animationQueue = {}
  self.direction = 'down'
  self.animDelay = 0
end

function Player:updateQuad()
  local nextDir = ""
  if self.actions.up then
    nextDir = "up"
  elseif self.actions.down then
    nextDir = "down"
  end
  if self.actions.left then
    nextDir = nextDir .. "left"
  elseif self.actions.right then
    nextDir = nextDir .. "right"
  end

  if nextDir ~= "" and nextDir ~= self.direction then
    local ldir = self.direction
    local rdir = self.direction
    local lqueue = {}
    local rqueue = {}
    self.animDelay = 0
    while true do
      ldir = self.clockwise[ldir]
      rdir = self.counterclockwise[rdir]
      table.insert(lqueue, ldir)
      table.insert(rqueue, rdir)
      if ldir == nextDir then
        self.animationQueue = lqueue
        break
      end
      if rdir == nextDir then
        self.animationQueue = rqueue
        break
      end
    end
  end
end

function Player:advanceDir()
  if self.animationQueue then
    local newDir = table.remove(self.animationQueue, 1)
    if newDir then
      self.direction = newDir
    end
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
  self.animDelay = self.animDelay - dt
  if self.animDelay <= 0 then
    self:advanceDir()
    self.animDelay = AnimateInterval
  end
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
  local quad = self.quads[self.direction]
  if quad then
  love.graphics.draw(
    self.image, quad,
    round(self.position.x), round(self.position.y)
  )
  end
end
