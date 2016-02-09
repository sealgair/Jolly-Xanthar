require 'world'

Ship = World:extend('Ship')

function Ship:init(fsm, ship)
  Ship.super.init(self, fsm, ship, "assets/worlds/barracks.world", "assets/worlds/ship.png", 0)
end