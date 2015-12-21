class = require 'lib/30log/30log'
require 'controller'
require 'worldmap'
require 'mobs.human'
require 'mobs.monster'
require 'mobs.behavior'
require 'indicator'
require 'hud'
require 'save'
local bump = require 'lib.bump.bump'
DEBUG_BUMP = false

World = class("World")

function World:init(fsm, ship)
  self.fsm = fsm
  self.ship = coalesce(ship, Save:shipNames()[1])

  self.mainScreen = Rect(Point(), GameSize)
  self.mainScreen.windowOffset = Point()

  self.gobs = {}
  self.players = {}
  self.behaviors = {}
  self.indicators = {}
  self.huds = {}
  self.despawnQueue = {}
  self.extraScreens = {}

  -- load the map
  self.bumpWorld = bump.newWorld(16)
  self.worldCanvas = love.graphics.newCanvas()
  self.map = WorldMap("assets/worlds/ship1.world",
    "assets/worlds/ship.png",
    self.bumpWorld,
    10)

  -- add monsters
  for i, coord in ipairs(self.map.monsterCoords) do
    local monster = Monster(coord)
    table.insert(self.behaviors, Behavior(monster))
    self:spawn(monster)
  end

  -- add players
  self.roster = Save:shipRoster(self.ship)
  local center = Point()
  local activePlayers = {1}
  for i, coord in ipairs(self.map.playerCoords) do
    local hud = HUD(self, i)
    self.huds[i] = hud

    if activePlayers[i] then
      local player = self:addPlayer(self.roster[i], i, coord)
      center = center + player:center()
    end
  end
  center = center / #activePlayers
  self.mainScreen:setCenter(center)
end

function World:activate()
  for player in values(self.players) do
    player.active = true
  end
end

function World:deactivate()
  Save:saveShip(self.ship, self.roster)
end

function World:remainingRoster()
  local activeNames = {}
  for player in values(self.players) do
    activeNames[player.name] = 1
  end
  local remaining = {}
  for player in values(self.roster) do
    if activeNames[player.name] == nil then
      table.insert(remaining, player)
    end
  end
  return remaining
end

function World:addPlayer(rosterData, index, coords)
  if coords == nil then
    coords = self.mainScreen:center()
  end
  local player = Human(coords, rosterData)
  player.active = self.active
  Controller:register(player, index)
  self:spawn(player)
  self.players[index] = player
  self.huds[index].player = player
  self.indicators[index] = Indicator(index)

  return player
end

function World:removePlayer(index)
  local player = self.players[index]
  self:despawn(player)
  self.players[index] = nil
  self.huds[index].player = nil
  self.indicators[index] = nil

  local left = false
  for p in values(self.players) do left = true end
  for h in values(self.huds) do
    if #h.itemGrid > 0 then left = true end
  end
  if not left then
    self.fsm:advance('quit')
  end
end

function World:spawn(gob)
  -- handle newest collisions first
  table.insert(self.gobs, 1, gob)
  gob.world = self
  if gob.hitbox.w > 0 and gob.hitbox.h > 0 then
    self.bumpWorld:add(gob,
      gob.position.x + gob.hitbox.x,
      gob.position.y + gob.hitbox.y,
      gob.hitbox.w, gob.hitbox.h)
    gob.bumpWorld = self.bumpWorld
  end
end

function World:despawn(gob)
  table.insert(self.despawnQueue, gob)
end

function World:update(dt)
  if self.paused then
    return
  end

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

    if self.bumpWorld:hasItem(gob) then
      local x, y, cols, len = self.bumpWorld:move(gob, goal.x, goal.y, Gob.collideFilter)
      gob:setBoundingBox(Point(x, y))
      collisions[gob] = cols
    end
    if gob.hitLine then
      local itemInfo, len = self.bumpWorld:querySegmentWithCoords(gob.hitLine.x1, gob.hitLine.y1,
        gob.hitLine.x2, gob.hitLine.y2)
      if gob.hitLineStop then
        local limitedInfo = {}
        for info in values(itemInfo) do
          table.insert(limitedInfo, info)
          if gob:hitLineStop(info.item) then
            gob.hitLine.x2 = info.x1
            gob.hitLine.y2 = info.y1
            break
          end
        end
        itemInfo = limitedInfo
      end
      collisions[gob] = itemInfo
    end
  end

  -- resolve collisions
  for gob, cols in pairs(collisions) do
    gob:collide(cols)
    for _, col in pairs(cols) do
      local other = coalesce(col.other, col.item)
      if other.collide then
        col.other = gob
        other:collide({ col })
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
  local outsiders = {}
  if #self.players > 0 then
    local count = 0
    for p, player in pairs(self.players) do
      if self.mainScreen:contains(player:center()) then
        newCenter = newCenter + player:center()
        count = count + 1
      else
        outsiders[p] = player
      end
    end
    newCenter = newCenter / count
  else
    newCenter = Point(self.map.playerCoords[1])
  end

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

  local screens = { self.mainScreen }
  table.extend(screens, self.extraScreens)
  local hud = self.huds[1]

  local sw, sh = self.worldCanvas:getDimensions()
  for screen in values(screens) do
    if scren ~= self.mainScreen then
      love.graphics.setColor(0, 0, 0)
      local background = Rect(screen.windowOffset.x - 1, screen.windowOffset.y - 1, screen.w + 2, screen.h + 2 + hud.barHeight)
      if background.y < self.mainScreen.h / 2 then
        background.y = background.y - hud.barHeight
      end
      love.graphics.rectangle("fill", background.x, background.y, background.w, background.h)
      love.graphics.setColor(255, 255, 255)
    end
    local quad = love.graphics.newQuad(screen.x, screen.y,
      screen.w, screen.h,
      sw, sh)
    love.graphics.draw(self.worldCanvas, quad, screen.windowOffset.x, screen.windowOffset.y)
  end

  local drawn = {}
  for i, player in pairs(self.players) do
    local ind = self.indicators[i]
    local indSz = Size(ind.w, ind.h)

    for s, screen in ipairs(screens) do
      local sco = screen.windowOffset
      local pos = player:center() - screen:origin() + sco
      pos.y = pos.y - (player.h) / 2
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

  if self.paused then
    graphicsContext({ color={0, 0, 0, 127}, font=Fonts[16], lineWidth=2 },
    function()
      local rect = Rect(0, 0, 64, 18)
      rect:setCenter(Point(GameSize.w / 2, GameSize.h / 2))
      love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
      love.graphics.setColor(255, 0, 0)
      love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)
      rect = rect:inset(2)
      love.graphics.printf("Paused", rect.x, rect.y, rect.w, "center")
    end)
  end
end
