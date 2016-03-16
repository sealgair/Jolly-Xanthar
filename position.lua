class = require 'lib/30log/30log'
require 'utils'

Point = class('Point')

function Point:init(x, y, z)
  if type(x) == "table" and tonumber(x.x) and tonumber(x.y) then
    self:init(x.x, x.y, x.z)
  else
    if x == nil then x = 0 end
    assert(tonumber(x), "invalid input: " .. x .. " is not a number")
    self.x = tonumber(x)
    if tonumber(y) then
      self.y = y
    else
      self.y = x
    end
    self.z = z
  end
end

function Point:__tostring()
  local s = "("..self.x..", "..self.y
  if self.z then
    s = s..", "..self.z
  end
  s = s..")"
  return s
end

function Point:__eq(other)
  return self.x == other.x and self.y == other.y and self.z == other.z
end

function Point:__unm()
  local z = self.z
  if z then z = -z end
  return Point(-self.x, -self.y, z)
end

function Point:__add(other)
  if class.isInstance(other, Point) then
    local z
    if self.z and other.z then
      z = self.z + other.z
    end
    return Point(self.x + other.x, self.y + other.y, z)
  else
    if pcall(function() Point(other) end) then
      return self + Point(other)
    else
      error("cannot add "..type(other).." '"..other.."' to a Point")
    end
  end
end

function Point:__sub(other)
  if class.isInstance(other, Point) then
    return self + -other
  else
    if pcall(function() Point(other) end) then
      return self - Point(other)
    else
      error("cannot subtract "..type(other).." '"..other.."' from a Point")
    end
  end
end

function Point:__mul(s)
  if tonumber(s) then
    s = Size(s, s, s)
  elseif not class.isInstance(s, Size) then
    s = Size(s)
  end
  local z = self.z
  if z and s.d then
    z = z * s.d
  end
  return Point(self.x * s.w, self.y * s.h, z)
end

function Point:__div(s)
  assert(tonumber(s), "invalid input: " .. s .. " is not a number")
  s = 1 / s
  return self * s
end

function Point:round(idp)
  local z = self.z
  if self.z then z = round(z, idp) end
  return Point(round(self.x, idp), round(self.y, idp), z)
end

function Point:abs()
  local z = self.z
  if self.z then z = math.abs(z) end
  return Point(math.abs(self.x), math.abs(self.y), z)
end

function Point:magSquared()
  local square = self.x * self.x + self.y * self.y
  if self.z then
    square = square + self.z * self.z
  end
  return square
end

function Point:magnitude()
  return math.sqrt(self:magSquared())
end

function Point:distanceToSquared(other)
  return (self - other):magSquared()
end

function Point:distanceTo(other)
  return (self - other):magnitude()
end

function Point:normalize()
  return self / self:magnitude()
end

function Point:isZero()
  return self.x == 0 and self.y == 0 and (self.z == nil or self.z == 0)
end


Size = class('Size')

function Size:init(w, h, d)
  if type(w) == "table" and tonumber(w.w) and tonumber(w.h) then
    self:init(w.w, w.h, w.d)
  else
    assert(tonumber(w), "invalid input 1: " .. w .. " is not a number")
    self.w = tonumber(w)
    if h == nil then
      self.h = self.w
    else
      assert(tonumber(h), "invalid input 2: " .. h .. " is not a number")
      self.h = tonumber(h)
    end
    self.d = d
  end
end

function Size:__tostring()
  local s = self.w.."X"..self.h
  if self.d then s = s.."X"..self.d end
  return s
end

function Size:__unm()
  local d = self.d
  if d then d = -d end
  return Size(-self.w, -self.h, d)
end

function Size:__add(other)
  if class.isInstance(other, Size) then
    local d
    if self.d and other.d then
      d = self.d + other.d
    end
    return Size(self.w + other.w, self.h + other.h, d)
  else
    if pcall(function() Size(other) end) then
      return self + Size(other)
    else
      error("cannot add "..type(other).." '"..other.."' to a Size")
    end
  end
end

function Size:__sub(other)
  if class.isInstance(other, Size) then
    return self + -other
  else
    if pcall(function() Size(other) end) then
      return self - Size(other)
    else
      error("cannot subtract "..type(other).." '"..other.."' from a Size")
    end
  end
end

function Size:__mul(s)
  assert(tonumber(s), "invalid input: " .. s .. " is not a number")
  local d = self.d
  if d then d = d * s end
  return Size(self.w * s, self.h * s, d)
end

function Size:__div(s)
  assert(tonumber(s), "invalid input: " .. s .. " is not a number")
  s = 1 / s
  return self * s
end

Rect = class('Rect')

