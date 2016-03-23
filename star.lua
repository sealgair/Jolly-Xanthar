require 'position'
require 'utils'

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