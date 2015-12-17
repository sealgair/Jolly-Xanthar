require 'weapons.abstractWeapon'

Bolter = Weapon:extend('Bolter')

function Bolter:init(owner)
  Bolter.super.init(self, {
    owner = owner,
    confFile = 'assets/weapons/bolt.json',
    ProjectileClass = Bolt,
    speed = 200,
    damage = 2,
    rateLimit = 0.15,
  })
end


Bolt = Impactor:extend("Bolt")

function Bolt:init(opts)
  Bolt.super.init(self, opts)

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

function Bolt:impact(other)
  Bolt.super.impact(self, other)
  self.particleSystem:setEmissionRate(0)
end

function Bolt:update(dt)
  if self.done then
    if self.particleSystem:getCount() <= 0 then
      self.owner.world:despawn(self)
      return
    end
  end
  Bolt.super.update(self, dt)
  self.particleSystem:setDirection(self.direction:reverse():radians())
  self.particleSystem:setSpeed(self.speed * 0.75)
  self.particleSystem:update(dt)
end


function Bolt:draw()
  if not self.done then
    Bolt.super.draw(self)
  end
  if self.particleSystem then
    local center = self:center()
    love.graphics.draw(self.particleSystem, center.x, center.y)
  end
end