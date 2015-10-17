class = require 'lib/30log/30log'

Behavior = class('Behavior')

function Behavior:init(mob)
  self.mob = mob
end

function Behavior:update(dt)
  self.mob:setDirection(Direction(1, -1))
end
