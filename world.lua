require 'controller'

World = {}

setmetatable(World, {
  __newindex = function(self, key, value)
    rawset(self, key, value)
    if key == 'active' then
      for i, player in pairs(self.players) do
        player.active = self.active
      end
    end
  end
})

function World:renderMap(mapfile, imagefile)
  local templateImg = love.graphics.newImage(imagefile)
  local qw, qh = 16, 16
  local sw, sh = templateImg:getWidth(), templateImg:getHeight()

  local quads = {}
  local mw = 0
  for line in love.filesystem.lines(mapfile) do
    local quadRow = {}
    for x = 1, string.len(line) do
      mw = math.max(x, mw)
      local block = line:sub(x, x)
      if block == "#" then
        table.insert(quadRow, love.graphics.newQuad(32, 16, qw, qh, sw, sh))
      else
        table.insert(quadRow, love.graphics.newQuad(0, 0, qw, qh, sw, sh))
      end
    end
    table.insert(quads, quadRow)
  end
  local mh = # quads

  love.graphics.push()
    love.graphics.origin()
    local mapCanvas = love.graphics.newCanvas(mw * qw, mh * qh)
    love.graphics.setCanvas(mapCanvas)
    for y, quadRow in ipairs(quads) do
      y = (y-1) * qh
      for x, quad in ipairs(quadRow) do
        x = (x-1) * qw
        love.graphics.draw(templateImg, quad, x, y)
      end
    end
    love.graphics.setCanvas()
  love.graphics.pop()
  return mapCanvas
end

function World:load()
  self.players = {
    Player(0, 0),
    Player(0, 32),
    -- Player(32, 0),
    -- Player(32, 32),
  }
  self.worldCanvas = love.graphics.newCanvas()
  self.mapCanvas = self:renderMap("worldMaps/ship1.world", "assets/worlds/ship.png")

  for i, player in ipairs(self.players) do
    Controller:register(player, i)
  end
end

function World:update(dt)
  self.center = {x=0, y=0}
  for i, dude in ipairs(self.players) do
    dude:update(dt)
    self.center.x = self.center.x + dude:center().x
    self.center.y = self.center.y + dude:center().y
  end
  self.center.x = round(self.center.x / # self.players)
  self.center.y = round(self.center.y / # self.players)
end

function World:draw()
  love.graphics.push()
    love.graphics.origin()
    self.worldCanvas:clear()
    love.graphics.setCanvas(self.worldCanvas)
    love.graphics.draw(self.mapCanvas)
    for i, dude in ipairs(self.players) do
      dude:draw()
    end
  love.graphics.pop()
  love.graphics.setCanvas()

  local offx = round(Size.w / 2) - self.center.x
  local offy = round(Size.h / 2) - self.center.y
  love.graphics.draw(self.worldCanvas, offx, offy)
end
