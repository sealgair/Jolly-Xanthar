class = require 'lib.30log.30log'
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

function World:init(fsm, fsmOpts, worldfile, tileset)
  self.fsm = fsm
  self.ship = coalesce(fsmOpts.ship, Save:shipNames()[1])
  self.planet = fsmOpts.planet
  self.depth = coalesce(fsmOpts.depth, 0)
  if self.planet then
    self.seed = self.planet .. self.depth
  else
    self.seed = self.ship
  end

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
  tileset = coalesce(tileset, "assets/worlds/forest.png")
  local monsterCount = math.random(8, 12) * self.depth
  self.map = WorldMap(worldfile, tileset, self.bumpWorld, monsterCount, self.seed)
  local cw, ch = self.map:getDimensions()
  self.worldCanvas = love.graphics.newCanvas(cw, ch)

  -- add monsters
  for i, coord in ipairs(self.map.monsterCoords) do
    local monster = Monster(coord)
    table.insert(self.behaviors, Behavior(monster))
    self:spawn(monster)
  end

  -- add players
  self.roster = Save:shipRoster(self.ship)
  local center = Point()
  local activePlayers = {}
  local active = false
  for playerdata in values(self.roster) do
    if playerdata.activePlayer then
      activePlayers[playerdata.activePlayer] = playerdata
      active = true
    end
  end
  if not active then
    activePlayers[1] = true
  end
  for i, coord in ipairs(self.map.playerCoords) do
    if i <= 4 then
      local hud = HUD(self, i)
      self.huds[i] = hud
    end

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
  for hud in values(self.huds) do
    hud.active = true
  end
end

function World:deactivate()
  Save:saveShip(self.ship, self.roster)
  for player in values(self.players) do
    player.active = false
  end
  for hud in values(self.huds) do
    hud.active = false
  end
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
  rosterData.activePlayer = index
  local player = Human(coords, rosterData)
  player.active = self.active
  Controller:register(player, index)
  self:spawn(player)
  self.players[index] = player
  self.huds[index].player = player
  self.indicators[index] = Indicator(index)

  return player
end

function World:removePlayer(index, keepBody)
  local player = self.players[index]
  if keepBody ~= true then
    self:despawn(player)
  end
  self.players[index] = nil
  self.huds[index].player = nil
  self.indicators[index] = nil

  local left = false
  for p in values(self.players) do left = true end
  for h in values(self.huds) do
    if #h.itemGrid > 0 then left = true end
  end
  if not left then
    self.fsm:advance('quit', self.ship)
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

  for p, player in pairs(self.players) do
    if player:stunned() then
      self.huds[p].player = nil
      self.indicators[p] = nil

      local others = invert(self.players)
      others[player] = nil
      local r = player:rect():inset(-16)
      local items, len = self.bumpWorld:queryRect(r.x, r.y, r.w, r.h, function(item)
        return others[item]
      end)
      if len == 0 then
        player.rescueTime = nil
      else
        for other in values(items) do
          if player.rescueTime == nil then player.rescueTime = 0 end
          if not other:isMoving() then
            player.rescueTime = player.rescueTime + dt
          else
            player.rescueTime = math.max(0, player.rescueTime - dt * .5)
          end
        end
        if player.rescueTime > 3 then
          self:removePlayer(p)
        end
      end
    end
    if player:dead() then
      local rosterIndex
      for r, data in ipairs(self.roster) do
        if data.name == player.name then
          rosterIndex = r
          break
        end
      end
      table.remove(self.roster, rosterIndex)
      Save:saveShip(self.ship, self.roster)
      self:removePlayer(p, true)
    end
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
          if Gob.collideFilter(gob, info.item) then
            table.insert(limitedInfo, info)
            if gob:hitLineStop(info.item) then
              gob.hitLine.x2 = info.x1
              gob.hitLine.y2 = info.y1
              break
            end
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

function World:descend(gob, verb)
  verb = coalesce(verb, "descend")
  local isPlayer = false
  for player in values(self.players) do
    if player == gob then
      isPlayer = true
      break
    end
  end
  if not isPlayer then return end
  Save:saveShip(self.ship, self.roster)
  self.fsm:advance(verb, {ship = self.ship, planet = self.planet, depth = self.depth + 1})
end

function World:drawRescue(player)
  local font = Fonts.small
  graphicsContext({
    font=font,
    color={0, 0, 0, 127},
    lineWidth=1
  },
  function()
    local rescueRect = Rect(player:center(), font:getWidth("Rescue"), font:getHeight())
    rescueRect = rescueRect + Point(-rescueRect.w/2, player.h / 2 + 5)
    rescueRect = rescueRect:inset(-1)
    rescueRect:draw("fill")

    local alpha
    if player.rescueTime ~= nil then
      love.graphics.setColor(255, 0, 0)
      local w = rescueRect.w
      rescueRect.w = w * (player.rescueTime / 3)
      rescueRect:draw("fill")
      rescueRect.w = w
      alpha = 255
    else
      alpha = 127
    end
    love.graphics.setColor(255, 0, 0)
    rescueRect:draw("line")
    love.graphics.setColor(255, 255, 255, alpha)
    love.graphics.print("Rescue", rescueRect.x + 1, rescueRect.y + 1)
  end)
end

function World:draw()
  love.graphics.push()
  love.graphics.origin()
  self.worldCanvas:clear()
  love.graphics.setCanvas(self.worldCanvas)
  self.worldCanvas:clear()
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
    if dude.stunned and dude:stunned() and not dude:dead() then
      self:drawRescue(dude)
    end
  end


  love.graphics.pop()
  love.graphics.setCanvas()

  local screens = { self.mainScreen }
  table.extend(screens, self.extraScreens)
  local hud = self.huds[1]

  local sw, sh = self.worldCanvas:getDimensions()
  for screen in values(screens) do
    local bgRect = Rect(screen.windowOffset.x - 1, screen.windowOffset.y - 1, screen.w + 2, screen.h + 2 + hud.barHeight)
    if bgRect.y < self.mainScreen.h / 2 then
      bgRect.y = bgRect.y - hud.barHeight
    end
    if self.background then
      local bw, bh = self.background:getDimensions()
      local bgQuad = love.graphics.newQuad(bgRect.x, bgRect.y,
        bgRect.w, bgRect.h,
        bw, bh)
      love.graphics.draw(self.background, bgQuad, bgRect.x, bgRect.y)
    else
      graphicsContext({color={0,0,0}}, function()
        love.graphics.rectangle("fill", bgRect.x, bgRect.y, bgRect.w, bgRect.h)
      end)
    end
    local quad = love.graphics.newQuad(
      round(screen.x), round(screen.y),
      screen.w, screen.h,
      sw, sh)
    love.graphics.draw(self.worldCanvas, quad, screen.windowOffset.x, screen.windowOffset.y)
  end

  local drawn = {}
  for i, player in pairs(self.players) do
    local ind = self.indicators[i]

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

        if ind then
          local indSz = Size(ind.w, ind.h)
          for p in values(drawn) do
            if Rect(p, indSz):intersects(Rect(pos, indSz)) then
              pos.x = p.x + indSz.w
            end
          end
        end
      end
      if dir == "" then
        dir = "down"
      end

      if ind then
        ind:draw(pos.x, pos.y, dir)
      end
      table.insert(drawn, pos)
    end
  end

  for hud in values(self.huds) do
    hud:draw()
  end

  if self.paused then
    graphicsContext({ color={0, 0, 0, 127}, font=Fonts.large, lineWidth=2 },
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
