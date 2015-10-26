require 'weapons.abstractWeapon'

Teeth = Weapon:extend('Teeth')

function Teeth:init(owner)
  Teeth.super.init(self, {
    owner = owner,
    confFile = 'assets/weapons/bite.json',
    ProjectileClass = Bite,
    speed = 0,
    damage = 3,
  })
end

function Teeth:update(dt)
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

  Teeth.super.update(self, dt)
end

function Teeth:start()
  self.bite = Teeth.super.start(self)
end

function Teeth:stop()
  World:despawn(self.bite)
  self.bite = nil
end


Bite = Impactor:extend('Bite')

function Bite:positionToOwner()
  Bite.super.positionToOwner(self)

  -- offset in front of owner
  local pythagoras = 1
  if self.direction:isDiagonal() then
    -- diagonal, use pythagoras
    pythagoras = 1 / 1.414
  end
  self.position = {
    x = self.owner.position.x + self.w/2 + (self.direction.x * (self.w + self.owner.w)/2 * pythagoras),
    y = self.owner.position.y + self.h/2 + (self.direction.y * (self.w + self.owner.h)/2 * pythagoras),
  }
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
  self:positionToOwner()
end