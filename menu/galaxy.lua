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


Sector = class("Sector")

function Sector:init(pos, density, seed)
  self.box = Rect(pos, Size(SectorSize, SectorSize, SectorSize))
  self.seed = coalesce(seed, os.time()) + seedFromPoint(pos)
  local starCount = self.box:area() * density
  print("sector with base star count", starCount)
  local variance = .25

  math.randomseed(self.seed)
  local starFactor = math.random() * .25 + (1 - variance/2)
  starCount = round(starFactor * starCount)
  print("sector with real star count", starCount)
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
  local xscale = GameSize.w / self.box.w
  local yscale = GameSize.h / self.box.h
  graphicsContext({canvas=self.canvas, color=Colors.white}, function()
    print("drawing", #self.stars, "stars")
    for s, star in ipairs(self.stars) do
      local pos = star.pos - self.pos
      pos.x = round(pos.x * xscale)
      pos.y = round(pos.y * yscale)
      love.graphics.circle("fill", pos.x, pos.y, star.luminosity, 8)
    end
    print("done drawn")
  end)
end

Galaxy = class("Galaxy")

function Galaxy:init(fsm, seed)
  print("galaxy created")
  self.fsm = fsm
  self.seed = coalesce(seed, os.time())
  self.sector = Sector(Point(0,0,0), 0.14, self.seed)
end

function Galaxy:update(dt)
end

function Galaxy:draw()
  love.graphics.draw(self.sector.canvas)
end