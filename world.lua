require 'controller'
require 'worldmap'
require 'mobs.human'
require 'mobs.monster'
require 'mobs.behavior'
require 'indicator'
require 'hud'
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
  self.map = WorldMap(
    "assets/worlds/ship1.world",
    "assets/worlds/ship.png",
    self.bumpWorld,
    10
  )
  local playerCount = 4
  self.gobs = {}
  self.players = {}
  self.behaviors = {}
  self.indicators = {}
  self.huds = {}
  self.despawnQueue = {}

  self.screen = Rect(Point(), GameSize)

  -- add players
  local center = Point()
  for i, coord in ipairs(self.map.playerCoords) do
    if i <= playerCount then
      local player = Human(coord)
      Controller:register(player, i)
      self:spawn(player)
      self.players[i] = player
      self.indicators[i] = Indicator(i)
      self.huds[i] = HUD(player, i)
      center = center + player:center()
    end
  end
  center = center / playerCount
  self.screen:setCenter(center)

  -- add monsters
  for i, coord in ipairs(self.map.monsterCoords) do
    local monster = Monster(coord)
    table.insert(self.behaviors, Behavior(monster))
    self:spawn(monster)
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
  local collisions = {}
  for i, gob in ipairs(self.gobs) do
    gob:update(dt)

    -- handle collisions
    local goal = gob:getBoundingBox()
    local x, y, cols, len = self.bumpWorld:move(gob, goal.x, goal.y, Gob.collideFilter)
    gob:setBoundingBox(Point(x, y))
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
    if self.bumpWorld:hasItem(gob) then
      self.bumpWorld:remove(gob)
    end
  end
  self.despawnQueue = {}

  -- Let AI do its thing
  for _, behavior in pairs(self.behaviors) do
    behavior:update(dt)
  end

  for hud in values(self.huds) do
    hud:update(dt)
  end

  local oldCenter = self.screen:center()
  local newCenter = Point()
  local count = 0
  for dude in values(self.players) do
    if self.screen:contains(dude:center()) then
      newCenter = newCenter + dude:center()
      count = count + 1
    end
  end
  newCenter = newCenter / count

  local maxStep = 60 * dt -- pixels per second
  newCenter.x = math.max(newCenter.x, oldCenter.x - maxStep)
  newCenter.x = math.min(newCenter.x, oldCenter.x + maxStep)
  newCenter.y = math.max(newCenter.y, oldCenter.y - maxStep)
  newCenter.y = math.min(newCenter.y, oldCenter.y + maxStep)
  self.screen:setCenter(newCenter)
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
    local dir = ""

    if pos.y < self.screen.y then
      dir = "up"
      pos.y = self.screen.y
    elseif pos.y > self.screen:bottom() then
      dir = "down"
      pos.y = self.screen:bottom()
    end
    if pos.x > self.screen:right() then
      dir = dir .. "right"
      pos.x = self.screen:right()
    elseif pos.x < self.screen.x then
      dir = dir .. "left"
      pos.x = self.screen.x
    end

    if dir == "" then dir = "down" end
    ind:draw(pos.x, pos.y, dir)
  end
  love.graphics.pop()
  love.graphics.setCanvas()

  local offset = Point(GameSize.w / 2, GameSize.h /2) - self.screen:center()
  love.graphics.draw(self.worldCanvas, offset.x, offset.y)

  for hud in values(self.huds) do
    hud:draw()
  end
end
