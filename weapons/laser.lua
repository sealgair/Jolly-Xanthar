require 'weapons.abstractWeapon'
require 'wall'

LaserRifle = Weapon:extend('Laser')

function LaserRifle:init(owner)
  LaserRifle.super.init(self, {
    owner = owner,
    damage = 5,
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
    self.owner.world:despawn(self.tracer)
    self.laser = self:fire(Laser)
    self.owner.modifiers.newDirection = function(new)
      if new ~= nil then
        self.doneDirection = new
      end
      return nil
    end

    local finish = function()
      self.owner.modifiers.speed = nil
      self.owner.modifiers.newDirection = nil
      self.owner:setDirection(self.doneDirection)
      self.doneDirection = nil
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
  self.color = {219, 207, 68, 128 }
  self.hitLine = {}
  self.damage = 0
end

function Tracer:hitLineStop(item)
  return true
end

function Tracer:update(dt)
  Tracer.super.update(self, dt)
  self:setCenter(self.owner:center())

  local dir = Point(self.owner:facingDirection())
  local from = self.position + dir * 4
  local to = from + dir * 500
  self.hitLine = {
    x1 = from.x, y1 = from.y,
    x2 = to.x, y2 = to.y
  }
end

function Tracer:width()
  return 1
end

function Tracer:draw()
  local r, g, b, a = love.graphics.getColor()
  local oldWidth = love.graphics.getLineWidth()
  local width = self:width()

  love.graphics.setColor(self.color)
  love.graphics.setLineWidth(width)

  love.graphics.line(self.hitLine.x1, self.hitLine.y1, self.hitLine.x2, self.hitLine.y2)

  love.graphics.setColor(r, g, b, a)
  love.graphics.setLineWidth(oldWidth)
end


Laser = Tracer:extend("Laser")

function Laser:init(opts)
  Laser.super.init(self, opts)
  self.color = {250, 0, 0, 255}
  self.maxAge = 0.5
  self.damage = opts.damage
  self.splatImg = love.graphics.newImage("assets/particles/laser.png")
  self.splats = {}
end

function Laser:hitLineStop(item)
  return class.isInstance(item, Wall)
end

function Laser:collide(cols)
  Laser.super.collide(self, cols)
  for col in values(cols) do
    if col.item ~= self.owner then
      local splat = love.graphics.newParticleSystem(self.splatImg, 64)
      splat:setEmissionRate(16)
      splat:setSpread(math.pi)
      splat:setSizeVariation(1)
      splat:setParticleLifetime(0.1, 0.3)
      splat:setRotation(0, 2 * math.pi)
      splat:setSpeed(50)
      splat:setEmitterLifetime(0.1)
      splat:start()
      splat:setPosition(col.x1, col.y1)
      table.insert(self.splats, splat)
    end
  end
end

function Laser:update(dt)
  Laser.super.update(self, dt)
  if self.done then
    if self.finish then
      self.finish()
    end
    self.owner.world:despawn(self)
  end
  for splat in values(self.splats) do
    splat:update(dt)
  end
end

function Laser:draw()
  Laser.super.draw(self)
  for splat in values(self.splats) do
    local x, y = splat:getPosition()
    love.graphics.draw(splat)
  end
end

function Laser:width()
  local x = self.age / self.maxAge
  return -12*x*x + 12*x + .5
end