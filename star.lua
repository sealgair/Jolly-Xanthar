require 'position'
require 'utils'

Star = class("Star")

function drawGlobe(c, radius, image, orient, gctx)
  local w = radius * 2
  local iw = image:getWidth()
  local s = w / iw
  local off = radius / s

  graphicsContext(gctx, function()
    love.graphics.draw(image, c.x, c.y, orient, s, s, off, off)
  end)
end

function Star:init(pos, seed)
  self.pos = pos
  self.seed = coalesce(seed, 0) .. tostring(pos:round(5))
  randomSeed(self.seed)
  self.luminosity = math.random()^5 * 1000
  self.mass = math.random()
  self.metalicity = math.random()
  self.rot = math.random() * 2 * math.pi

  self.cache = {}
end

function Star:name()
  local p = self.pos:round(2)
  return "SC-"..p.x.."-"..p.y.."-"..p.z
end

function Star:color()
  local y = math.min((self.luminosity - 2400) / 3600, 1) * 255
  local w = math.min((self.luminosity - 6000) / 4000, 1) * 255
  local b = math.min(math.min(self.luminosity, 10000) / 30000, 1)
  b = math.max(1-b)
  return {255 * b, y * b, w}
end

function Star:details(viewpoint)
  local details = self:name().."\n"
  details = details .. "Dst: "..round(self:distance(viewpoint), 1).."pc  "
  details = details .. "Tmp: "..round(self.luminosity, 2).."°  "
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
    return .4 * math.log10(self:apparentLuminosity(viewpoint))
  end)
end

function Star:tripTime(viewpoint, idp)
  idp = coalesce(idp, 1)
  local parsecs = self:distance(viewpoint)
  local ly = parsecs * 3.26163344
  return round(ly, idp)
end

function Star:drawPoint(point, origin)
  local mag = self:apparentMagnitude(origin)
  local a = math.min(mag, 1)
  local color = self:color()
  love.graphics.setColor(colorWithAlpha(color, 255*a))
  love.graphics.points(point.x, point.y)
  if mag > 1 then
    local cm = math.ceil(mag)
    for l = 1, cm do
      a = ((cm - l)/mag)^2.5
      a = math.min(a, 1)
      love.graphics.setColor(colorWithAlpha(color, 255*a))
      love.graphics.points(
        point.x+l, point.y,
        point.x-l, point.y,
        point.x, point.y+l,
        point.x, point.y-l
      )
    end
  end
end

function Star:drawClose(c, radius)
  drawGlobe(c, radius, love.graphics.newImage('assets/stars/star1.png'), self.rot,
            { color = self:color(), lineWidth = 1.5 })
end

function Star:planets()
  if self._cachedPlanets == nil then
    self._cachedPlanets = {}
    randomSeed(self.seed)
    local pcount = round(math.random() * self.metalicity * 20)
    for i = 1, pcount do
      table.insert(self._cachedPlanets, Planet(self.seed .. "p" .. i))
    end
  end
  return self._cachedPlanets
end


Planet = class('Planet')

function Planet:init(seed)
  self.seed = seed
  randomSeed(self.seed)
  self.mass = math.random() ^ 2 * 100
  self.radius = self.mass
  self.drawRadius = math.log10(self.radius) * 10
  self.dist = math.random() ^ 2 * 100
  self.rot = math.random() * 2 * math.pi
  self.orient = math.random() * 2 * math.pi

  self.imageName = randomChoice({
    "life2",
    "rock1",
  })
end

function Planet:draw(c)
  local filename = self.imageName
  if self.drawRadius <= 8 then
    filename = filename .. '_sm'
  end
  filename = 'assets/planets/'..filename..'.png'
  local image = love.graphics.newImage(filename)
  drawGlobe(c, self.drawRadius, image, self.rot, {color = Colors.white})
end

function Planet:__eq(rhs)
  return self.seed == rhs.seed
end