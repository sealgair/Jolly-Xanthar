require 'gob'

Projectile = Gob:extend("Projectile")


function Projectile:init(opts)
  Projectile.super.init(self, opts)
  self.done = false
  self.owner = opts.owner
  if opts.damage then
    self.damage = opts.damage
  else
    self.damage = 1
  end
  if self.conf.particles then
    local pimage = love.graphics.newImage(self.conf.particles.image)
    self.particleSystem = love.graphics.newParticleSystem(pimage, 32)
    self.particleSystem:setSpread(0.5 * math.pi)
    self.particleSystem:setParticleLifetime(0.1, 0.3)
    self.particleSystem:setEmissionRate(20)
    self.particleSystem:setSizeVariation(.5)
    self.particleSystem:setRotation(0, 2*math.pi)
  end
end


function Projectile:collidesWith(b)
  return "touch", 10
end


function Projectile:collide(cols)
  Projectile.super.collide(self, cols)

  for _, col in pairs(cols) do
    if col.other ~= self.owner then
      self.done = true
      break
    end
  end
end


function Projectile:update(dt)
  if self.done then
    World:despawn(self)
    return
  end
  Projectile.super.update(self, dt)
  self.particleSystem:setDirection(self.direction:reverse():radians())
  self.particleSystem:setSpeed(self.speed)
  self.particleSystem:update(dt)
end


function Projectile:draw()
  Projectile.super.draw(self)
  if self.particleSystem then
    local center = self:center()
    love.graphics.draw(self.particleSystem, center.x, center.y)
  end
end