function Rect:init(...)
  local keys
  if #{...} == 6 then
    keys = {'x', 'y', 'z', 'w', 'h', 'd' }
  else
    keys = {'x', 'y', 'w', 'h' }
  end
  for i, v in ipairs({...}) do
    if tonumber(v) then
      if #keys > 0 then
        local k = table.remove(keys, 1)
        self[k] = tonumber(v)
      end
    elseif class.isInstance(v, Point) then
      self:setOrigin(v)
      table.removeValue(keys, "x")
      table.removeValue(keys, "y")
      table.removeValue(keys, "z")
    elseif class.isInstance(v, Size) then
      self:setSize(v)
      table.removeValue(keys, "w")
      table.removeValue(keys, "h")
      table.removeValue(keys, "d")
    elseif type(v) == "table" then
      for k in values(keys) do
        if tonumber(v[k]) then
          self[k] = v[k]
        end
      end
    else
      error("invalid input "..i..": " .. v)
    end
  end

  for k in values({'x', 'y', 'w', 'h'}) do
    assert(self[k] ~= nil, "invalid "..k..": no value provided")
    assert(tonumber(self[k]), "invalid "..k..": "..self[k])
  end
end

function Rect:__tostring()
  return tostring(self:origin()) .. " @ " .. tostring(self:size())
end

function Rect:origin()
  return Point(self)
end

function Rect:setOrigin(newOrigin)
  if not class.isInstance(newOrigin, Point) then
    newOrigin = Point(newOrigin)
  end
  self.x = newOrigin.x
  self.y = newOrigin.y
  self.z = newOrigin.z
end

function Rect:center()
  local z
  if self.z and self.d then
    z = self.z + self.d/2
  end
  return Point(self.x + self.w/2, self.y + self.h/2, z)
end

function Rect:setCenter(newCenter)
  if not class.isInstance(newCenter, Point) then
    newCenter = Point(newCenter)
  end
  self.x = newCenter.x - self.w/2
  self.y = newCenter.y - self.h/2
  if newCenter.z and self.d then
    self.z = newCenter.z - self.d/2
  else
    self.z = nil
  end
end

function Rect:bottom()
  return self.y + self.h
end

function Rect:setBottom(btm)
  self.h = btm - self.y
end

function Rect:right()
  return self.x + self.w
end

function Rect:setRight(rgt)
  self.w = rgt - self.x
end

function Rect:back()
  return self.z + self.d
end

function Rect:area()
  return self.w * self.h * coalesce(self.d, 1)
end

function Rect:size()
  return Size(self.w, self.h, self.d)
end

function Rect:setSize(new)
  self.w = new.w
  self.h = new.h
  self.d = new.d
end

function Rect:contains(thing)
  if class.isInstance(thing, Point) then
    local result = self.x < thing.x and thing.x < self:right()
               and self.y < thing.y and thing.y < self:bottom()
    if self.z and thing.z then
      result = result and self.z < thing.z and thing.z < self:back()
    end
    return result
  end
  return false
end

function Rect:intersects(other)
  if class.isInstance(other, Rect) then
    local result = self.x < other:right() and self:right() > other.x
               and self.y < other:bottom() and self:bottom() > other.y
    if self.z and other.z then
      result = result and self.z < other:back() and self.back() > other.z
    end
    return result
  end
  return false
end

function Rect:union(other)
  local r = Rect(
    math.min(self.x, other.x),
    math.min(self.y, other.y),
    0, 0
  )
  r:setBottom(math.max(self:bottom(), other:bottom()))
  r:setRight(math.max(self:right(), other:right()))
  return r
end

function Rect:inset(x, y, z)
  y = coalesce(y, x)
  local d
  if self.d then
    z = coalesce(z, y)
    z = self.z + z
    d = self.d - 2*z
  else
    z = nil
  end
  return Rect(Point(self.x + x, self.y + y, z), Size(self.w - 2*x, self.h - 2*y, d))
end

function Rect:expand(x, y)
  y = coalesce(y, x)
  return self:inset(-x, -y)
end

function Rect:draw(style)
  local r = self:round() + Point(0.5, 0.5)
  love.graphics.rectangle(style, r:parts())
end

function Rect:parts()
  return self.x, self.y, self.w, self.h
end

function Rect:round(idp)
  return Rect(round(self.x, idp), round(self.y, idp), round(self.w, idp), round(self.h, idp))
end

function Rect:__add(other)
  assert(class.isInstance(other, Point), "Cannot add "..type(other).." '".."' to Rect")
  return Rect(self:origin() + other, Size(self.w, self.h, self.d))
end

function Rect:__sub(other)
  assert(class.isInstance(other, Point), "Cannot subtract "..type(other).." '".."' from Rect")
  return Rect(self:origin() - other, Size(self.w, self.h, self.d))
end

function Rect:__mul(s)
  assert(tonumber(s), "invalid input: " .. s .. " is not a number")
  local scaled = Rect(self:origin(), self:size() * s)
  scaled:setCenter(self:center())
  return scaled
end