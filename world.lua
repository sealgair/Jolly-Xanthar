require 'controller'
require 'worldmap'
require 'mobs.human'
require 'mobs.monster'
require 'mobs.behavior'
require 'indicator'
require 'hud'
local bump = require 'lib.bump.bump'
DEBUG_BUMP = false

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
  self.bumpWorld = bump.newWorld(16)
  self.worldCanvas = love.graphics.newCanvas()
  self.map = WorldMap(
    "assets/worlds/ship1.world",
    "assets/worlds/ship.png",
    self.bumpWorld,
    10
  )
  local playerCount = 2
  self.gobs = {}
  self.players = {}
  self.behaviors = {}
  self.indicators = {}
  self.huds = {}
  self.despawnQueue = {}

  self.mainScreen = Rect(Point(), GameSize)
  self.mainScreen.windowOffset = Point()
  self.extraScreens = {}

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
  self.mainScreen:setCenter(center)

  -- add monsters
  for i, coord in ipairs(self.map.monsterCoords) do
    local monster = Monster(coord)
    table.insert(self.behaviors, Behavior(monster))
    self:spawn(monster)
  end
end

function World:spawn(gob)
  -- handle newest collisions first
  table.insert(self.gobs, 1, gob)
  self.bumpWorld:add(gob,
    gob.position.x + gob.hitbox.x,
    gob.position.y + gob.hitbox.y,
    gob.hitbox.w, gob.hitbox.h)
  gob.bumpWorld = self.bumpWorld
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

    if gob.hitbox.updated then
      local newhb = Rect(gob.hitbox) + Point(gob.position)
      self.bumpWorld:update(gob, newhb.x, newhb.y, newhb.w, newhb.h)
      gob.hitbox.updated = nil
    end

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
      if gob.bumpWorld == self.bumpWorld then
        gob.bumpWorld = nil
      end
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

  local oldCenter = self.mainScreen:center()
  local newCenter = Point()
  local count = 0
  local outsiders = {}
  for p, player in pairs(self.players) do
    if self.mainScreen:contains(player:center()) then
      newCenter = newCenter + player:center()
      count = count + 1
    else
      outsiders[p] = player
    end
  end
  newCenter = newCenter / count

  newCenter.x = math.max(newCenter.x, oldCenter.x - maxStep)
  newCenter.x = math.min(newCenter.x, oldCenter.x + maxStep)
  newCenter.y = math.max(newCenter.y, oldCenter.y - maxStep)
  newCenter.y = math.min(newCenter.y, oldCenter.y + maxStep)
  self.mainScreen:setCenter(newCenter)

  self.extraScreens = {}
  for p, player in pairs(outsiders) do
    local hud = self.huds[p]
    local newScreen = Rect(Point(), hud.rect.w, hud.rect.w)
    newScreen:setCenter(player:center())

    newScreen.windowOffset = hud.rect:origin()
    if p > 2 then
      newScreen.windowOffset.y = hud.rect:bottom() - newScreen.h - hud.barHeight
    else
      newScreen.windowOffset.y = newScreen.windowOffset.y + hud.barHeight
    end
    table.insert(self.extraScreens, newScreen)
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
    if DEBUG_BUMP then
      local x, y, w, h = self.bumpWorld:getRect(dude)
      love.graphics.rectangle("line", x, y, w, h)
    end
  end


  love.graphics.pop()
  love.graphics.setCanvas()

  local screens = {self.mainScreen}
  table.extend(screens, self.extraScreens)
  local hud = self.huds[1]

  local sw, sh = self.worldCanvas:getDimensions()
  for screen in values(screens) do
    if scren ~= self.mainScreen then
      love.graphics.setColor(0,0,0)
      local background = Rect(screen.windowOffset.x-1, screen.windowOffset.y-1, screen.w+2, screen.h+2 + hud.barHeight)
      if background.y < self.mainScreen.h / 2 then
        background.y = background.y - hud.barHeight
      end
      love.graphics.rectangle("fill", background.x, background.y, background.w, background.h)
      love.graphics.setColor(255,255,255)
    end
    local quad = love.graphics.newQuad(
      screen.x, screen.y,
      screen.w, screen.h,
      sw, sh
    )
    love.graphics.draw(self.worldCanvas, quad, screen.windowOffset.x, screen.windowOffset.y)
  end

  local drawn = {}
  for i, player in pairs(self.players) do
    local ind = self.indicators[i]
    local indSz = Size(ind.w, ind.h)

    for s, screen in ipairs(screens) do
      local sco = screen.windowOffset
      local pos = player:center() - screen:origin() + sco
      pos.y = pos.y - (player.h)/2
      local dir = ""

      if not Rect(screen.windowOffset, screen:size()):contains(pos) then
        if pos.y < sco.y then
          dir = "up"
          pos.y = sco.y
        elseif pos.y > sco.y + screen.h then
          dir = "down"
          pos.y = sco.y + screen.h
        end
        if pos.x > sco.x + screen.w then
          dir = dir .. "right"
          pos.x = sco.x + screen.w
        elseif pos.x < sco.x then
          dir = dir .. "left"
          pos.x = sco.x
        end

        for p in values(drawn) do
          if Rect(p, indSz):intersects(Rect(pos, indSz)) then
            pos.x = p.x + indSz.w
          end
        end
      end
      if dir == "" then
        dir = "down"
      end

      ind:draw(pos.x, pos.y, dir)
      table.insert(drawn, pos)
    end
  end

  for hud in values(self.huds) do
    hud:draw()
  end
end
