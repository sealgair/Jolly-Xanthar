class = require 'lib/30log/30log'
json = require 'lib.json4lua.json.json'
require 'wall'
require 'utils'

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

  local function blockAt(x, y)
    local block
    local row = blocks[y]
    if row then
      block = row[x]
    end
    return block
  end

  local function testEmpty(y, x)
    local block = blockAt(x, y)
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
    -- todo: boy, this could use some cleanup
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

      elseif block == "W" then
        for q, off in ipairs(quadrants) do
          key = 'h' .. q
          if blockAt(x + off.x, y) ~= block or blockAt(x, y + off.y) ~= block then
            key = 'f'
            if not testEmpty(y, x + off.x) and not testEmpty(y + off.y, x) then key = key .. q .. 'c' end
          else
            if blockAt(x - off.x, y) ~= block then key = key .. 'v' end
            if blockAt(x, y - off.y) ~= block then key = key .. 'h' end
            if key == 'h' .. q then
              if blockAt(x - off.x, y - off.y) ~= block then
                key = key .. 'c'
              elseif blockAt(x + off.x, y + off.y) ~= block then
                key = 'f'
              elseif blockAt(x - off.x, y + off.y) ~= block then
                key = key .. 'v'
              elseif blockAt(x + off.x, y - off.y) ~= block then
                key = key .. 'h'
              end
            end
          end
          local qr
          if q < 3 then qr = topQuadRow else qr = btmQuadRow end
          table.insert(qr, quadMap[key])
        end

      else
        if block:find("%d") then
          local coord = Point{ x = dx, y = dy }
          self.playerCoords[tonumber(block)] = coord
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
  local hueShifter = love.graphics.newShader("shaders/hueShift.glsl")
  hueShifter:send("shift", math.random())

  self.mapCanvas = love.graphics.newCanvas(mw * qw, mh * qh)
  graphicsContext({origin=true, shader=hueShifter, canvas=self.mapCanvas}, function()
    for y, quadRow in ipairs(quads) do
      y = (y - 1) * qh
      for x, quad in ipairs(quadRow) do
        x = (x - 1) * qw
        love.graphics.draw(templateImg, quad, x, y)
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