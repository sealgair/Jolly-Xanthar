require 'weapons.abstractWeapon'

LaserRifle = Weapon:extend('LaserRifle')

function LaserRifle:init(owner)
  LaserRifle.super.init(self, {
    owner = owner,
    damage = 2,
    rateLimit = 0.15,
    conf = {
      w = 0,
      h = 0,
    },
    ProjectileClass = Tracer,
  })
end

function LaserRifle:start()
  self.tracer = self:fire()
  self.owner.modifiers.speed = function(v) return 0 end
end

function LaserRifle:stop()
  World:despawn(self.tracer)
  self.owner.modifiers.speed = nil
end


Tracer = Impactor:extend("Tracer")

function Tracer:update(dt)
  Tracer.super.update(self, dt)
  self:setCenter(self.owner:center())
  self.color = {219, 207, 68, 128}
end

function Tracer:draw()
  local dir = Point(self.owner:facingDirection())
  local from = self.position + dir * 4
  local to = from + dir * 200
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(self.color)
  love.graphics.line(from.x, from.y, to.x, to.y)
  love.graphics.setColor(r, g, b, a)
end