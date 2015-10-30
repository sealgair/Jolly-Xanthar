class = require 'lib/30log/30log'
json = require 'lib.json4lua.json.json'
require 'utils'
require 'direction'
require 'position'

Gob = class('Gob')
DefaultAnimateInterval = 0.15 --seconds

function Gob:init(opts)
  -- required opts: x, y, confFile
  -- optional opts: speed, dir, animDelay
  self.position = Point(opts)
  if opts.conf then
    self.conf = opts.conf
  else
    local confData, _ = love.filesystem.read(opts.confFile)
    self.conf = json.decode(confData)
  end

  self.w = self.conf.w
  self.h = self.conf.h
  self.hitbox = Rect(self.conf.hitbox)
  self.animations = self.conf.animations

  self.speed = coalesce(opts.speed, 40)
  self.direction = coalesce(opts.dir, Direction(0, 0))
  self.animInterval = coalesce(opts.animInterval, self.conf.animInterval, DefaultAnimateInterval)
  self.collisions = {}

  if opts.image then
    self.image = opts.image
  else
    self.image = love.graphics.newImage(self.conf.image)
  end
  local tw, th = self.image:getWidth(), self.image:getHeight()
  if opts.shader then
    local canvas = love.graphics.newCanvas(tw, th)
    love.graphics.setCanvas(canvas)
    love.graphics.setShader(opts.shader)
    love.graphics.draw(self.image)
    love.graphics.setShader()
    love.graphics.setCanvas()
    self.image = canvas
  end

  self.quads = opts.quads
  if opts.quads == nil then
    self.quads = {}
    for i, dir in ipairs(Direction.keys) do
      local quadList = {}
      local y = (i - 1) * self.h
      for x = 0, tw - self.w, self.w do
        table.insert(quadList, love.graphics.newQuad(x, y, self.w, self.h, tw, th))
      end
      self.quads[dir] = quadList
    end
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

function Gob:rect()
  return Rect(self.position, self.w, self.h)
end

function Gob:center()
  return self:rect():center()
end

function Gob:setDirection(newDirection)
  self.direction = newDirection
  if self.direction ~= Direction(0, 0) then
    self.facingDir = self.direction:key()
  end
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
  return self.hitbox:origin() + self.position
end

function Gob:setBoundingBox(box)
  self.position = box - self.hitbox:origin()
end

function Gob:animState()
  if self.direction ~= Direction(0, 0) then
    return "walk"
  else
    return "idle"
  end
end

function Gob:animFrames()
  return coalesce(self.animations[self:animState()], self.animations["idle"])
end

function Gob:update(dt)
  self.turnDelay = self.turnDelay - dt
  self.animDelay = self.animDelay - dt

  if self.animDelay <= 0 then
    self.animDelay = self.animInterval
    self.animIndex = self.animIndex + 1
    if self.animIndex > #self:animFrames() then self.animIndex = 1 end
  end

  if self.turnDelay <= 0 then
    self:advanceQuad()
    self.turnDelay = self.animInterval / self.animLength
  end
  local distance = dt * self.speed

  if self.direction:isDiagonal() then
    -- diagonal, use pythagoras
    distance = distance / 1.414
  end

  self.position = self.position + (Point(self.direction) * distance)
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
  local animFrames = self:animFrames()
  local animFrame = animFrames[math.min(self.animIndex, #animFrames)]
  love.graphics.draw(self.image,
    self.quads[self.facingDir][animFrame],
    self.position.x,
    self.position.y)
end
