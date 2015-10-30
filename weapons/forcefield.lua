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
end

function Bubble:impact(other)
  self.despawnTimer = 0.5
  self:shove(map(other:facingDirection():vector(), function(n) return n * 16 end), 100)
end

function Bubble:update(dt)
  if self.starting then
    self.starting = self.starting - dt
    if self.starting <= 0 then self.starting = nil end
  end
  if self.despawnTimer then
    if self.despawnTimer == nil then
      self.despawnTimer = 0.5
    end
    self.despawnTimer = self.despawnTimer - dt
  end

  Bite.super.update(self, dt)
  self:positionToOwner()
end
