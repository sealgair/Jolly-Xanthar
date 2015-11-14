require 'weapons.abstractWeapon'

ForceField = Weapon:extend('ForceField')

function ForceField:init(owner)
  ForceField.super.init(self, {
    owner = owner,
    confFile = 'assets/weapons/forcefield.json',
    ProjectileClass = Bubble,
    collideType = "slide",
    collidePriority = 20,
    speed = 0,
    damage = 0,
  })
end

function ForceField:start()
  self.bubble = ForceField.super.start(self)
end

function ForceField:stop()
  World:despawn(self.bubble)
  self.bubble = nil
end

Bubble = Impactor:extend('Bubble')

function Bubble:init(opts)
  Bubble.super.init(self, opts)
  self.scaleCanvas = love.graphics.newCanvas()
  self.spawnTime = 0.3
  self.despawnTime = 0.5
end

function Bubble:impact(other)
  if other.facingDirection then
    if self.despawnTimer == nil then
      self.despawnTimer = self.despawnTime
    end
    self:shove(map(other:facingDirection():vector(), function(n) return n * 16 end), 100)
  end
end

function Bubble:update(dt)
  if self.starting then
    self.starting = self.starting - dt
    if self.starting <= 0 then self.starting = nil end
  end
  if self.age > self.spawnTime and self.despawnTimer then
    if self.despawnTimer <= 0 then
      self.despawnTimer = nil
      World:despawn(self)
    else
      self.despawnTimer = self.despawnTimer - dt
    end
  end
  self.direction = self.owner.direction
  self.speed = self.owner.speed
  Bite.super.update(self, dt)
  self.owner:setCenter(self:center())
end

function easeInOut(t)
  local ts = (t) * t
  local tc = ts * t
  return (6.2975 * tc * ts + -14.9425 * ts * ts + 8.595 * tc + 0.5 * ts + 0.55 * t)
end

function Bubble:draw()
  local scale = 1
  if self.age < self.spawnTime then
    scale = easeInOut(self.age / self.spawnTime)
  elseif self.despawnTimer then
    scale = easeInOut(self.despawnTimer / self.despawnTime)
  end

  if scale ~= 1 then
    local oldCavnas = love.graphics.getCanvas()
    self.scaleCanvas:clear()

    love.graphics.push()
      love.graphics.setCanvas(self.scaleCanvas)

      local translate = Point(self.position) * -scale
      love.graphics.translate(translate.x, translate.y)
      love.graphics.scale(scale)
      Bubble.super.draw(self)

      love.graphics.setCanvas(oldCavnas)
    love.graphics.pop()

    local offset = (Point(self.w, self.h) / 2) * (1-scale)
    local scaledPos = Point(self.position) + offset
    love.graphics.draw(self.scaleCanvas, scaledPos.x, scaledPos.y)
  else
    Bubble.super.draw(self)
  end
end