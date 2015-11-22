class = require 'lib/30log/30log'
require 'utils'

Point = class('Point')

function Point:init(x, y)
  if type(x) == "table" and tonumber(x.x) and tonumber(x.y) then
    self:init(x.x, x.y)
  else
    if x == nil then x = 0 end
    assert(tonumber(x), "invalid input: " .. x .. " is not a number")
    self.x = tonumber(x)
    if tonumber(y) then
      self.y = y
    else
      self.y = x
    end
  end
end

function Point:__tostring()
  return "("..self.x..", "..self.y..")"
end

function Point:__unm()
  return Point(-self.x, -self.y)
end

function Point:__add(other)
  if class.isInstance(other, Point) then
    return Point(self.x + other.x, self.y + other.y)
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
  assert(tonumber(s), "invalid input: " .. s .. " is not a number")
  return Point(self.x * s, self.y * s)
end

function Point:__div(s)
  assert(tonumber(s), "invalid input: " .. s .. " is not a number")
  return Point(self.x / s, self.y / s)
end

function Point:abs()
  return Point(math.abs(self.x), math.abs(self.y))
end

function Point:magnitude()
  return math.sqrt(self.x * self.x + self.y * self.y)
end

function Point:normalize()
  return self / self:magnitude()
end

function Point:isZero()
  return self.x == 0 and self.y == 0
end


Size = class('Size')

function Size:init(w, h)
  if type(w) == "table" and tonumber(w.w) and tonumber(w.h) then
    self:init(w.w, w.h)
  else
    assert(tonumber(w), "invalid input 1: " .. w .. " is not a number")
    self.w = tonumber(w)
    if h == nil then
      self.h = self.w
    else
      assert(tonumber(h), "invalid input 2: " .. h .. " is not a number")
      self.h = tonumber(h)
    end
  end
end

function Size:__tostring()
  return self.w.."X"..self.h
end

function Size:__mul(s)
  assert(tonumber(s), "invalid input: " .. s .. " is not a number")
  return Size(self.w * s, self.h * s)
end

function Size:__div(s)
  assert(tonumber(s), "invalid input: " .. s .. " is not a number")
  return Size(self.w / s, self.h / s)
end

Rect = class('Rect')

function Rect:init(...)
  local keys = {'x', 'y', 'w', 'h'}
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
    elseif class.isInstance(v, Size) then
      self:setSize(v)
      table.removeValue(keys, "w")
      table.removeValue(keys, "h")
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
end

function Rect:center()
  return Point(self.x + self.w/2, self.y + self.h/2)
end

function Rect:setCenter(newCenter)
  if not class.isInstance(newCenter, Point) then
    newCenter = Point(newCenter)
  end
  self.x = newCenter.x - self.w/2
  self.y = newCenter.y - self.h/2
end

function Rect:bottom()
  return self.y + self.h
end

function Rect:right()
  return self.x + self.w
end

function Rect:size()
  return Size(self.w, self.h)
end

function Rect:setSize(new)
  self.w = new.w
  self.h = new.h
end

function Rect:contains(thing)
  if class.isInstance(thing, Point) then
    return self.x < thing.x and thing.x < self:right()
       and self.y < thing.y and thing.y < self:bottom()
  end
  return false
end

function Rect:intersects(other)
  if class.isInstance(other, Rect) then
    return self.x < other:right() and self:right() > other.x
       and self.y < other:bottom() and self:bottom() > other.y
  end
  return false
end

function Rect:__add(other)
  assert(class.isInstance(other, Point), "Cannot add "..type(other).." '".."' to Rect")
  return Rect(self:origin() + other, self.w, self.h)
end

function Rect:__sub(other)
  assert(class.isInstance(other, Point), "Cannot subtract "..type(other).." '".."' from Rect")
  return Rect(self:origin() - other, self.w, self.h)
end

function Rect:__mul(s)
  assert(tonumber(s), "invalid input: " .. s .. " is not a number")
  local scaled = Rect(self:origin(), self:size() * s)
  scaled:setCenter(self:center())
  return scaled
end