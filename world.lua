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

  self.screens = {Rect(Point(), GameSize) }
  self.screens[1].windowOffset = Point()

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
  self.screens[1]:setCenter(center)

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

  local maxStep = 120 * dt -- pixels per second

  local screensChanged = false
  local outsiders = shallowCopy(self.players)
  local unusedScreens = shallowCopy(self.screens)
  for screen in values(self.screens) do
    local oldCenter = screen:center()
    local newCenter = Point()
    local count = 0
    local toRemove = {}
    for player in values(outsiders) do
      if screen:contains(player:center()) then
        newCenter = newCenter + player:center()
        count = count + 1
        table.insert(toRemove, player)
        table.removeValue(unusedScreens, screen)
      end
    end
    newCenter = newCenter / count
    for p in values(toRemove) do
      table.removeValue(outsiders, p)
    end

    newCenter.x = math.max(newCenter.x, oldCenter.x - maxStep)
    newCenter.x = math.min(newCenter.x, oldCenter.x + maxStep)
    newCenter.y = math.max(newCenter.y, oldCenter.y - maxStep)
    newCenter.y = math.min(newCenter.y, oldCenter.y + maxStep)
    screen:setCenter(newCenter)
  end
  for s in values(unusedScreens) do
    table.removeValue(self.screens, s)
    screensChanged = true
  end

  if #outsiders > 0 then
    local oldScreen, newScreen

    local newScreen = Rect(Point(), self.screens[1]:size())
    table.insert(self.screens, newScreen)
    screensChanged = true

    local newCenter = Point()
    for player in values(outsiders) do
      newCenter = newCenter + player:center()
    end
    newCenter = newCenter / #outsiders
    newScreen:setCenter(newCenter)
  end

  if screensChanged then
    local borderSize = 1
    local fullSize = GameSize
    local halfSize = Size(GameSize.w, GameSize.h / 2)
    local quarterSize = Size(GameSize.w / 2, halfSize.h)
    local x2 = quarterSize.w + borderSize
    local y2 = quarterSize.h + borderSize

    local oldCenters = map(self.screens, function(s)
      return s:center()
    end)

    local sc = #self.screens

    self.screens[1].windowOffset = Point(0, 0)
    self.screens[1]:setSize(fullSize)

    if sc >= 2 then
      self.screens[2].windowOffset = Point(0, y2)
      self.screens[2]:setSize(halfSize)
      self.screens[1]:setSize(halfSize)
    end

    if sc >= 3 then
      self.screens[3].windowOffset = Point(x2, y2)
      self.screens[3]:setSize(quarterSize)
      self.screens[2]:setSize(quarterSize)
    end

    if sc == 4 then
      self.screens[4].windowOffset = Point(x2, 0)
      self.screens[4]:setSize(quarterSize)
      self.screens[1]:setSize(quarterSize)
    end

    for s, center in ipairs(oldCenters) do
      self.screens[s]:setCenter(center)
    end
  end
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
    -- TODO: draw indicators directly to screen after canvas
    local ind = self.indicators[i]

    for screen in values(self.screens) do
      local pos = player:center()
      pos.y = pos.y - (player.h)/2
      local dir = ""

      if pos.y < screen.y then
        dir = "up"
        pos.y = screen.y
      elseif pos.y > screen:bottom() then
        dir = "down"
        pos.y = screen:bottom()
      end
      if pos.x > screen:right() then
        dir = dir .. "right"
        pos.x = screen:right()
      elseif pos.x < screen.x then
        dir = dir .. "left"
        pos.x = screen.x
      end

      if dir == "" then dir = "down" end
      ind:draw(pos.x, pos.y, dir)
    end
  end
  love.graphics.pop()
  love.graphics.setCanvas()

  local sw, sh = self.worldCanvas:getDimensions()
  for screen in values(self.screens) do
    local quad = love.graphics.newQuad(
      screen.x, screen.y,
      screen.w, screen.h,
      sw, sh
    )
    love.graphics.draw(self.worldCanvas, quad, screen.windowOffset.x, screen.windowOffset.y)
  end

  for hud in values(self.huds) do
    hud:draw()
  end
end
