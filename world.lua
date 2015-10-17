require 'controller'
require 'worldmap'
local bump = require 'lib.bump.bump'

World = {}

setmetatable(World, {
  __newindex = function(self, key, value)
    rawset(self, key, value)
    if key == 'active' then
      for i, player in pairs(self.mobs) do
        player.active = self.active
      end
    end
  end
})

function World:load()
  self.bumpWorld = bump.newWorld(8)
  self.worldCanvas = love.graphics.newCanvas()
  self.map = WorldMap("worldMaps/ship1.world", "assets/worlds/ship.png", self.bumpWorld)
  local playerCount = 2
  self.mobs = {}
  for i, coord in ipairs(self.map.playerCoords) do
    if i <= playerCount then
      self.mobs[i] = Mob(coord.x, coord.y, self.bumpWorld)
    end
  end

  for i, player in ipairs(self.mobs) do
    Controller:register(player, i)
  end
end

function World:update(dt)
  self.center = {x=0, y=0}
  for i, dude in ipairs(self.mobs) do
    dude:update(dt)

    self.center.x = self.center.x + dude:center().x
    self.center.y = self.center.y + dude:center().y
  end
  self.center.x = round(self.center.x / # self.mobs)
  self.center.y = round(self.center.y / # self.mobs)
end

function World:draw()
  love.graphics.push()
    love.graphics.origin()
    self.worldCanvas:clear()
    love.graphics.setCanvas(self.worldCanvas)
    self.map:draw()
    for i, dude in ipairs(self.mobs) do
      dude:draw()
    end
  love.graphics.pop()
  love.graphics.setCanvas()

  local offx = round(Size.w / 2) - self.center.x
  local offy = round(Size.h / 2) - self.center.y
  love.graphics.draw(self.worldCanvas, offx, offy)
end
