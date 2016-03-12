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
  self.luminosity = r^5 * 1000
end

function Star:apparentLuminosity(viewpoint)
  local d = (self.pos - viewpoint):magSquared()
  return self.luminosity / d
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
  self.rot = Point(0, 0, 0)

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
  -- #TODO
end

function Galaxy:setDirection(direction)
  self.rot = Point(
    -direction.y * math.pi/2,
    direction.x * math.pi/2,
    0
  )
end

function Galaxy:update(dt)
  if self.rot.x ~= 0 or self.rot.y ~= 0 then
    self.camera.orientation = self.camera.orientation:rotate(self.rot * dt)
    self:drawCanvas()
  end
end

function Galaxy:drawCanvas()
  local size = self.galaxyRect:size()
  if not self.canvas then
    self.canvas = love.graphics.newCanvas(size.w, size.h)
  end
  local r = Rect(Point(), size)
  graphicsContext({canvas=self.canvas, color=Colors.white, origin=true}, function()
    love.graphics.clear()
    local v, d = 0, 0
    for s, star in ipairs(self.sector.stars) do
      local l = star:apparentLuminosity(self.camera.position)
      if l > 1 then
        v = v + 1
        local point = self.camera:project(star.pos)
        if point and r:contains(point) then
          d = d + 1
          point = point:round() + Point(0.5, 0.5)
          self:drawStar(point, l)
        end
      end
    end
  end)
end

function Galaxy:drawStar(pos, lum)
  local mag = 1.7 * math.log10(lum)
  local a = math.min(mag, 1)
  love.graphics.setColor({255, 255, 255, 255*a})
  love.graphics.points(pos.x, pos.y)
  if mag > 1 then
    local cm = math.ceil(mag)
    for l = 1, cm do
      a = ((cm - l)/mag)^2.5
      a = math.min(a, 1)
      love.graphics.setColor({255, 255, 255, 255*a})
      love.graphics.points(
        pos.x+l, pos.y,
        pos.x-l, pos.y,
        pos.x, pos.y+l,
        pos.x, pos.y-l
      )
    end
  end
end

function Galaxy:draw()
  local r = self.galaxyRect
  love.graphics.draw(self.canvas, r.x, r.y)

  love.graphics.draw(self.background)
  local quad = self.menuQuads[sel]
  if quad then
    graphicsContext({color = Colors.red}, function()
      local x, y, w, h = quad:getViewport( )
      love.graphics.draw(self.background, quad, x, y)
    end)
  end
end