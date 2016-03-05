require 'world'
require 'interactables'

Room = class(World)

function Room:init(filename, direction)
  self.direction = direction
  self.data = {}
  for line in love.filesystem.lines(filename) do
    local row = {}
    for tile in line:gmatch"." do table.insert(row, tile) end
    table.insert(self.data, row)
  end

  if self.direction == Direction.up then
    self.data = reverseCopy(self.data)
  end

  local doorTiles = {}
  self.h = #self.data
  self.w = 1
  for y, row in ipairs(self.data) do
    self.w = math.max(self.w, #row)
    for x, tile in ipairs(row) do
      if tile == "D" then
        table.insert(doorTiles, Point(x, y))
        row[x] = " "
      end
    end
  end
  self.door = Rect(doorTiles[1], 4, 1)
end

function Room:heighten(height)
  while #self.data < height do
    if self.direction == Direction.down then
      table.insert(self.data, 1, rowOf("#", self.w))
    else
      table.insert(self.data, rowOf("#", self.w))
    end
  end
end

Ship = World:extend('Ship')

function Ship:init(fsm, fsmOpts)
  self.shipFile = "myship.world"
  self.ship = coalesce(fsmOpts.ship, Save:shipNames()[1])
  randomSeed(self.ship)
  local roomFiles = randomize({
    "assets/worlds/barracks.world",
    "assets/worlds/observation.world",
    "assets/worlds/teleporter.world",
  })

  self.background = love.graphics.newImage("assets/stars.png")
  self.switchToImg = love.graphics.newImage("assets/switchTo.png")

  local dir = Direction.down
  local topRooms = {}
  local bottomRooms = {}
  local th, bh = 1, 1
  for roomFile in values(roomFiles) do
    local room = Room(roomFile, dir)
    if dir == Direction.down then
      table.insert(topRooms, room)
      th = math.max(th, room.h)
    else
      table.insert(bottomRooms, room)
      bh = math.max(bh, room.h)
    end
    dir = -dir
  end

  local top = {}
  local w = 0
  for room in values(topRooms) do
    w = w + room.w
    room:heighten(th)
    gridStitch(top, room.data)
  end

  local bottom = rowOf({}, bh)
  for room in values(bottomRooms) do
    room:heighten(bh)
    gridStitch(bottom, room.data)
  end

  local data = {}
  table.extend(data, top)
  local hallRow = rowOf(" ", w)
  table.extend(data, rowOf(hallRow, 4))
  table.extend(data, bottom)

  gridFill(data, "#")

  self:writeShip(data)
  self.allPlayers = {}

  Ship.super.init(self, fsm, {ship=ship, planet="blah"}, self.shipFile, "assets/worlds/ship.png")

  self.playerSwitchers = {}
  for i, coord in ipairs(self.map.playerCoords) do
    local player = self.players[i]
    if player == nil then
      player = Human(coord, self.roster[i])
      self:spawn(player)
    end
    self.allPlayers[i] = player
    self.playerSwitchers[i] = PlayerSwitcher(player)
    player.controlOverride = self
  end
end

function Ship:controlStart(player, action)
end

function Ship:controlStop(player, action)
  if action == 'a' then
    local switchTo = self.playerSwitchOptions[player.playerIndex]
    if switchTo then
      local pid = player.playerIndex
      self:removePlayer(pid)
      self:addPlayer(switchTo:serialize(), pid)
    end
  end
end

function Ship:addPlayer(rosterData, index, coords)
  local player
  for p in values(self.allPlayers) do
    if p.name == rosterData.name then
      player = p
      break
    end
  end
  if player == nil then
    player = Ship.super.addPlayer(self, rosterData, index, coords)
    self.allPlayers[index] = player
  else
    Controller:register(player, index)
    self.huds[index].player = player
    player.active = self.active
    self.indicators[index] = Indicator(index)
    self.players[index] = player
    player.playerIndex = index
  end
  return player
end

function Ship:removePlayer(index, keepBody)
  local player = self.players[index]
  Controller:unregister(player, index)
  self.players[index] = nil
  self.huds[index].player = nil
  self.indicators[index] = nil
  player.playerIndex = nil
end

function Ship:writeShip(data)
  local text = ""
  for row in values(data) do
    for tile in values(row) do
      text = text .. tile
    end
    text = text .. "\n"
  end
  love.filesystem.write(self.shipFile, text)
end

function Ship:update(dt)
  Ship.super.update(self, dt)
  self.playerSwitchOptions = {}

  for switcher in values(self.playerSwitchers) do
    switcher:update(dt)
    if switcher.player.playerIndex == nil then
      local l,t,w,h = switcher.hitbox:parts()
      local items, len = self.bumpWorld:queryRect(l,t,w,h, function(item)
        return item.playerIndex ~= nil
      end)
      for item in values(items) do
        self.playerSwitchOptions[item.playerIndex] = switcher.player
      end
    end
  end
end

function Ship:drawGob(gob)
  local switchTo = self.playerSwitchOptions[gob.playerIndex]

  if switchTo then
    graphicsContext({color=PlayerColors[gob.playerIndex]}, function()
      local imgRect = Rect(0, 0, self.switchToImg:getDimensions())
      imgRect:setCenter(switchTo:center())
      imgRect.y = switchTo.position.y - imgRect.h - 2
      love.graphics.draw(self.switchToImg, imgRect.x, imgRect.y)
    end)
  end

  Ship.super.drawGob(self, gob)
end

function rowOf(val, len)
  local row = {}
  for _ = 1, len do table.insert(row, val) end
  return row
end

function gridStitch(grid, other)
  for r, row in ipairs(other) do
    local d = {}
    if grid[r] then
      for t in values(grid[r]) do
        table.insert(d, t)
      end
    end
    for t in values(row) do
      table.insert(d, t)
    end
    grid[r] = d
  end
end

function gridFill(grid, value)
  local w = 0
  for row in values(grid) do
    w = math.max(w, #row)
  end
  for row in values(grid) do
    if #row < w then
      table.extend(row, rowOf(value, w - #row))
    end
  end
end