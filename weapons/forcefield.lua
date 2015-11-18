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
    rateLimit = 0.5,
  })
end

function ForceField:start()
  self.bubble = ForceField.super.start(self)
end

function ForceField:stop()
  if self.bubble ~= nil then
    World:despawn(self.bubble)
    self.cooldown = math.min(self.rateLimit, self.bubble.age)
    self.bubble = nil
  end
end

Bubble = Impactor:extend('Bubble')

function Bubble:init(opts)
  Bubble.super.init(self, opts)
  self.scaleCanvas = love.graphics.newCanvas()
  self.spawnTime = 0.5
  self.despawnTime = 0.5
  self.baseHitbox = self.hitbox
  self.scale = 1
  self.damage = 3
end

function Bubble:impact(other)
  if other.facingDirection then
    if self.despawnTimer == nil then
      self.despawnTimer = self.despawnTime
    end
    other:shove(Point(self.direction) * 8, 150)
  end
end

function Bubble:update(dt)
  local oldScale = self.scale
  self.scale = 1
  if self.age < self.spawnTime then
    self.scale = easeInOut(self.age / self.spawnTime)
  else
    self.damage = 0
    if self.despawnTimer then
      self.scale = easeInOut(self.despawnTimer / self.despawnTime)
    end
  end

  if self.scale ~= oldScale then
    self.hitbox = self.baseHitbox * math.max(self.scale, 0.1)
    self.hitbox:setCenter(self.baseHitbox:center())
    self.hitbox.updated = true
  end

  if self.starting then
    self.starting = self.starting - dt
    if self.starting <= 0 then self.starting = nil end
  end
  if self.age > self.spawnTime and self.despawnTimer then
    if self.despawnTimer <= 0 then
      self.despawnTimer = nil
      self.weapon:stop()
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
  return 24.0475 * tc * ts + -48.9925 * ts * ts + 23.895 * tc + 1.9 * ts + 0.15 * t
end

function Bubble:animState()
  if self.damage > 0 then
    return "attack"
  else
    Bubble.super.animState(self)
  end
end

function Bubble:draw()
  if scale ~= 1 then
    local oldCavnas = love.graphics.getCanvas()
    self.scaleCanvas:clear()

    love.graphics.push()
      love.graphics.setCanvas(self.scaleCanvas)

      local translate = Point(self.position) * -self.scale
      love.graphics.translate(translate.x, translate.y)
      love.graphics.scale(self.scale)
      Bubble.super.draw(self)

      love.graphics.setCanvas(oldCavnas)
    love.graphics.pop()

    local offset = (Point(self.w, self.h) / 2) * (1-self.scale)
    local scaledPos = Point(self.position) + offset
    love.graphics.draw(self.scaleCanvas, scaledPos.x, scaledPos.y)
  else
    Bubble.super.draw(self)
  end
end