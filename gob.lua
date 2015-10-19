class = require 'lib/30log/30log'
json = require 'lib.json4lua.json.json'
require 'utils'
require 'direction'

Gob = class('Gob')
DefaultAnimateInterval = 0.15 --seconds

function Gob:init(opts)
  -- required opts: x, y, confFile
  -- optional opts: speed, dir, animDelay
  self.position = {x=opts.x, y=opts.y}
  local conf, _ = love.filesystem.read(opts.confFile)
  conf = json.decode(conf)

  self.w = conf.w
  self.h = conf.h
  self.hitbox = conf.hitbox

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
    if conf.animInterval == nil then
      self.animInterval = DefaultAnimateInterval
    else
      self.animInterval = conf.animInterval
    end
  else
    self.animInterval = opts.animInterval
  end

  self.collisions = {}

  self.image = love.graphics.newImage(conf.image)
  local tw, th = self.image:getWidth(), self.image:getHeight()

  self.quads = {}
  for i, dir in ipairs(Direction.keys) do
    local quadList = {}
    local y = (i - 1) * self.h
    for x=0, self.w*2, self.w do
      table.insert(quadList, love.graphics.newQuad(x, y, self.w, self.h, tw, th))
    end
    self.quads[dir] = quadList
  end

  self.animFrame = 1
  self.animDelay = self.animInterval
  self.animationQueue = {}
  self.facingDir = "down"
  self.turnDelay = 0
  self.animLength = 1
end

function Gob:center()
  return {
    x = self.position.x + round(self.w/2),
    y = self.position.y + round(self.h/2),
  }
end

function Gob:advanceQuad()
  if self.animationQueue then
    local newQuad = table.remove(self.animationQueue, 1)
    if newQuad and self.quads[newQuad] then
      self.facingDir = newQuad
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


function Gob:update(dt)
  self.turnDelay = self.turnDelay - dt

  if self.direction ~= Direction(0, 0) then
    self.animDelay = self.animDelay - dt
    if self.animDelay <= 0 then
      self.animDelay = self.animInterval
      self.animFrame = self.animFrame + 1
      if self.animFrame > 3 then self.animFrame = 2 end
    end
  else
    self.animFrame = 1
  end

  if self.turnDelay <= 0 then
    self:advanceQuad()
    self.turnDelay = self.animInterval / self.animLength
  end
  local distance = dt * self.speed

  self.position = {
    x = self.position.x + self.direction.x * distance,
    y = self.position.y + self.direction.y * distance,
  }
end

function Gob:collide(cols)
  self.collisions = cols
end

function Gob:draw()
  love.graphics.draw(
    self.image, self.quads[self.facingDir][self.animFrame],
    round(self.position.x), round(self.position.y)
  )
end
