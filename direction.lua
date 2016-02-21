class = require 'lib/30log/30log'

Direction = class('Direction', {x=0, y=0})

Direction.keys = {
    'down',
    'downleft',
    'left',
    'upleft',
    'up',
    'upright',
    'right',
    'downright',
}

function Direction:init(x, y)
  self.x = x
  self.y = y
  self:normalize()
end

function Direction:normalize()
  if self.x > 0 then
    self.x = 1
  elseif self.x < 0 then
    self.x = -1
  end

  if self.y > 0 then
    self.y = 1
  elseif self.y < 0 then
    self.y = -1
  end
end

function Direction:vector()
  return {
    x = self.x,
    y = self.y,
  }
end

function Direction:isDiagonal()
  return self.x ~= 0 and self.y ~= 0
end

function Direction:horizontal()
  return Direction(self.x, 0)
end

function Direction:vertical()
  return Direction(0, self.y)
end

function Direction:add(rhs)
  return Direction(self.x + rhs.x, self.y + rhs.y)
end

function Direction:sub(rhs)
  return Direction(self.x - rhs.x, self.y - rhs.y)
end

function Direction:reverse()
  return Direction(self.x * -1, self.y * -1)
end

function Direction:shortkey()
  local result = ""
  if self.y > 0 then
    result = "d"
  elseif self.y < 0 then
    result = "u"
  end
  if self.x > 0 then
    result = result .. "r"
  elseif self.x < 0 then
    result = result .. "l"
  end
  return result
end

function Direction:key()
  local result = ""
  if self.y > 0 then
    result = "down"
  elseif self.y < 0 then
    result = "up"
  end
  if self.x > 0 then
    result = result .. "right"
  elseif self.x < 0 then
    result = result .. "left"
  end
  return result
end

function Direction:__tostring()
  if self:key() == "" then
    return "center"
  else
    return self:key()
  end
end

function Direction:__unm()
  return Direction(-self.x, -self.y)
end

function Direction:__eq(rhs)
  return self.x == rhs.x and self.y == rhs.y
end

-- set up named keys for each direction on the Direction class
for _, x in pairs({-1, 0, 1}) do
  for _, y in pairs({-1, 0, 1}) do
    local d = Direction(x, y)
    Direction[d:key()] = d
  end
end

Direction.allDirections = {
  Direction.downleft,
  Direction.left,
  Direction.upleft,
  Direction.up,
  Direction.upright,
  Direction.right,
  Direction.downright,
  Direction.down,
}

local clockwise = {
  down = Direction.downleft,
  downleft = Direction.left,
  left = Direction.upleft,
  upleft = Direction.up,
  up = Direction.upright,
  upright = Direction.right,
  right = Direction.downright,
  downright = Direction.down,
}

local counterclockwise = {}
for key, dir in pairs(clockwise) do
  counterclockwise[dir:key()] = Direction[key]
end

function Direction:turnRight()
  return clockwise[self:key()]
end

function Direction:turnLeft()
  return counterclockwise[self:key()]
end

function Direction:radians()
  if self == Direction(0, 0) then
    return nil
  end
  local d = Direction.right
  local r = 0
  while d ~= self do
    r = r + .25
    d = d:turnRight()

    -- prevent weird infinite loops
    if r >= 2 then
      return nil
    end
  end
  return r * math.pi
end