Orientation = class('Orientation')

function Orientation:init(x, y, z)
  self.x = x
  self.y = y
  self.z = z
  self.vec = {
    x = self.x,
    y = self.y,
    z = self.z
  }

  self.cos = map(self.vec, function(n) return math.cos(-n) end)
  self.sin = map(self.vec, function(n) return math.sin(-n) end)
end

function Orientation:rotate(other)
  local x = self.x + other.x
  x = math.min(x, math.pi/2)
  x = math.max(x, -math.pi/2)
  local y = self.y + other.y
  local res = Orientation(x, y, self.z + other.z)
  return res
end

function Orientation:__eq(other)
  return self.x == other.x and self.y == other.y and self.z == other.z
end

function Orientation:__unm()
  return Orientation(-self.x, -self.y, -self.z)
end

function Orientation:__add(o)
  return Orientation(self.x + o.x, self.y + o.y, self.z + o.z)
end

function Orientation:__sub(o)
  return self + -o
end

function Orientation:__tostring()
  return tostring(Point(self))
end

local pi = math.pi
Orientations = {
  front = Orientation(0, 0, 0),
  back  = Orientation(0, 0, pi),
  left  = Orientation(0, -pi/2, 0),
  right = Orientation(0, pi/2, 0),
  up    = Orientation(pi/2, 0, 0),
  down  = Orientation(-pi/2, 0, 0),
}

Camera = class("Camera")

function Camera:init(position, orientation, screenSize)
  self.position = position
  self.orientation = orientation
  self.screenSize = coalesce(screenSize, Size(1,1))
end

function Camera:__tostring()
  return "Camera at "..tostring(self.position).." facing "..tostring(self.orientation)
end

-- https://en.wikipedia.org/wiki/3D_projection#Perspective_projection
function Camera:project(point)
  local p = point - self.position
  local c = self.orientation.cos
  local s = self.orientation.sin
  local x, y, z = p.x, p.y, p.z

  local cyz = c.y * z
  local czx = c.z * x
  local czy = c.z * y
  local szx = s.z * x
  local szy = s.z * y
  local d = {
    x = c.y * (szy + czx) - s.y * z,
    y = s.x * (cyz + s.y * (szy + czx)) + c.x * (czy - szx),
    z = c.x * (cyz + s.y * (szy + czx)) - s.x * (czy - szx)
  }
  local b = Point(
    d.x / -d.z,
    d.y / -d.z
  )
  b = (b + Point(1, 1)) * .5 * self.screenSize
  return b
end