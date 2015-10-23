require 'gob'

Weapon = Gob:extend("Weapon")

function Weapon:init(opts)
  -- required: confFile, owner
  -- optional: speed, damage
  self.owner = opts.owner
  opts.dir = self.owner:facingDirection()
  if opts.speed == nil then
    opts.speed = 0
  end
  opts.x = 0
  opts.y = 0
  Weapon.super.init(self, opts)
  local center = self.owner:center()
  self.position = {
    x = center.x - self.w / 2,
    y = center.y - self.h / 2,
  }
  if opts.damage then
    self.damage = opts.damage
  else
    self.damage = 1
  end
  self.done = false
end

function Weapon:collidesWith(b)
  if self.done or b == self.owner then
    return nil, 100
  end
  return "touch", 10
end

function Weapon:collide(cols)
  Weapon.super.collide(self, cols)
  local doneTypes = { touch = true, slide = true, bounce = true }
  for _, col in pairs(cols) do
    if col.other ~= self.owner and doneTypes[col.type] then
      self.done = true
      break
    end
  end
end


Projectile = Weapon:extend("Projectile")

function Projectile:init(opts)
  Projectile.super.init(self, opts)

  if self.conf.particles then
    local pimage = love.graphics.newImage(self.conf.particles.image)
    self.particleSystem = love.graphics.newParticleSystem(pimage, 32)
    self.particleSystem:setSpread(0.5 * math.pi)
    self.particleSystem:setParticleLifetime(0.1, 0.3)
    self.particleSystem:setEmissionRate(20)
    self.particleSystem:setSizeVariation(.5)
    self.particleSystem:setRotation(0, 2 * math.pi)
  end
end

function Projectile:collide(cols)
  Projectile.super.collide(self, cols)
  if self.done then
    self.particleSystem:setEmissionRate(0)
  end
end

function Projectile:update(dt)
  if self.done then
    if self.particleSystem:getCount() <= 0 then
      World:despawn(self)
      return
    end
  end
  Projectile.super.update(self, dt)
  self.particleSystem:setDirection(self.direction:reverse():radians())
  self.particleSystem:setSpeed(self.speed * 0.75)
  self.particleSystem:update(dt)
end


function Projectile:draw()
  if not self.done then
    Projectile.super.draw(self)
  end
  if self.particleSystem then
    local center = self:center()
    love.graphics.draw(self.particleSystem, center.x, center.y)
  end
end

Bolt = Projectile:extend('Bolt')

function Bolt:init(shooter)
  Bolt.super.init(self, {
    owner = shooter,
    confFile = 'assets/weapons/bolt.json',
    speed = 200,
    damage = 1,
  })
end

Bite = Weapon:extend('Bite')

function Bite:init(shooter)
  Bite.super.init(self, {
    owner = shooter,
    confFile = 'assets/weapons/bite.json',
    speed = 0,
    damage = 2,
  })
end

function Bite:update(dt)
  if self.done then
    if self.despawnTimer == nil then
      self.despawnTimer = 0.25
    end
    if self.despawnTimer <= 0 then
      World:despawn(self)
      return
    end
    self.despawnTimer = self.despawnTimer - dt
  end

  Bite.super.update(self, dt)
  self:setDirection(self.owner:facingDirection())

  local pythagoras = 1
  if self.direction.x ~= 0 and self.direction.y ~= 0 then
    -- diagonal, use pythagoras
    pythagoras = 1 / 1.414
  end

  self.position = {
    x = self.owner.position.x + self.w/2 + (self.direction.x * (self.w + self.owner.w)/2 * pythagoras),
    y = self.owner.position.y + self.h/2 + (self.direction.y * (self.w + self.owner.h)/2 * pythagoras),
  }
end