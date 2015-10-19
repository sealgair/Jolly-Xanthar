class = require 'lib/30log/30log'
require 'utils'
require 'direction'
require 'gob'

Mob = Gob:extend('Mob')

function Mob:init(opts)
  Mob.super.init(self, opts)
  self.actions = {}
end

function Mob:setDirection(newDirection)
  if newDirection == self.direction or newDirection == nil then
    return
  end

  self.direction = newDirection
  if newDirection ~= Direction(0, 0) then
    local oldDirection = Direction[self.facingDir]
    if oldDirection == newDirection then return end

    local ldir = oldDirection
    local rdir = oldDirection
    local lqueue = {}
    local rqueue = {}
    self.turnDelay = 0
    while true do
      ldir = ldir:turnLeft()
      rdir = rdir:turnRight()
      table.insert(lqueue, ldir:key())
      table.insert(rqueue, rdir:key())
      if ldir == newDirection then
        self.animationQueue = lqueue
        break
      end
      if rdir == newDirection then
        self.animationQueue = rqueue
        break
      end
    end
    self.animLength = # self.animationQueue
  end
end

function Mob:controlStart(action)
  self.actions[action] = true
end

function Mob:controlStop(action)
  self.actions[action] = nil
  local facingDirection = Direction[self.facingDir]
  local shoot = {
    x = self.position.x + facingDirection.x * self.w * (2/3),
    y = self.position.y + facingDirection.y * self.h * (2/3),
  }

  if action == 'a' then
    local bullet = Gob{
      confFile = 'assets/sprites/bolt.json',
      x = shoot.x,
      y = shoot.y,
      dir = facingDirection,
      speed = 200,
    }
    World:spawn(bullet)
  end
end
