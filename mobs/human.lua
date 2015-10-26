require 'mobs.mob'
require 'weapons.bolter'

Human = Mob:extend('Human')

function Human:init(coord)
  local hue1 = math.random(255)
  local hue2 = math.random(255)

  self.shader = palletSwapShader({
    {255, 0, 0},
    {128, 0, 0},
    {0, 0, 255},
    {0, 0, 128},
  }, {
    HSVtoRGB(hue1, 188, 255),
    HSVtoRGB(hue1, 188, 128),
    HSVtoRGB(hue2, 188, 255),
    HSVtoRGB(hue2, 188, 128),
  })

  Human.super.init(self, {
    x = coord.x,
    y = coord.y,
    confFile = 'assets/mobs/human.json',
    speed = 50,
    shader = self.shader
  })
  self.weapons.a = Bolter(self)
end