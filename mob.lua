class = require 'lib/30log/30log'
require 'utils'
require 'direction'
require 'gob'
require 'projectile'

Mob = Gob:extend('Mob')

function Mob:init(opts)
  Mob.super.init(self, opts)

  if opts.health then
    self.maxHeatlh = opts.health
  else
    self.maxHealth = 10
  end
  self.health = self.maxHealth

  self.actions = {}
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
end

function Mob:controlStop(action)
  if self:dead() then return end
  self.actions[action] = nil
  local facingDirection = Direction[self.facingDir]
  local shoot = self:center()
  shoot.x = shoot.x - 4
  shoot.y = shoot.y - 4

  if action == 'a' then
    local bullet = Projectile{
      owner=self,
      confFile = 'assets/projectiles/bolt.json',
      x = shoot.x,
      y = shoot.y,
      dir = facingDirection,
      speed = 200,
      damage=10,
    }
    World:spawn(bullet)
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
  if self:dead() then
--    World:despawn(self)
    return
  end

  Mob.super.update(self, dt)
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

function Mob:collide(cols)
  Mob.super.collide(self, cols)
  for _, col in pairs(cols) do
    if col.other.damage then
      self.health = self.health - col.other.damage
    end
  end
end

function Mob:dead()
  return self.health <= 0
end