class = require 'lib/30log/30log'
require 'utils'
require 'direction'

Mob = class('Mob')
AnimateInterval = 0.15 --seconds

function Mob:init(opts)
  -- opts: x, y, bumpWorld, imageFile, speed
  self.bumpWorld = opts.bumpWorld
  self.position = {x=opts.x, y=opts.y}

  self.w, self.h = 16, 16
  self.hitbox = {w=8, h=8}
  self.hitboxOffset = {
    x = (self.w - self.hitbox.w) / 2,
    y = (self.h - self.hitbox.h) / 2,
  }

  self.bumpWorld:add(self,
          self.position.x + self.hitboxOffset.x,
          self.position.y + self.hitboxOffset.y,
          self.hitbox.w, self.hitbox.h)

  if opts.speed == nil then
    self.speed = 40
  else
    self.speed = opts.speed
  end
  self.actions = {}
  self.collisions = {}

  self.image = love.graphics.newImage(opts.imageFile)
  local tw, th = self.image:getWidth(), self.image:getHeight()

  local dirKeys = {
    'down',
    'downleft',
    'left',
    'upleft',
    'up',
    'upright',
    'right',
    'downright',
  }
  self.quads = {}
  for i, dir in ipairs(dirKeys) do
    local quadList = {}
    local y = (i - 1) * self.h
    for x=0, self.w*2, self.w do
      table.insert(quadList, love.graphics.newQuad(x, y, self.w, self.h, tw, th))
    end
    self.quads[dir] = quadList
  end

  self.animFrame = 1
  self.animDelay = AnimateInterval
  self.direction = Direction(0, 0)
  self.animationQueue = {}
  self.facingDir = "down"
  self.turnDelay = 0
  self.animLength = 1
end

function Mob:center()
  return {
    x = self.position.x + round(self.w/2),
    y = self.position.y + round(self.h/2),
  }
end

function Mob:advanceQuad()
  if self.animationQueue then
    local newQuad = table.remove(self.animationQueue, 1)
    if newQuad and self.quads[newQuad] then
      self.facingDir = newQuad
    end
  end
end

function Mob:setDirection(newDirection)
  if newDirection == self.direction or newDirection == nil then
    return
  end

  self.direction = newDirection
  if newDirection ~= Direction(0, 0) then
    local oldDirection = Direction[self.facingDir]
    if oldDirection == newDirection then return end

    local ldir = oldDirection
    local rdir = oldDirection
    local lqueue = {}
    local rqueue = {}
    self.turnDelay = 0
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

function Mob:controlStart(action)
  self.actions[action] = true
end

function Mob:controlStop(action)
  self.actions[action] = nil
end

function Mob:update(dt)
  self.turnDelay = self.turnDelay - dt

  if self.direction ~= Direction(0, 0) then
    self.animDelay = self.animDelay - dt
    if self.animDelay <= 0 then
      self.animDelay = AnimateInterval
      self.animFrame = self.animFrame + 1
      if self.animFrame > 3 then self.animFrame = 2 end
    end
  else
    self.animFrame = 1
  end

  if self.turnDelay <= 0 then
    self:advanceQuad()
    self.turnDelay = AnimateInterval / self.animLength
  end
  local distance = dt * self.speed

  local goal = {
    x = self.position.x + (self.direction.x * distance) + self.hitboxOffset.x,
    y = self.position.y + (self.direction.y * distance) + self.hitboxOffset.y,
  }
  local actualX, actualY, cols, len = self.bumpWorld:move(self, goal.x, goal.y)
  self.collisions = cols
  self.position = {
    x = actualX - self.hitbox.w/2,
    y = actualY - self.hitbox.h/2,
  }
end

function Mob:draw()
  love.graphics.draw(
    self.image, self.quads[self.facingDir][self.animFrame],
    round(self.position.x), round(self.position.y)
  )
end
