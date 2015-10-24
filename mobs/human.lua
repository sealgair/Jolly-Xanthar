require 'mobs.mob'
require 'weapons.bolter'

Human = Mob:extend('Human')

function Human:init(coord)
  Human.super.init(self, {
    x = coord.x,
    y = coord.y,
    confFile = 'assets/mobs/human.json',
    speed = 50
  })
  self.weapons.a = Bolter(self)
end