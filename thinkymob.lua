class = require 'lib/30log/30log'
require 'mob'

ThinkyMob = Mob:extend('ThinkyMob')

local AllDirections = {
  Direction.downleft,
  Direction.left,
  Direction.upleft,
  Direction.up,
  Direction.upright,
  Direction.right,
  Direction.downright,
  Direction.down,
}

function ThinkyMob:update(dt)
  if self.agressor then
    if self.health <= self.maxHealth / 4 then
      self:flee(dt)
    else
      self:attack(dt)
    end
  else
    self:wander(dt)
  end
  ThinkyMob.super.update(self, dt)
end

function ThinkyMob:wander(dt)
  if self.wanderDirection == nil then
    self.wanderDirection = AllDirections[math.random(8)]
    self.wanderDuration = math.random() * 5
  end
  if self.wanderDuration < 0 then
    self.wanderDuration = math.random() * 5
    local turnDir = math.random()
    for _=1,math.random(3) do
      if turnDir > 0.5 then
        self.wanderDirection = self.wanderDirection:turnLeft()
      else
        self.wanderDirection = self.wanderDirection:turnRight()
      end
    end
  else
    self.wanderDuration = self.wanderDuration - dt
  end

  if # self.collisions > 0 then
    local newx = self.wanderDirection.x
    local newy = self.wanderDirection.y
    for _, col in pairs(self.collisions) do
      if col.normal.x ~= 0 then
        newx = col.normal.x
      end
      if col.normal.y ~= 0 then
        newy = col.normal.y
      end
    end
    self.wanderDirection = Direction(newx, newy)
  end
  self:setDirection(self.wanderDirection)
end

function ThinkyMob:hurt(damage, collision)
  ThinkyMob.super.hurt(self, damage, collision)
  self.agressor = collision.other.owner
end

function ThinkyMob:attack(dt)
  if self.agressor == nil then return end

  local s = 3
  local dist = {
    x = self.agressor.position.x - self.position.x,
    y = self.agressor.position.y - self.position.y,
  }
  if math.abs(dist.x) * 3 < math.abs(dist.y) then
    dist.x = 0
  elseif math.abs(dist.y) * 3 < math.abs(dist.x) then
    dist.y = 0
  end

  self:setDirection(Direction(dist.x, dist.y))
end

function ThinkyMob:flee(dt)
  if self.agressor == nil then return end

  local s = 3
  local dist = {
    x = self.position.x - self.agressor.position.x,
    y = self.position.y - self.agressor.position.y,
  }
  if math.abs(dist.x) * 3 < math.abs(dist.y) then
    dist.x = 0
  elseif math.abs(dist.y) * 3 < math.abs(dist.x) then
    dist.y = 0
  end

  self:setDirection(Direction(dist.x, dist.y))
end