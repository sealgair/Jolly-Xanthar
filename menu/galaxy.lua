class = require 'lib/30log/30log'
require 'menu.abstractMenu'
require 'position'
require 'camera'
require 'utils'

local SectorSize = 50
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
  self.seed = seed
  local seed = coalesce(seed, 0) + seedFromPoint(pos)
  math.randomseed(seed)
  local r = math.random()
  self.luminosity = r^5 * 1000
  self.mass = math.random()
  self.metalicity = math.random()

  self.cache = {}
end

function Star:name()
  local p = self.pos:round(2)
  return "SC-"..p.x.."-"..p.y.."-"..p.z
end

function Star:details(viewpoint)
  local details = self:name().."\n"
  details = details .. "Dst: "..round(self:distance(viewpoint), 1).."pc  "
  details = details .. "Lum: "..round(self.luminosity, 2).."⊙  "
  details = details .. "Mtl: "..round(self.metalicity, 4).."  "
  return details
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
  return self:cached("distanceSq:" .. tostring(viewpoint), function()
    return (self.pos - viewpoint):magSquared()
  end)
end

function Star:apparentLuminosity(viewpoint)
  return self:cached("luminosity:" .. tostring(viewpoint), function()
    return self.luminosity / self:squaredDistance(viewpoint)
  end)
end

function Star:apparentMagnitude(viewpoint)
  return self:cached("magnitude:" .. tostring(viewpoint), function()
    return 1.7 * math.log10(self:apparentLuminosity(viewpoint))
  end)
end

function Star:tripTime(viewpoint, idp)
  idp = coalesce(idp, 1)
  local parsecs = self:distance(viewpoint)
  local ly = parsecs * 3.26163344
  return round(ly, idp)
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
    telescope = "Navigate",
  }

  self.starFilters = {
    near = function(star) return star:squaredDistance(self.camera.position) end,
    size = function(star) return star.mass end,
    bright = function(star) return star.luminosity end,
    metal = function(star) return star.metalicity end,
    galaxy = function(star) return 1/star:squaredDistance(self.camera.position) end,
  }
  self.currentFilterKey = "near"

  self.seed = 1000
  self.sector = Sector(Point(0,0,0), 0.14, self.seed)

  self.fsmOpts = opts
  self.ship = coalesce(self.fsmOpts.ship, Save:shipNames()[1])
  self.shipStar = coalesce(Save:shipStar(self.ship), Star(self.sector.box:center(), self.seed))

  self.camera = Camera(self.shipStar.pos, Orientations.front, Size(GameSize))
  self.galaxyRect = Rect(0, 0, Size(GameSize)):inset(16)
  self.rotationDir = Point(0, 0, 0)
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
  if self.confirmTravel then
    Save:saveShip(self.ship, nil, self.selectedStar)
    self.fsm:advance('back', self.fsmOpts)
  end
  if item == 'back' then
    self.fsm:advance('back', self.fsmOpts)
  elseif item == 'telescope' then
    if self.orienting then
      self.confirmTravel = true
    else
      self.orienting = true
    end
  elseif self.starFilters[item] then
    self.currentFilterKey = item
    self:filterStars()
  end
end

function Galaxy:cancelItem(item)
  if self.confirmTravel then
    self.confirmTravel = false
  elseif item == 'telescope' then
    self.orienting = false
  end
end

function Galaxy:setDirection(direction)
  if self.orienting then
    if self.confirmTravel then return end
    local speed = math.pi/16
    if direction:isDiagonal() then
      -- diagonal, use pythagoras
      speed = speed / 1.414
    end
    self.rotationDir = Point(
      -direction.y * speed,
      direction.x * speed
    )
  else
    Galaxy.super.setDirection(self, direction)
  end
end

function Galaxy:update(dt)
  if self.rotationDir.x ~= 0 or self.rotationDir.y ~= 0 then
    local rot = self.rotationDir * dt
    self.camera:rotate(rot.x, rot.y)
    self:drawCanvas()
  end
end

function Galaxy:drawCanvas()
  local size = self.galaxyRect:size()
  if not self.canvas then
    self.canvas = love.graphics.newCanvas(size.w, size.h + 20)
  end
  local r = Rect(Point(), size)
  graphicsContext({canvas=self.canvas, color=Colors.white, origin=true, font=Fonts.small, lineWidth=1}, function()
    love.graphics.clear()
    local v, d = 0, 0
    local centerPoint = self.galaxyRect:center() - self.galaxyRect:origin()
    local centerStarPoint = Point(0, 0)
    centerStarPoint.dist = 10000
    local centerStar
    for s, star in ipairs(self.filteredStars) do
      v = v + 1
      local point = self.camera:project(star.pos)
      if point and r:contains(point) then
        d = d + 1
        point = point:round() + Point(0.5, 0.5)
        self:drawStar(point, star:apparentMagnitude(self.camera.position))

        local dist = centerPoint:distanceToSquared(point)
        if dist < centerStarPoint.dist then
          centerStarPoint = point
          centerStarPoint.dist = dist
          centerStar = star
        end
      end
    end
    self.selectedStar = centerStar

    love.graphics.setColor({0, 255, 0, 128})
    love.graphics.circle("fill", centerStarPoint.x, centerStarPoint.y, 2.75, 8)
    love.graphics.setColor({64, 128, 255, 200})
    local cp = centerPoint + Point(0.5, 0.5)
    local cr = 2
    love.graphics.line(cp.x - cr, cp.y, cp.x + cr, cp.y)
    love.graphics.line(cp.x, cp.y - cr, cp.x, cp.y + cr)
  end)
end

function Galaxy:drawStar(pos, mag)
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
  if self.orienting then
    desc = "A: Travel   B: Cancel"
  end
  graphicsContext({color = Colors.menuBlue, font = Fonts.medium}, function()
    if desc then
      love.graphics.print(desc, 18, 5)
    end

    local detailStar
    if self.orienting then
      detailStar = self.selectedStar
    else
      detailStar = self.shipStar
    end
    if detailStar then
      love.graphics.setColor({0, 128, 0})
      love.graphics.setFont(Fonts.small)
      love.graphics.print(detailStar:details(self.shipStar.pos), self.galaxyRect.x + 2, self.galaxyRect:bottom() + 2)
    end
  end)

  if self.confirmTravel then
    graphicsContext({ color = colorWithAlpha(Colors.black, 128), font = Fonts.medium }, function()
      local r = Rect(Point(), GameSize)
      r:draw("fill")

      local c = r:center()
      r = Rect(Point(), GameSize.w / 2, GameSize.h / 4)
      r:setCenter(c)
      love.graphics.setColor(Colors.black)
      r:draw("fill")
      love.graphics.setColor(Colors.white)
      r:draw("line")
      r = r:inset(4)
      local travelmsg = "Travel to new system? Trip will take "..self.selectedStar:tripTime(self.shipStar.pos).." years."
      travelmsg = travelmsg .. "\nA: Go  B: Stay"
      local x, y, w, h = r:parts()
      love.graphics.printf(travelmsg, x, y, w, "center")
    end)
  end
end