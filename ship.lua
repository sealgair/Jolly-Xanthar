require 'world'

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

function Ship:init(fsm, ship)
  self.shipFile = "myship.world"
  local roomFiles = randomize({
    "assets/worlds/barracks.world",
    "assets/worlds/observation.world",
  })

  self.background = love.graphics.newImage("assets/stars.png")

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

  self:writeShip(data)
  Ship.super.init(self, fsm, ship, self.shipFile, "assets/worlds/ship.png", 0)
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