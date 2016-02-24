class = require 'lib.30log.30log'
md5 = require 'lib.md5.md5'
json = require 'lib.json4lua.json.json'
rot = require 'lib.rotlove.rotlove.rotlove'
require 'tile'
require 'utils'


WorldMap = class('WorldMap')

function generateMap(w, h)
  local blocks = {}
  local players = {'1', '2', '3', '4'}
  local generator = rot.Map.Brogue:new(w, h)
  local doorCoord
  generator:create(function(x, y, value)
    if value == 1 then
      value = "#"
    else
      if #players > 0 then
        value = table.remove(players, 1)
      else
        value = " "
        doorCoord = Point(x, y)
      end
    end
    local row = setDefault(blocks, y, {})
    row[x] = value
  end)
  blocks[doorCoord.y][doorCoord.x] = 'D'
  return blocks
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
    blocks = generateMap(50, 50)
  end
  local padx = GameSize.w / 2 / 16
  local pady = GameSize.h / 2 / 16
  padMap(blocks, padx, pady)
  local mw = 0
  local mh = #blocks

  self.playerCoords = {}
  local potentialMonsters = {}

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