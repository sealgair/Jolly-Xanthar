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
  self.map = WorldMap(
    "worldMaps/ship1.world",
    "assets/worlds/ship.png",
    self.bumpWorld,
    10
  )
  local playerCount = 2
  self.mobs = {}
  self.players = {}

  -- add players
  for i, coord in ipairs(self.map.playerCoords) do
    if i <= playerCount then
      local player = Mob(coord.x, coord.y, self.bumpWorld, 'assets/mobs/human.png')
      Controller:register(player, i)
      self.mobs[i] = player
      self.players[i] = player
    end
  end

  -- add monsters
  for i, coord in ipairs(self.map.monsterCoords) do
    table.insert(self.mobs, Mob(coord.x, coord.y, self.bumpWorld, 'assets/mobs/monster2.png'))
  end
end

function World:update(dt)
  self.center = {x=0, y=0}
  for i, dude in ipairs(self.players) do
    dude:update(dt)

    self.center.x = self.center.x + dude:center().x
    self.center.y = self.center.y + dude:center().y
  end
  self.center.x = round(self.center.x / # self.players)
  self.center.y = round(self.center.y / # self.players)
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
