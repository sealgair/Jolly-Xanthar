require 'mobs.mob'
require 'weapons.bolter'
require 'weapons.laser'
require 'weapons.forcefield'

Human = Mob:extend('Human')

function Human:init(coord, colors, weapons, name)
  local palette = love.graphics.newImage('assets/palette.bmp'):getData()
  local choices = palette:getHeight()

  local toColors = colors
  local seen = {}
  if toColors == nil then
    toColors = {}
    for i = 1,3 do
      local c
      repeat c = math.random(0, choices - 1) until seen[c] == nil
      seen[c] = true
      table.insert(toColors, {palette:getPixel(0, c)})
      table.insert(toColors, {palette:getPixel(1, c)})
    end
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

  if weapons == nil then
    local allWeapons = {Bolter, LaserRifle, ForceField }
    local a = math.random(1, #allWeapons)
    local b
    repeat b = math.random(1, #allWeapons) until b ~= a
    self.weapons.a = allWeapons[a](self)
    self.weapons.b = allWeapons[b](self)
  else
    self.weapons = weapons
  end

  if name == nil then
    local forenames = {}
    for n in love.filesystem.lines("assets/forenames.txt") do
      table.insert(forenames, n)
    end
    local forename = forenames[math.random(#forenames)]
    forenames = nil

    local surnames = {}
    for n in love.filesystem.lines("assets/surnames.txt") do
      table.insert(surnames, n)
    end
    local surname = surnames[math.random(#surnames)]
    surnames = nil

    self.name = forename .. " " .. surname
  else
    self.name = name
  end
end