class = require 'lib/30log/30log'

Behavior = class('Behavior')

function Behavior:init(mob)
  self.mob = mob
end

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

function Behavior:update(dt)
  self:wander(dt)
end

function Behavior:wander(dt)
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
