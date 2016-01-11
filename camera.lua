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

  self.cos = map(self.vec, function(n) return round(math.cos(-n), 6) end)
  self.sin = map(self.vec, function(n) return round(math.sin(-n), 6) end)
end

function Orientation:__eq(other)
  return self.x == other.x and self.y == other.y and self.z == other.z
end

function Orientation:__unm()
  return Orientation(-self.x, -self.y, -self.z)
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
  up    = Orientation(-pi/2, 0, 0),
  down  = Orientation(pi/2, 0, 0),
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

function Camera:project(point, print)
  local p = point - self.position
  local c = self.orientation.cos
  local s = self.orientation.sin
  local x, y, z = p.x, p.y, p.z
  local d = Point {
    x = c.y * (s.z * y + c.z * x) - s.y * z,
    y = s.x * (c.y * z + s.y * (s.z * y + c.z * x)) + c.x * (c.z * y - s.z * x),
    z = c.x * (c.y * z + s.y * (s.z * y + c.z * x)) - s.x * (c.z * y - s.z * x)
  }
  local e = Point(0, 0, -1)
  local b = Point(
    ((e.z / d.z) * d.x - e.x),
    ((e.z / d.z) * d.y - e.y)
  )
  b = (b + Point(1, 1)) * .5 * self.screenSize
  if print then
    print('proj', point, 'a', p, 's', Point(s), 'c', Point(c), 'd', d, 'b', b)
  end
  return b
end