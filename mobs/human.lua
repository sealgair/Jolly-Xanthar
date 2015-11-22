require 'mobs.mob'
require 'weapons.bolter'
require 'weapons.forcefield'

Human = Mob:extend('Human')

function Human:init(coord)
  local palette = love.graphics.newImage('assets/palette.bmp'):getData()
  local choices = palette:getHeight()

  local toColors = {}
  local seen = {}
  for i = 1,3 do
    local c
    repeat c = math.random(0, choices) until seen[c] == nil
    seen[c] = true
    table.insert(toColors, {palette:getPixel(0, c)})
    table.insert(toColors, {palette:getPixel(1, c)})
  end

  self.shader = palletSwapShader({
    {255, 0, 0},
    {128, 0, 0},
    {0, 255, 0},
    {0, 128, 0},
    {0, 0, 255},
    {0, 0, 128},
  }, toColors)

  Human.super.init(self, {
    x = coord.x,
    y = coord.y,
    confFile = 'assets/mobs/human.json',
    speed = 50,
    momentum = 20,
    shader = self.shader
  })
  self.weapons.a = Bolter(self)
  self.weapons.b = ForceField(self)
end