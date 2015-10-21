require 'controller'
require 'worldmap'
require 'behavior'
require 'indicator'
local bump = require 'lib.bump.bump'

World = {}

setmetatable(World, {
  __newindex = function(self, key, value)
    rawset(self, key, value)
    if key == 'active' then
      for i, player in pairs(self.gobs) do
        player.active = self.active
      end
    end
  end
})

function World:load()
  self.bumpWorld = bump.newWorld(8)
  self.worldCanvas = love.graphics.newCanvas()
  self.map = WorldMap("worldMaps/ship1.world",
    "assets/worlds/ship.png",
    self.bumpWorld,
    10)
  local playerCount = 4
  self.gobs = {}
  self.players = {}
  self.indicators = {}
  self.despawnQueue = {}

  -- add players
  for i, coord in ipairs(self.map.playerCoords) do
    if i <= playerCount then
      local player = Mob {
        x = coord.x,
        y = coord.y,
        confFile = 'assets/mobs/human.json',
        speed = 50
      }
      Controller:register(player, i)
      self:spawn(player)
      self.players[i] = player
      self.indicators[i] = Indicator(i)
    end
  end

  -- add monsters
  self.behaviors = {}
  for i, coord in ipairs(self.map.monsterCoords) do
    local monster = Mob {
      x = coord.x,
      y = coord.y,
      confFile = 'assets/mobs/monster2.json',
      speed = 30
    }
    self:spawn(monster)
    table.insert(self.behaviors, Behavior(monster))
  end
end

function World:spawn(gob)
  table.insert(self.gobs, gob)
  self.bumpWorld:add(gob,
    gob.position.x + gob.hitbox.x,
    gob.position.y + gob.hitbox.y,
    gob.hitbox.w, gob.hitbox.h)
end

function World:despawn(gob)
  table.insert(self.despawnQueue, gob)
end

function World:update(dt)
  for _, behavior in pairs(self.behaviors) do
    behavior:update(dt)
  end

  local collisions = {}
  for i, gob in ipairs(self.gobs) do
    gob:update(dt)

    -- handle collisions
    local goal = gob:getBoundingBox()
    local x, y, cols, len = self.bumpWorld:move(gob, goal.x, goal.y, Gob.collideFilter)
    gob:setBoundingBox { x = x, y = y }
    collisions[gob] = cols
  end

  -- resolve collisions
  for gob, cols in pairs(collisions) do
    gob:collide(cols)
    for _, col in pairs(cols) do
      local other = col.other
      if other.collide then
        col.other = gob
        other:collide({col})
      end
    end
  end

  -- handle queued despawns
  for _, gob in pairs(self.despawnQueue) do
    for i, g in ipairs(self.gobs) do
      if g == gob then
        table.remove(self.gobs, i)
        break
      end
    end
    self.bumpWorld:remove(gob)
  end
  self.despawnQueue = {}

  self.center = { x = 0, y = 0 }
  for i, dude in ipairs(self.players) do
    self.center.x = self.center.x + dude:center().x
    self.center.y = self.center.y + dude:center().y
  end
  self.center.x = self.center.x / #self.players
  self.center.y = self.center.y / #self.players
end

function World:draw()
  love.graphics.push()
  love.graphics.origin()
  self.worldCanvas:clear()
  love.graphics.setCanvas(self.worldCanvas)
  self.map:draw()

  table.sort(self.gobs, function(a, b)
    return a.position.y < b.position.y
  end)

  for i, dude in ipairs(self.gobs) do
    dude:draw()
  end
  for i, player in pairs(self.players) do
    local ind = self.indicators[i]
    local pos = player:center()
    pos.y = pos.y - (player.h)/2
    ind:draw(pos.x, pos.y)
  end
  love.graphics.pop()
  love.graphics.setCanvas()

  local offx = (Size.w / 2) - self.center.x
  local offy = (Size.h / 2) - self.center.y
  love.graphics.draw(self.worldCanvas, offx, offy)
end
