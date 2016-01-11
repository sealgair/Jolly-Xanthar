class = require 'lib/30log/30log'
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
  self.luminosity = math.random()
end

function safeAlpha(a)
  return math.max(math.min(a, 255), 0)
end

function Star:draw(sx, sy)
  local alpha = self.luminosity * 1.5 * 255
  love.graphics.setColor(255, 255, 255, safeAlpha(alpha))

  local p = Point(round(self.pos.x * sx) + .5, round(self.pos.y * sy) + .5)
  love.graphics.point(p.x, p.y)

  local d = 1
  local da = 255/3
  alpha = alpha - da
  while alpha > 0 do
    love.graphics.setColor(255, 255, 255, safeAlpha(alpha))
    love.graphics.point(p.x, p.y+d)
    love.graphics.point(p.x, p.y-d)

    if alpha > da then
      love.graphics.setColor(255, 255, 255, safeAlpha(alpha - da))
      love.graphics.point(p.x+d, p.y)
      love.graphics.point(p.x-d, p.y)
      if d > 1 then
        local dd = d-1
        love.graphics.point(p.x+dd, p.y+dd)
        love.graphics.point(p.x+dd, p.y-dd)
        love.graphics.point(p.x-dd, p.y+dd)
        love.graphics.point(p.x-dd, p.y-dd)
      end
    end
    alpha = alpha - da
    d = d + 1
  end
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

  self.canvas = love.graphics.newCanvas(GameSize.w, GameSize.h)
  graphicsContext({canvas=self.canvas, color=Colors.white, origin=true}, function()
    local sx = GameSize.w / self.box.w
    local sy = GameSize.h / self.box.h

    for star in values(self.stars) do
      star:draw(sx, sy)
    end
  end)
end

Galaxy = class("Galaxy")

function Galaxy:init(fsm, seed)
  self.fsm = fsm
  self.seed = coalesce(seed, os.time())
  self.sector = Sector(Point(0,0,0), 0.14, self.seed)
  self.camera = Camera(self.sector.box:center(), Orientations.front, Size(GameSize))
  self:drawCanvas()
end

function Galaxy:update(dt)
end

function Galaxy:drawCanvas()
  self.canvas = love.graphics.newCanvas(GameSize.w, GameSize.h)
  graphicsContext({canvas=self.canvas, color=Colors.white, origin=true}, function()
    for star in values(self.sector.stars) do
      local point = self.camera:project(star.pos)
      point = point:round() + Point(0.5, 0.5)
      love.graphics.point(point.x, point.y)
    end
  end)
end

function Galaxy:draw()
  love.graphics.draw(self.canvas)
end