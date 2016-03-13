class = require 'lib/30log/30log'
require 'menu.abstractMenu'
require 'position'
require 'camera'
require 'utils'

local SectorSize = 60
local FilterLimit = 1000

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
  self.mass = math.random()
  self.metalicity = math.random()

  self.cache = {}
end

function Star:cached(key, fn)
  local v = self.cache[key]
  if v == nil then
    v = fn()
    self.cache[key] = v
  end
  return v
end

function Star:distance(viewpoint)
  return self:cached("distance:" .. tostring(viewpoint), function()
    return math.sqrt(self:squaredDistance(viewpoint))
  end)
end

function Star:squaredDistance(viewpoint)
  return self:cached("distance" .. tostring(viewpoint), function()
    return (self.pos - viewpoint):magSquared()
  end)
end

function Star:apparentLuminosity(viewpoint)
  return self.luminosity / self:squaredDistance(viewpoint)
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

function Galaxy:init(fsm, opts)
  Galaxy.super.init(self, {
    fsm = fsm,
    itemGrid = {
      {'back', 'telescope'},
      {'near', 'telescope'},
      {'size', 'telescope'},
      {'bright', 'telescope'},
      {'metal', 'telescope'},
      {'galaxy', 'telescope'},
    },
    initialItem = Point(1, 2)
  })
  self.itemDescriptions = {
    back = "Exit NavCom",
    near = "Nearest Stars",
    metal = "Most Metallic Stars",
    size = "Biggest Stars",
    bright = "Hottest Stars",
    galaxy = "Galactic Features",
  }

  self.starFilters = {
    near = function(star) return star:squaredDistance(self.camera.position) end,
    size = function(star) return star.mass end,
    bright = function(star) return star.luminosity end,
    metal = function(star) return star.metalicity end,
    galaxy = function(star) return 1/star:squaredDistance(self.camera.position) end,
  }
  self.currentFilterKey = "near"

  self.fsmOpts = opts
  self.seed = 1000
  self.sector = Sector(Point(0,0,0), 0.14, self.seed)
  self.camera = Camera(self.sector.box:center(), Orientations.front, Size(GameSize))
  self.galaxyRect = Rect(0, 0, Size(GameSize)):inset(16)
  self.rot = Point(0, 0, 0)
  self:filterStars()

  self.background = love.graphics.newImage('assets/galaxy.png')
  local sw, sh = self.background:getDimensions()
  self.menuQuads = {}
  local w, h = 14, 14
  for r, row in ipairs(self.itemGrid) do
    local item = row[1]
    local x = 0
    local y = (r - 1) * 16
    self.menuQuads[item] = love.graphics.newQuad(x, y, w, h, sw, sh)
  end
end

function Galaxy:filterStars()
  self.filteredStars = {}
  local stars = table.ifilter(self.sector.stars, function(star)
    return star:apparentLuminosity(self.camera.position) > 1
  end)
  local f = self.starFilters[self.currentFilterKey]
  table.sort(stars, function(a, b)
    return f(a) < f(b)
  end)
  for i = 1, FilterLimit do
    self.filteredStars[i] = stars[i]
  end
  self:drawCanvas()
end

function Galaxy:chooseItem(item)
  if item == 'back' then
    self.fsm:advance('back', self.fsmOpts)
  elseif item == 'telescope' then
    self.orienting = true
  elseif self.starFilters[item] then
    self.currentFilterKey = item
    self:filterStars()
  end
end

function Galaxy:cancelItem(item)
  if item == 'telescope' then
    self.orienting = false
  end
end

function Galaxy:setDirection(direction)
  if self.orienting then
    self.rot = Point(
      -direction.y * math.pi/2,
      direction.x * math.pi/2,
      0
    )
  else
    Galaxy.super.setDirection(self, direction)
  end
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
    for s, star in ipairs(self.filteredStars) do
      v = v + 1
      local point = self.camera:project(star.pos)
      if point and r:contains(point) then
        d = d + 1
        point = point:round() + Point(0.5, 0.5)
        self:drawStar(point, star:apparentLuminosity(self.camera.position))
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
  local quad = self.menuQuads[self.currentFilterKey]
  if quad then
    graphicsContext({color = Colors.yellow}, function()
      local x, y, w, h = quad:getViewport( )
      love.graphics.draw(self.background, quad, x, y)
    end)
  end

  local sel = self:selectedItem()
  local quad = self.menuQuads[sel]
  if quad then
    graphicsContext({color = Colors.red}, function()
      local x, y, w, h = quad:getViewport( )
      love.graphics.draw(self.background, quad, x, y)
    end)
  elseif sel == 'telescope' and not self.orienting then
    graphicsContext({color = Colors.red, lineWidth=1}, function()
      local r = Rect(15, 15, 225, 209)
      r:draw('line')
      love.graphics.setColor(colorWithAlpha(Colors.red, 128))
      r:inset(1):draw('line')
    end)
  end
  local desc = self.itemDescriptions[sel]
  if desc then
    graphicsContext({color = Colors.menuBlue, font = Fonts.medium}, function()
      love.graphics.print(desc, 18, 5)
    end)
  end
end