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
  local l = self.luminosity * 10
  local y = math.min((l - 2400) / 3600, 1) * 255
  local w = math.min((l - 6000) / 4000, 1) * 255
  local b = math.min(math.min(l, 10000) / 30000, 1)
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

function Star:apparentBrightness(viewpoint)
  return self:cached("brightness:" .. tostring(viewpoint), function()
    local b = math.log10(self:apparentLuminosity(viewpoint))
    return b
  end)
end

function Star:tripTime(viewpoint, idp)
  idp = coalesce(idp, 1)
  local parsecs = self:distance(viewpoint)
  local ly = parsecs * 3.26163344
  return round(ly, idp)
end

function Star:drawClose(c, radius)
  drawGlobe(c, radius, love.graphics.newImage('assets/stars/star1.png'), self.rot,
            { color = self:color(), lineWidth = 1.5 })
end

function Star:planets()
  if self._cachedPlanets == nil then
    self._cachedPlanets = {}
    randomSeed(self.seed)
    local r = math.random()
    local pcount = round(r * self.metalicity * 20)
    for i = 1, pcount do
      table.insert(self._cachedPlanets, Planet(self, self.seed .. "p" .. i, i))
    end
  end
  return self._cachedPlanets
end


Planet = class('Planet')

function Planet:init(star, seed, index)
  self.star = star
  self.seed = seed
  if index then self.index = index end
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

function Planet:name()
  local chars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  }
  return self.star:name() .. ' ' .. chars[self.index]
end

function Planet:draw(c, drawScale)
  local dr = self.drawRadius * coalesce(drawScale, 1)
  local filename = self.imageName
  filename = 'assets/planets/'..filename..'.png'
  local image = love.graphics.newImage(filename)
  drawGlobe(c, dr, image, self.rot, {color = Colors.white})
end

function Planet:__eq(rhs)
  return self.seed == rhs.seed
end