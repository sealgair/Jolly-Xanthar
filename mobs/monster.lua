require 'mobs.mob'
require 'weapons.teeth'

Monster = Mob:extend('Monster')

function Monster:init(coord)
  Monster.super.init(self, {
    x = coord.x,
    y = coord.y,
    confFile = 'assets/mobs/monster2.json',
    speed = 30
  })
  self.weapons.a = Teeth(self)
end