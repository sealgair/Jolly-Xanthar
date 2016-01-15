class = require 'lib/30log/30log'
require 'menu.abstractMenu'
require 'position'
require 'camera'
require 'utils'

local SectorSize = 20

function seedFromPoint(p)
  local seedStr = "0"
  for i in values({p.x, p.y, coalesce(p.z)}) do
    seedStr = seedStr..string.format("%07d", round(i * 100))
  end
  return tonumber(seedStr)
end

Star = class("Star")

function Star:init(pos, seed)
  self.pos = pos
  local seed = coalesce(seed, 0) + seedFromPoint(pos)
  math.randomseed(seed)
  local r = math.random()
  self.magnitude = r^4 * -20 + 10
end

function Star:apparentMagnitude(viewpoint)
  local d = self.pos - viewpoint
  d = math.sqrt(d.x * d.x + d.y * d.y + d.z * d.z)
  return self.magnitude - 5 * (1 - math.log10(d))
end

function safeAlpha(a)
  return math.max(math.min(a, 255), 0)
end

Sector = class("Sector")

function Sector:init(pos, density, seed)
  self.box = Rect(pos, Size(SectorSize, SectorSize, SectorSize))
  self.seed = coalesce(seed, os.time()) + seedFromPoint(pos)
  local starCount = self.box:area() * density
  local variance = .25

  math.randomseed(self.seed)
  local starFactor = math.random() * .25 + (1 - variance/2)
  starCount = round(starFactor * starCount)
  self.stars = {}
  for i=1,starCount do
    local star = Star(Point(
      self.box.x + math.random() * self.box.w,
      self.box.y + math.random() * self.box.h,
      self.box.z + math.random() * self.box.d
    ), self.seed)
    table.insert(self.stars, star)
  end
end

Galaxy = Menu:extend("Galaxy")

function Galaxy:init(fsm)
  Galaxy.super.init(self, {
    fsm = fsm,
    itemGrid = {
      { '', 'up', 'up', 'up', 'up', '' },
      { 'left', Point(0, 0), Point(1, 0), Point(2, 0), Point(3, 0), 'right' },
      { 'left', Point(0, 1), Point(1, 1), Point(2, 1), Point(3, 1), 'right' },
      { 'left', Point(0, 2), Point(1, 2), Point(2, 2), Point(3, 2), 'right' },
      { 'left', Point(0, 3), Point(1, 3), Point(2, 3), Point(3, 3), 'right' },
      { '', 'down', 'down', 'down', 'down', '' },
    },
    navMaps = {
      left = {
        up = Point(2, 1),
        down = Point(2, 6),
      },
      right = {
        up = Point(5, 1),
        down = Point(5, 6),
      },
      up = {
        left = Point(1, 2),
        right = Point(6, 2),
      },
      down = {
        left = Point(1, 5),
        right = Point(6, 5),
      },
    },
    initialItem = Point(2, 1)
  })
  self.seed = 1000
  self.sector = Sector(Point(0,0,0), 0.14, self.seed)
  self.camera = Camera(self.sector.box:center(), Orientations.front, Size(GameSize))
  self.galaxyRect = Rect(0, 0, Size(GameSize)):inset(16)
  self:drawCanvas()

  self.background = love.graphics.newImage('assets/galaxy.png')
  local sw, sh = self.background:getDimensions()
  self.menuQuads = {
    up = love.graphics.newQuad(113, 3, 30, 8, sw, sh),
    down = love.graphics.newQuad(113, 229, 30, 8, sw, sh),
    left = love.graphics.newQuad(2, 105, 8, 30, sw, sh),
    right = love.graphics.newQuad(245, 105, 8, 30, sw, sh),
  }
end

function Galaxy:chooseItem(item)
  local rot = Orientations[item]
  if not self.newOrientation and rot then
    self.newOrientation = self.camera.orientation:rotate(rot)
  end
end

function Galaxy:setDirection(direction)
  if self.newOrientation == nil then
    Galaxy.super.setDirection(self, direction)
  end
end

function Galaxy:update(dt)
  if self.newOrientation then
    if self.newOrientation.age == nil then
      self.newOrientation.age = 0
    else
      self.newOrientation.age = self.newOrientation.age + dt
    end
    local dtheta = easeInOutQuad(self.newOrientation.age) * math.pi / 2
    local no = self.newOrientation
    local co = self.camera.orientation

    for coord in values({'x', 'y', 'z'}) do
      if no[coord] > co[coord] then
        co[coord] = math.min(co[coord] + dtheta, no[coord])
      elseif no[coord] < co[coord] then
        co[coord] = math.max(co[coord] - dtheta, no[coord])
      end
    end
    self.camera.orientation = Orientation(co.x, co.y, co.z)
    if self.camera.orientation == self.newOrientation then
      self.newOrientation = nil
    end
    self:drawCanvas()
  end
end

function Galaxy:drawCanvas()
  local size = self.galaxyRect:size()
  if self.canvas then
    self.canvas:clear()
  else
    self.canvas = love.graphics.newCanvas(size.w, size.h)
  end
  graphicsContext({canvas=self.canvas, color=Colors.white, origin=true}, function()
    for star in values(self.sector.stars) do
      local point = self.camera:project(star.pos)
      point = point:round() + Point(0.5, 0.5)
      love.graphics.point(point.x, point.y)
      self:drawStar(point, star:apparentMagnitude(self.camera.position))
    end
  end)
end

function Galaxy:drawStar(pos, mag)
  local a = 1
  if mag > 0 then a = 1/mag end
  love.graphics.setColor({255, 255, 255, 255*a})
  love.graphics.point(pos.x, pos.y)
  if mag < 0 then
    mag = -mag * .75
    local cm = math.ceil(mag)
    for l = 1, cm do
      a = (cm-l) / mag
      a = a^2.5
      love.graphics.setColor({255, 255, 255, 255*a})
      love.graphics.point(pos.x+l, pos.y)
      love.graphics.point(pos.x-l, pos.y)
      love.graphics.point(pos.x, pos.y+l)
      love.graphics.point(pos.x, pos.y-l)
    end
  end
end

function Galaxy:draw()
  local r = self.galaxyRect
  love.graphics.draw(self.canvas, r.x, r.y)

  local sectorSize = r:size() / 4
  graphicsContext({color = {255, 255, 255, 64}}, function()
    local w = sectorSize.w
    for x = r.x + w - 0.5, r:right() - w, w do
      love.graphics.line(x, r.y, x, r:bottom())
    end
    local h = sectorSize.h
    for y = r.y + h -0.5, r:bottom() - h, h do
      love.graphics.line(r.x, y, r:right(), y)
    end
  end)

  local sel = self:selectedItem()
  if class.isInstance(sel, Point) then
    graphicsContext({color = {255, 255, 0, 128}}, function()
      local sector = Rect(Point(), sectorSize)
      sector = sector + r:origin() + sel * sectorSize - Point(1, 1)
      sector:draw("line")
    end)
  end
  love.graphics.draw(self.background)
  local quad = self.menuQuads[sel]
  if quad then
    graphicsContext({color = Colors.red}, function()
      local x, y, w, h = quad:getViewport( )
      love.graphics.draw(self.background, quad, x, y)
    end)
  end
end