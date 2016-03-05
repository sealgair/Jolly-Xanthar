require 'utils'
require 'mobs.mob'
require 'weapons.bolter'
require 'weapons.laser'
require 'weapons.forcefield'

Weapons = {
  [Bolter.name] = Bolter,
  [LaserRifle.name] = LaserRifle,
  [ForceField.name] = ForceField,
}

Human = Mob:extend('Human')

function Human:init(coord, opts)
  if opts == nil then opts = {} end
  local palette = love.graphics.newImage('assets/palette.png'):getData()
  local choices = palette:getHeight()

  local toColors = opts.colors
  if toColors == nil then
    toColors = {}
    local seen = {}
    for i = 1,3 do
      local c
      repeat c = math.random(0, choices - 1) until seen[c] == nil
      seen[c] = true
      table.insert(toColors, {palette:getPixel(0, c)})
      table.insert(toColors, {palette:getPixel(1, c)})
    end
  end
  self.colors = toColors

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
    stunFactor = 1.5,
    shader = self.shader
  })

  self.weapons = opts.weapons
  if self.weapons == nil then
    self.weapons = {}
    local allWeapons = {Bolter.name, LaserRifle.name, ForceField.name}
    local a = math.random(1, #allWeapons)
    local b
    repeat b = math.random(1, #allWeapons) until b ~= a
    self.weapons.a = allWeapons[a]
    self.weapons.b = allWeapons[b]
  end
  self.weapons = map(self.weapons, function(w) return Weapons[w](self) end)

  if opts.name == nil then
    local forename = randomLine("assets/names/forenames.txt")
    local surname = randomLine("assets/names/surnames.txt")
    self.name = forename .. " " .. surname
  else
    self.name = opts.name
  end
  self.isFriendly = true
end

function Human:serialize()
  return {
    colors = self.colors,
    weapons = map(self.weapons, function(w) return w.name end),
    name = self.name,
  }
end

function Human:__tostring()
  return self.name .. " the human"
end