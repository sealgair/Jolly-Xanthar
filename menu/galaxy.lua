class = require 'lib/30log/30log'
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

function Star:draw(sx, sy)
  local alpha = math.min(self.luminosity * 3, 1) * 255
  love.graphics.setColor(255, 255, 255, alpha)

  love.graphics.point(round(self.pos.x * sx) + .5, round(self.pos.y * sy) + .5)
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
end

function Galaxy:update(dt)
end

function Galaxy:draw()
  love.graphics.draw(self.sector.canvas)
end