class = require 'lib.30log.30log'
md5 = require 'lib.md5.md5'
json = require 'lib.json4lua.json.json'
rot = require 'lib.rotlove.rotlove.rotlove'
require 'tile'
require 'utils'


WorldMap = class('WorldMap')

function WorldMap:generateMap(w, h)
  randomSeed(self.seed)
  local blocks = {}
  local generator = rot.Map.Brogue:new(w, h, {}, self)

  local floors = {}
  generator:create(function(x, y, value)
    if value == 1 then
      value = "#"
    else
      value = " "
      table.insert(floors, Point(x, y))
    end
    local row = setDefault(blocks, y, {})
    row[x] = value
  end)

  local door = table.remove(floors, math.random(#floors))
  blocks[door.y][door.x] = 'D'

  local player = table.remove(floors, math.random(#floors))
  for p = 1, 4 do
    blocks[player.y][player.x] = tostring(p)
    for d in values(Direction.allDirections) do
      local next = player + d
      if blocks[next.y][next.x] == " " then
        player = next
        break
      end
    end
  end

  return blocks
end

function WorldMap:random(min, max)
  if max then
    return math.random(min, max)
  elseif min then
    return math.random(min)
  else
    return math.random()
  end
end

function WorldMap:init(mapfile, imagefile, bumpWorld, monsterCount, seed)
  local templateImg = love.graphics.newImage(imagefile)

  self.seed = seed

  -- create our tiles
  local qw, qh = 16, 16
  local blocks
  if mapfile then
    blocks = self:fileToTable(mapfile)
  else
    blocks = self:generateMap(50, 50)
  end
  local padx = GameSize.w / 2 / 16
  local pady = GameSize.h / 2 / 16
  padMap(blocks, padx, pady)
  local mw = 0
  local mh = #blocks

  self.playerCoords = {}
  local potentialMonsters = {}
  self.transporters = {}

  local tiles = {}
  for y, row in ipairs(blocks) do
    mw = math.max(mw, #row)
    local trow = {}
    for x, block in ipairs(row) do
      local TileType = Tile.typeForBlock(block)
      local tile = TileType(x, y, blocks, templateImg)
      table.insert(trow, tile)
      local dx, dy = (x - 1) * qw, (y - 1) * qh
      if tile.player then
        self.playerCoords[tile.player] = Point(dx, dy)
      elseif tile.isFloor then
        table.insert(potentialMonsters, Point(dx, dy))
      end
      if tile.collides then
        bumpWorld:add(tile, dx, dy, qw, qh)
      end
      if class.isInstance(tile, Teleporter) then
        table.insert(self.transporters, tile)
      elseif class.isInstance(tile, NavCom) then
        if not self.navCom then
          self.navCom = tile.hitbox
        else
          self.navCom = self.navCom:union(tile.hitbox)
        end
      end
    end
    table.insert(tiles, trow)
  end

  self.monsterCoords = {}
  local seen = {}
  local i = math.random(#potentialMonsters)
  monsterCount = math.min(#potentialMonsters, monsterCount)
  for _ = 1, monsterCount do
    while seen[i] ~= nil do
      i = math.random(#potentialMonsters)
    end
    seen[i] = true
    table.insert(self.monsterCoords, potentialMonsters[i])
  end

  -- draw quads to canvas
  local hueShifter = love.graphics.newShader("shaders/hueShift.glsl")
  if self.seed then
    randomSeed(self.seed)
  end
  hueShifter:send("shift", math.random())

  self.mapCanvas = love.graphics.newCanvas(mw * qw, mh * qh)
  graphicsContext({origin=true, shader=hueShifter, canvas=self.mapCanvas}, function()
    for y, tileRow in ipairs(tiles) do
      y = (y - 1) * qh
      for x, tile in ipairs(tileRow) do
        x = (x - 1) * qw
        tile:draw(x, y)
      end
    end
  end)
end

function pad(tbl, amount, value)
  for _ = 1, amount do
    table.insert(tbl, 1, value)
    table.insert(tbl, value)
  end
  return tbl
end

function padMap(map, w, h, value)
  local maxw = 0
  value = coalesce(value, "#")
  for row in values(map) do
    pad(row, w, value)
    maxw = math.max(maxw, #row)
  end
  local padRow = {}
  for _ = 1, maxw do table.insert(padRow, "#") end
  pad(map, h, padRow)
end

function WorldMap:fileToTable(filename)
  local blocks = {}
  for line in love.filesystem.lines(filename) do
    local blockrow = {}
    for x = 1, string.len(line) do
      table.insert(blockrow, line:sub(x, x))
    end
    table.insert(blocks, blockrow)
  end
  return blocks
end

function WorldMap:draw()
  love.graphics.draw(self.mapCanvas)
end

function WorldMap:getDimensions()
  return self.mapCanvas:getDimensions()
end