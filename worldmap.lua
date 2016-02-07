class = require 'lib/30log/30log'
json = require 'lib.json4lua.json.json'
require 'wall'

WorldMap = class('WorldMap')

function WorldMap:init(mapfile, imagefile, bumpWorld, monsterCount)
  local templateImg = love.graphics.newImage(imagefile)
  local qw, qh = 8, 8
  local sw, sh = templateImg:getWidth(), templateImg:getHeight()

  -- create our quads
  local tileJson, _ = love.filesystem.read("assets/worlds/tiles.json")
  local tileData = json.decode(tileJson)
  local quadMap = map(tileData, function(coord)
    return love.graphics.newQuad((coord[1] - 1) * qw, (coord[2] - 1) * qh, qw, qh, sw, sh)
  end)

  -- translate mapfile to quads
  local quads = {}
  local mw = 0
  local blocks = self:fileToTable(mapfile)
  local function testEmpty(y, x)
    local block
    local row = blocks[y]
    if row then
      block = row[x]
    end
    if block == nil then
      block = "#" -- null is wall
    end
    return block ~= "#"
  end

  self.playerCoords = {}
  local potentialMonsters = {}

  local quadrants = {
    Point(-1, -1),
    Point(1, -1),
    Point(-1, 1),
    Point(1, 1),
  }

  local bw, bh = 16, 16
  for y, row in ipairs(blocks) do
    local topQuadRow = {}
    local btmQuadRow = {}
    for x, block in ipairs(row) do
      local dx = (x - 1) * bw
      local dy = (y - 1) * bh
      local key
      if block == "#" then
        bumpWorld:add(Wall(), dx, dy, bw, bh)

        for q, off in ipairs(quadrants) do
          key = 'w' .. q
          if testEmpty(y, x + off.x) then key = key .. 'v' end
          if testEmpty(y + off.y, x) then key = key .. 'h' end
          if key == 'w' .. q and testEmpty(y + off.y, x + off.x) then key = key .. 'c' end
          local qr
          if q < 3 then qr = topQuadRow else qr = btmQuadRow end
          table.insert(qr, quadMap[key])
        end

      else
        key = 'f'
        if block:find("%d") then
          self.playerCoords[tonumber(block)] = { x = dx, y = dy }
        else
          table.insert(potentialMonsters, { x = dx, y = dy })
        end

        for q, off in ipairs(quadrants) do
          key = 'f'
          if not testEmpty(y, x + off.x) and not testEmpty(y + off.y, x) then key = key .. q .. 'c' end
          local qr
          if q < 3 then qr = topQuadRow else qr = btmQuadRow end
          table.insert(qr, quadMap[key])
        end
      end
    end

    for quadRow in values({topQuadRow, btmQuadRow}) do
      mw = math.max(#quadRow, mw)
      table.insert(quads, quadRow)
    end
  end
  local mh = #quads

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
  love.graphics.push()
    love.graphics.origin()
    self.mapCanvas = love.graphics.newCanvas(mw * qw, mh * qh)
    love.graphics.setCanvas(self.mapCanvas)
    for y, quadRow in ipairs(quads) do
      y = (y - 1) * qh
      for x, quad in ipairs(quadRow) do
        x = (x - 1) * qw
        love.graphics.draw(templateImg, quad, x, y)
      end
    end
    love.graphics.setCanvas()
  love.graphics.pop()
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
