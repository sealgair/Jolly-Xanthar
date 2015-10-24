class = require 'lib/30log/30log'

Behavior = class('Behavior')

function Behavior:init(mob)
  self.mob = mob
  self.attackRepeat = 0.66
  self.attackDuration = 0.2
  self.attackTimer = self.attackRepeat
end

function Behavior:update(dt)
  if self.mob.agressor then
    if self.mob.health <= self.mob.maxHealth / 4 then
      self:flee(dt)
    else
      self:attack(dt)
    end
  else
    self:wander(dt)
  end
end

function Behavior:wander(dt)
  if self.wanderDirection == nil then
    self.wanderDirection = Direction.allDirections[math.random(8)]
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

  if # self.mob.collisions > 0 then
    local newx = self.wanderDirection.x
    local newy = self.wanderDirection.y
    for _, col in pairs(self.mob.collisions) do
      if col.normal.x ~= 0 then
        newx = col.normal.x
      end
      if col.normal.y ~= 0 then
        newy = col.normal.y
      end
    end
    self.wanderDirection = Direction(newx, newy)
  end
  self.mob:setDirection(self.wanderDirection)
end

function Behavior:attack(dt)
  if self.mob.agressor == nil then return end

  local s = 3
  local dist = {
    x = self.mob.agressor.position.x - self.mob.position.x,
    y = self.mob.agressor.position.y - self.mob.position.y,
  }
  if math.abs(dist.x) * 3 < math.abs(dist.y) then
    dist.x = 0
  elseif math.abs(dist.y) * 3 < math.abs(dist.x) then
    dist.y = 0
  end

  self.mob:setDirection(Direction(dist.x, dist.y))

  if self.attackTimer <= 0 then
    self.mob:controlStart('a')
    self.attacking = true
    self.attackTimer = self.attackRepeat
  end
  if self.attacking and self.attackTimer < self.attackRepeat - self.attackDuration then
    self.mob:controlStop('a')
    self.attacking = false
  end

  if self.attackTimer > 0 then
    self.attackTimer = self.attackTimer - dt
  end
end

function Behavior:flee(dt)
  if self.mob.agressor == nil then return end

  local s = 3
  local dist = {
    x = self.mob.position.x - self.mob.agressor.position.x,
    y = self.mob.position.y - self.mob.agressor.position.y,
  }
  if math.abs(dist.x) * 3 < math.abs(dist.y) then
    dist.x = 0
  elseif math.abs(dist.y) * 3 < math.abs(dist.x) then
    dist.y = 0
  end

  self.mob:setDirection(Direction(dist.x, dist.y))
end