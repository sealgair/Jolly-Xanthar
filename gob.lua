class = require 'lib/30log/30log'
json = require 'lib.json4lua.json.json'
require 'utils'
require 'direction'

Gob = class('Gob')
DefaultAnimateInterval = 0.15 --seconds

function Gob:init(opts)
  -- required opts: x, y, confFile
  -- optional opts: speed, dir, animDelay
  self.position = { x = opts.x, y = opts.y }
  local conf, _ = love.filesystem.read(opts.confFile)
  self.conf = json.decode(conf)

  self.w = self.conf.w
  self.h = self.conf.h
  self.hitbox = self.conf.hitbox
  self.animations = self.conf.animations

  if opts.speed == nil then
    self.speed = 40
  else
    self.speed = opts.speed
  end
  if opts.dir == nil then
    self.direction = Direction(0, 0)
  else
    self.direction = opts.dir
  end
  if opts.animInterval == nil then
    if self.conf.animInterval == nil then
      self.animInterval = DefaultAnimateInterval
    else
      self.animInterval = self.conf.animInterval
    end
  else
    self.animInterval = opts.animInterval
  end

  self.collisions = {}

  self.image = love.graphics.newImage(self.conf.image)
  local tw, th = self.image:getWidth(), self.image:getHeight()

  self.quads = {}
  for i, dir in ipairs(Direction.keys) do
    local quadList = {}
    local y = (i - 1) * self.h
    for x = 0, tw - self.w, self.w do
      table.insert(quadList, love.graphics.newQuad(x, y, self.w, self.h, tw, th))
    end
    self.quads[dir] = quadList
  end

  self.animIndex = 1
  self.animDelay = self.animInterval
  self.animationQueue = {}
  if self.direction == Direction(0, 0) then
    self.facingDir = "down"
  else
    self.facingDir = self.direction:key()
  end
  self.turnDelay = 0
  self.animLength = 1
end

function Gob:center()
  return {
    x = self.position.x + self.w / 2,
    y = self.position.y + self.h / 2,
  }
end

function Gob:setDirection(newDirection)
  self.direction = newDirection
  self.facingDir = self.direction:key()
end

function Gob:facingDirection()
  return Direction[self.facingDir]
end

function Gob:advanceQuad()
  if self.animationQueue then
    local newDirKey = table.remove(self.animationQueue, 1)
    if newDirKey and self.quads[newDirKey] then
      self.facingDir = newDirKey
    end
  end
end

function Gob:getBoundingBox()
  return {
    x = self.position.x + self.hitbox.x,
    y = self.position.y + self.hitbox.y,
  }
end

function Gob:setBoundingBox(box)
  self.position = {
    x = box.x - self.hitbox.x,
    y = box.y - self.hitbox.y,
  }
end

function Gob:animState()
  if self.direction ~= Direction(0, 0) then
    return "walk"
  else
    return "idle"
  end
end

function Gob:update(dt)
  self.turnDelay = self.turnDelay - dt
  self.animDelay = self.animDelay - dt

  local animFrames = self.animations[self:animState()]
  if self.animDelay <= 0 then
    self.animDelay = self.animInterval
    self.animIndex = self.animIndex + 1
    if self.animIndex > #animFrames then self.animIndex = 1 end
  end

  if self.turnDelay <= 0 then
    self:advanceQuad()
    self.turnDelay = self.animInterval / self.animLength
  end
  local distance = dt * self.speed

  if self.direction.x ~= 0 and self.direction.y ~= 0 then
    -- diagonal, use pythagoras
    distance = distance / 1.414
  end

  self.position = {
    x = self.position.x + self.direction.x * distance,
    y = self.position.y + self.direction.y * distance,
  }
end

function Gob:collidesWith(other)
  return "slide", 0
end

function Gob.collideFilter(a, b)
  local typeA, priorityA = a:collidesWith(b)
  local typeB, priorityB = b:collidesWith(a)
  if priorityA > priorityB then
    return typeA
  else
    return typeB
  end
end

function Gob:collide(cols)
  self.collisions = cols
end

function Gob:draw()
  local animFrames = self.animations[self:animState()]
  local animFrame = animFrames[math.min(self.animIndex, #animFrames)]
  love.graphics.draw(self.image,
    self.quads[self.facingDir][animFrame],
    self.position.x,
    self.position.y)
end
