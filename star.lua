require 'position'
require 'utils'

Star = class("Star")

function Star:init(pos, seed)
  self.pos = pos
  self.seed = coalesce(seed, 0) .. tostring(pos:round(5))
  randomSeed(self.seed)
  self.luminosity = math.random()^5 * 1000
  self.mass = math.random()
  self.metalicity = math.random()

  self.cache = {}
end

function Star:name()
  local p = self.pos:round(2)
  return "SC-"..p.x.."-"..p.y.."-"..p.z
end

function Star:color()
  local g = math.min(self.luminosity * .5, 255)
  local b = math.min(self.luminosity * .5 - g, 255)
  return {255, g, b}
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
  graphicsContext({ color = Colors.white }, function()
    local color = self:color()
    for i = 1, 5 do
      local a = 255 * (i/5)
      love.graphics.setColor(colorWithAlpha(color, a))
      love.graphics.circle("fill", c.x, c.y, radius - (i - 1), 20)
    end
  end)
end

function Star:planets()
  if self.planets == nil then
    self.planets = {}
    randomSeed(self.seed)
    local pcount = round(math.random() * self.mass * 20)
    for i = 1, pcount do
      table.insert(self.planets, Planet(self.seed .. "p" .. i))
    end
  end
  return self.planets
end


Planet = class('Planet')

function Planet:init(seed)
  self.seed = seed
  randomSeed(self.seed)
  self.mass = math.random() ^ 3 * 100
  self.dist = math.random() ^ 3 * 100
end