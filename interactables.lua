class = require 'lib/30log/30log'
require 'gob'
require 'utils'
require 'position'

PlayerSwitcher = class('PlayerSwitcher')

function PlayerSwitcher:init(player)
  self.player = player
  self.hitbox = player:rect() * 3
end

function PlayerSwitcher:collideFilter(other)
  if other ~= self.player then
    return PlayerSwitcher.super.collideFilter(self, other)
  end
end

function PlayerSwitcher:update()
  self.hitbox:setCenter(self.player:center())
end
