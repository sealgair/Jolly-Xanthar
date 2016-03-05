class = require 'lib/30log/30log'
require 'utils'
require 'direction'
require 'gob'
require 'weapons.bolter'
require 'weapons.teeth'

Mob = Gob:extend('Mob')

function Mob:init(opts)
  self.maxHealth = coalesce(opts.health, 10)
  self.health = self.maxHealth
  self.momentum = coalesce(opts.momentum, 10)
  self.stunFactor = coalesce(opts.stunFactor, 0)
  self.minHealth = -self.stunFactor * self.maxHealth

  Mob.super.init(self, opts)

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
  self.hasHurt = {}

  self.modifiers = {}
end

function Mob:setDirection(newDirection)
  if self:stunned() then
    self.direction = Direction(0, 0)
    return
  end

  if self.modifiers.newDirection then
    newDirection = self.modifiers.newDirection(newDirection)
  end

  if newDirection == self.direction or newDirection == nil then
    return
  end

  local oldDirection = self:facingDirection()
  Mob.super.setDirection(self, newDirection)

  if newDirection ~= Direction(0, 0) then
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
    self.animLength = #self.animationQueue
  end
end

function Mob:controlStart(action)
  if self:stunned() then return end
  self.actions[action] = true

  if self.controlOverride then
    self.controlOverride:controlStart(self, action)
  else
    local weapon = self.weapons[action]
    if weapon ~= nil then
      weapon:start()
    end
  end
end

function Mob:controlStop(action)
  if self:stunned() then return end
  self.actions[action] = nil

  if self.controlOverride then
    self.controlOverride:controlStop(self, action)
  else
    local weapon = self.weapons[action]
    if weapon ~= nil then
      weapon:stop()
    end
  end
end

function Mob:descend(verb)
  self.world:descend(self, verb)
end

function Mob:animState()
  if self:dead() then
    return "dead"
  elseif self:stunned() then
    return "stunned"
  else
    return Mob.super.animState(self)
  end
end

function Mob:update(dt)
  local modified = {}
  for k, modifier in pairs(self.modifiers) do
    modified[k] = self[k]
    self[k] = modifier(self[k])
  end

  if self.agressor and self.agressor:dead() then
    self.agressor = nil
  end
  if self.hurting then
    self.hurting = self.hurting - dt
    if self.hurting <= 0 then
      self.hurting = nil
    end
  end

  if self:dead() then
    if self.corpseDecay == nil then
      self.corpseDecay = 10
    else
      self.corpseDecay = self.corpseDecay - dt
    end
    if self.corpseDecay <= 0 then
      self.world:despawn(self)
    end
  elseif self:stunned() then
    if self.rescueTime == nil then
      self.health = self.health - dt
    end
  end
  Mob.super.update(self, dt)

  self.splat:update(dt)
  for k, weapon in pairs(self.weapons) do
    weapon:update(dt)
  end

  for k, val in pairs(modified) do
    self[k] = val
  end
end

function Mob:draw()
  love.graphics.push()
  if self.hurting then
    love.graphics.setColor(255, 0, 0)
  end
  Mob.super.draw(self)
  love.graphics.setColor(255, 255, 255)
  local center = self:center()
  love.graphics.draw(self.splat, center.x, center.y)
  love.graphics.pop()

  if self:stunned() and not self:dead() then
    graphicsContext({
      color={255, 0, 0 },
      font=Fonts.medium,
    },
    function()
      local coord = self:center() - Point(self.w/2, self.h)
      love.graphics.printf(math.ceil(self.health - self.minHealth), coord.x, coord.y, self.w, "center")
    end)
  end
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
  if self.agressor == self then
    local poop
    poop.pee()
  end
  self.health = self.health - damage
  if not self:dead() then
    self:shove(Point(collision.other.direction), 75 * damage)
  end
  self.hurting = self.animInterval

  if collision.normal then
    local splatDir = Direction(collision.normal.x, collision.normal.y)
    self.splat:setDirection(splatDir:radians())
  end
  self.splat:setEmitterLifetime(0.1)
  self.splat:start()

  if self:dead() then
    for weapon in values(self.weapons) do
      weapon:stop()
    end
  end
end

function Mob:collide(cols)
  Mob.super.collide(self, cols)
  if self:dead() then return end
  for _, col in pairs(cols) do
    if col.other.damage and col.other.damage > 0 and not self.hasHurt[col.other] then
      self:hurt(col.other.damage, col)
      self.hasHurt[col.other] = true  -- hurt me once, shame on you... (TODO: timeout?)
    end
  end
end

function Mob:stunned()
  return self.health <= 0
end

function Mob:dead()
  return self.health <= self.minHealth
end