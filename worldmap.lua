class = require 'lib/30log/30log'

WorldMap = class('WorldMap', {
  quadNames = {
    {'f1', 'ul',  'u',   'ur',  'udlr'},
    {'f2', 'l',   'c',   'r',   'lr'},
    {'f3', 'dl',  'd',   'dr',  'ud'},
    {'f4', 'dlr', 'udr', 'udl', 'ulr'},
  }
})

function WorldMap:init(mapfile, imagefile, bumpWorld)
  local templateImg = love.graphics.newImage(imagefile)
  local qw, qh = 16, 16
  local sw, sh = templateImg:getWidth(), templateImg:getHeight()

  -- create our quads
  local quadMap = {}
  for y, row in ipairs(self.quadNames) do
    y = (y-1)*qh
    for x, name in ipairs(row) do
      x = (x-1)*qw
      quadMap[name] = love.graphics.newQuad(x, y, qw, qh, sw, sh)
    end
  end

  -- translate mapfile to quads
  local quads = {}
  local mw = 0
  local blocks = self:fileToTable(mapfile)
  function testEmpty(y, x)
    local block = nil
    local row = blocks[y]
    if row then
      block = row[x]
    end
    if block == nil then
      block = "#"  -- null is wall
    end
    return block ~= "#"
  end

  for y, row in ipairs(blocks) do
    local quadRow = {}
    for x, block in ipairs(row) do
      if block == "#" then
        key = ''
        if testEmpty(y-1, x) then key = key .. 'u' end
        if testEmpty(y+1, x) then key = key .. 'd' end
        if testEmpty(y, x-1) then key = key .. 'l' end
        if testEmpty(y, x+1) then key = key .. 'r' end
        if key == '' then key = 'c' end
        bumpWorld:add({name="wall"}, (x-1)*qw, (y-1)*qh, qw, qh)
      else
        key = 'f' .. tostring(math.random(1, 4))
      end
      table.insert(quadRow, quadMap[key])
    end
    mw = math.max(# quadRow, mw)
    table.insert(quads, quadRow)
  end
  local mh = # quads

  -- draw quaods to canvas
  love.graphics.push()
    love.graphics.origin()
    self.mapCanvas = love.graphics.newCanvas(mw * qw, mh * qh)
    love.graphics.setCanvas(self.mapCanvas)
    for y, quadRow in ipairs(quads) do
      y = (y-1) * qh
      for x, quad in ipairs(quadRow) do
        x = (x-1) * qw
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
