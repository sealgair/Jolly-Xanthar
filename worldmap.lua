class = require 'lib.30log.30log'
md5 = require 'lib.md5.md5'
json = require 'lib.json4lua.json.json'
require 'tile'
require 'utils'


WorldMap = class('WorldMap')

function WorldMap:init(mapfile, imagefile, bumpWorld, monsterCount, seed)
  local templateImg = love.graphics.newImage(imagefile)

  self.seed = seed

  -- create our tiles
  local qw, qh = 16, 16
  local blocks = self:fileToTable(mapfile)
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
      bumpWorld:add(tile, dx, dy, qw, qh)
    end
    table.insert(tiles, trow)
  end

  self.monsterCoords = {}
  local seen = {}
  local i = math.random(#potentialMonsters)
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

function WorldMap:fileToTable(filename)
  local padx = GameSize.w / 2 / 16
  local pady = GameSize.h / 2 / 16
  local w = 1

  local blocks = {}
  for line in love.filesystem.lines(filename) do
    local blockrow = {}
    for x = 1, string.len(line) do
      table.insert(blockrow, line:sub(x, x))
    end
    pad(blockrow, padx, "#")
    w = math.max(w, #blockrow)
    table.insert(blocks, blockrow)
  end
  local p = {}
  for _ = 1, w do table.insert(p, "#") end
  pad(blocks, pady, p)
  return blocks
end

function WorldMap:draw()
  love.graphics.draw(self.mapCanvas)
end

function WorldMap:getDimensions()
  return self.mapCanvas:getDimensions()
end