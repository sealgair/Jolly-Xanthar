require 'controller'
require 'worldmap'

World = {}

setmetatable(World, {
  __newindex = function(self, key, value)
    rawset(self, key, value)
    if key == 'active' then
      for i, player in pairs(self.players) do
        player.active = self.active
      end
    end
  end
})

function World:load()
  self.players = {
    Player(0, 0),
    Player(0, 32),
    -- Player(32, 0),
    -- Player(32, 32),
  }
  self.worldCanvas = love.graphics.newCanvas()
  self.map = WorldMap("worldMaps/ship1.world", "assets/worlds/ship.png")

  for i, player in ipairs(self.players) do
    Controller:register(player, i)
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
    for i, dude in ipairs(self.players) do
      dude:draw()
    end
  love.graphics.pop()
  love.graphics.setCanvas()

  local offx = round(Size.w / 2) - self.center.x
  local offy = round(Size.h / 2) - self.center.y
  love.graphics.draw(self.worldCanvas, offx, offy)
end
