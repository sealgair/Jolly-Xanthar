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
    rateLimit = 1,
  })
end

function LaserRifle:start()
  self.tracer = self:fire()
  if self.tracer then
    self.owner.modifiers.speed = function() return 0 end
    self.cooldown = 0
  end
end

function LaserRifle:stop()
  if self.tracer then
    World:despawn(self.tracer)
    self.laser = self:fire(Laser)
    self.owner.modifiers.newDirection = function() return nil end

    local finish = function()
      self.owner.modifiers.speed = nil
      self.owner.modifiers.newDirection = nil
    end

    if self.laser ~= nil then
      self.laser.finish = finish
    else
      finish()
    end
  end
end


Tracer = Impactor:extend("Tracer")

function Tracer:init(opts)
  Tracer.super.init(self, opts)
  self.color = {219, 207, 68, 128}
end

function Tracer:update(dt)
  Tracer.super.update(self, dt)
  self:setCenter(self.owner:center())
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


Laser = Impactor:extend("Laser")

function Laser:init(opts)
  Laser.super.init(self, opts)
  self.color = {250, 0, 0, 255}
  self.maxAge = 0.5
end

function Laser:update(dt)
  Laser.super.update(self, dt)
  self:setCenter(self.owner:center())
  if self.done then
    if self.finish then
      self.finish()
    end
    World:despawn(self)
  end
end

function ease(x)
  return -12*x*x + 12*x + .5
end

function Laser:draw()
  local dir = Point(self.owner:facingDirection())
  local from = self.position + dir * 4
  local to = from + dir * 200

  local r, g, b, a = love.graphics.getColor()
  local oldWidth = love.graphics.getLineWidth()
  local width = ease(self.age / self.maxAge)

  love.graphics.setColor(self.color)
  love.graphics.setLineWidth(width)

  love.graphics.line(from.x, from.y, to.x, to.y)

  love.graphics.setColor(r, g, b, a)
  love.graphics.setLineWidth(oldWidth)
end