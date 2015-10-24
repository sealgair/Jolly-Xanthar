class = require 'lib/30log/30log'
require 'utils'
require 'direction'
require 'gob'
require 'weapons.bolter'
require 'weapons.teeth'

Mob = Gob:extend('Mob')

function Mob:init(opts)
  Mob.super.init(self, opts)

  if opts.health then
    self.maxHeatlh = opts.health
  else
    self.maxHealth = 10
  end
  self.health = self.maxHealth

  self.splatImg = love.graphics.newImage("assets/particles/damage.png")
  self.splat = love.graphics.newParticleSystem(self.splatImg, 64)
  self.splat:setEmissionRate(32)
  self.splat:setSpread(math.pi)
  self.splat:setSizeVariation(1)
  self.splat:setParticleLifetime(0.1, 0.3)
  self.splat:setRotation(0, 2 * math.pi)
  self.splat:setSpeed(50)
  self.splat:setEmitterLifetime(0)

  self.actions = {}
  self.weapons = {}
end

function Mob:setDirection(newDirection)
  if self:dead() then
    self.direction = Direction(0, 0)
    return
  end

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
  if self:dead() then return end
  self.actions[action] = true

  local weapon = self.weapons[action]
  if weapon ~= nil then
    weapon:start()
  end
end

function Mob:controlStop(action)
  if self:dead() then return end
  self.actions[action] = nil

  local weapon = self.weapons[action]
  if weapon ~= nil then
    weapon:stop()
  end
end

function Mob:animState()
  if self:dead() then
    return "dead"
  else
    return Mob.super.animState(self)
  end
end

function Mob:update(dt)
  if self.agressor and self.agressor:dead() then
    self.agressor = nil
  end

  if self:dead() then
    if self.corpseDecay == nil then
      self.corpseDecay = 20
    else
      self.corpseDecay = self.corpseDecay - dt
    end
    if self.corpseDecay <= 0 then
      World:despawn(self)
    end
  end
  Mob.super.update(self, dt)
  self.splat:update(dt)
  for k, weapon in pairs(self.weapons) do
    weapon:update(dt)
  end
end

function Mob:draw()
  Mob.super.draw(self)
  local center = self:center()
  love.graphics.draw(self.splat, center.x, center.y)
end

function Mob:collidesWith(other)
  if self:dead() then
    return "cross", 50
  elseif other.owner == self then
    return nil, 100
  else
    return Mob.super.collidesWith(self, other)
  end
end

function Mob:hurt(damage, collision)
  self.agressor = collision.other.owner
  self.health = self.health - damage

  local splatDir = Direction(collision.normal.x, collision.normal.y)
  self.splat:setDirection(splatDir:radians())
  self.splat:setEmitterLifetime(0.1)
  self.splat:start()
end

function Mob:collide(cols)
  Mob.super.collide(self, cols)
  if self:dead() then return end
  for _, col in pairs(cols) do
    if col.other.damage then
      self:hurt(col.other.damage, col)
    end
  end
end

function Mob:dead()
  return self.health <= 0
end