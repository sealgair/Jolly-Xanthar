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
  if self.wanderDuration == nil or self.wanderDuration < 0 then
    self.wanderDirection = AllDirections[math.random(8)]
    self.wanderDuration = math.random() * 5
  else
    self.wanderDuration = self.wanderDuration - dt
  end
  self.mob:setDirection(self.wanderDirection)
end
