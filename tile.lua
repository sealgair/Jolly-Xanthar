class = require 'lib.30log.30log'
require 'position'
require 'utils'

Tile = class('Tile', {tileCoords = {}})

function Tile:init(x, y, tileset, img)
  self.block = tileset[y][x]
  self.img = img

  self.h = 16
  self.w = 16

  self.isFloor = self.block ~= "#"

  self.borders = {}
  for dir in values(Direction.allDirections) do
    local r = coalesce(tileset[y+dir.y], {})
    self.borders[dir:key()] = coalesce(r[x+dir.x], "#")
  end

  local qw, qh = 8, 8
  local sw, sh = img:getWidth(), img:getHeight()
  self.quadMap = map(self.tileCoords, function(coord)
    return love.graphics.newQuad((coord.x) * qw, (coord.y) * qh, qw, qh, sw, sh)
  end)
end

function Tile:draw(x, y)
  local quadrants = {
    Direction.upleft,
    Direction.upright,
    Direction.downleft,
    Direction.downright,
  }
  local dx, dy
  local w = self.w / 4
  local h = self.h / 4
  for q in values(quadrants) do
    local quad = self:quad(q)
    dx = x + w + (w * q.x)
    dy = y + h + (h * q.y)
    if quad then
      love.graphics.draw(self.img, quad, dx, dy)
    end
  end
end

function Tile:quad(quadrant)
  return nil  -- Implement in subclasses
end

function Tile:__tostring()
  return self.class.name .. " " .. self.block
end

Wall = Tile:extend('Wall', {
  tileCoords = {
    [''] = Point(4, 2),
    dv   = Point(1, 0),
    dv2  = Point(2, 0),
    rh   = Point(0, 1),
    lh   = Point(3, 1),
    rh2  = Point(0, 2),
    lh2  = Point(3, 2),
    uv   = Point(1, 3),
    uv2  = Point(2, 3),

    uvlh = Point(4, 0),
    uvrh = Point(5, 0),
    dvlh = Point(4, 1),
    dvrh = Point(5, 1),

    urc  = Point(0, 3),
    ulc  = Point(3, 3),
    drc  = Point(0, 0),
    dlc  = Point(3, 0),
  }
})

function Wall:collidesWith(b)
  return "slide", 1
end

function Wall:collide(cols)
end

function Wall:quad(q)
  local key = ''
  if self.borders[q:vertical():key()] ~= self.block then
    key = key .. q:vertical():shortkey() .. 'v'
  end
  if self.borders[q:horizontal():key()] ~= self.block then
    key = key .. q:horizontal():shortkey() .. 'h'
  end
  if key == '' and self.borders[q:key()] ~= self.block then
    key = q:shortkey() .. 'c'
  end
  return self.quadMap[key]
end

Floor = Tile:extend('Floor')

function Floor:init(x, y, tileset, img)
  Floor.super.init(self, x, y, tileset, img)
  if self.block:find("%d") then
    self.player = tonumber(self.block)
  end
end

function Floor:collidesWith(b)
  return nil, 1
end

function Floor:collide(cols)
end

Hole = Floor:extend('Hole')

function Tile.typeForBlock(block)
  if block == "#" then
    return Wall
  elseif block == "W" then
    return Hole
  else
    return Floor
  end
end