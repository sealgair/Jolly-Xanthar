require 'gob'

Weapon = class("weapon")

function Weapon:init(opts)
  self.owner = opts.owner
  self.projectileOpts = opts
  self.projectileOpts.shooter = self
  self.projectileOpts.owner = self.owner
  self.rateLimit = opts.rateLimit
  if opts.ProjectileClass == nil then
    self.ProjectileClass = Impactor
  else
    self.ProjectileClass = opts.ProjectileClass
  end
  self.cooldown = 0
end

function Weapon:start()
  if self.cooldown <= 0 then
    local bullet = self.ProjectileClass(self.projectileOpts)
    World:spawn(bullet)
    if self.rateLimit then
      self.cooldown = self.rateLimit
    end
    return bullet
  end
end

function Weapon:stop()
end

function Weapon:update(dt)
  if self.cooldown > 0 then
    self.cooldown = self.cooldown - dt
  end
end


Impactor = Gob:extend("Impactor")

function Impactor:init(opts)
  -- required: confFile, owner
  -- optional: speed, damage
  self.owner = opts.owner
  opts.dir = self.owner:facingDirection()
  if opts.speed == nil then
    opts.speed = 0
  end
  opts.x = 0
  opts.y = 0
  self.age = 0
  Impactor.super.init(self, opts)
  self:positionToOwner()
  if opts.damage then
    self.damage = opts.damage
  else
    self.damage = 1
  end
  self.maxAge = opts.maxAge
  self.done = false
end

function Impactor:positionToOwner()
  local center = self.owner:center()
  self.position = {
    x = center.x - self.w / 2,
    y = center.y - self.h / 2,
  }
  self:setDirection(self.owner:facingDirection())
end

function Impactor:update(dt)
  Impactor.super.update(self, dt)
  self.age = self.age + dt
  if self.maxAge and self.age > self.maxAge then
    self.done = true
  end
end

function Impactor:collidesWith(b)
  if self.done or b == self.owner then
    return nil, 100
  end
  return "touch", 10
end

function Impactor:collide(cols)
  Impactor.super.collide(self, cols)
  local doneTypes = { touch = true, slide = true, bounce = true }
  for _, col in pairs(cols) do
    if col.other ~= self.owner and doneTypes[col.type] then
      self:impact(col.other)
      break
    end
  end
end

function Impactor:impact(other)
  self.done = true
end