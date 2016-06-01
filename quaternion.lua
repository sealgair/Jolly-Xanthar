class = require 'lib/30log/30log'

Quaternion = class("Quaternion")

function Quaternion:init(x, y, z, w)
  self.x = x
  self.y = y
  self.z = z
  self.w = w
end

function Quaternion.euler(x, y, z)
	local c1 = math.cos(x / 2)
	local c2 = math.cos(y / 2)
	local c3 = math.cos(z / 2)
	local s1 = math.sin(x / 2)
	local s2 = math.sin(y / 2)
	local s3 = math.sin(z / 2)

	return Quaternion(
		(s1 * s2 * c3) + (c1 * c2 * s3),
		(s1 * c2 * c3) + (c1 * s2 * s3),
		(c1 * s2 * c3) - (s1 * c2 * s3),
		(c1 * c2 * c3) - (s1 * s2 * s3)
  )
end

function Quaternion:parts()
  return self.x, self.y, self.z, self.w
end

function Quaternion:raw()
  return {self:parts()}
end

function Quaternion:__mul(other)
  local x1, y1, z1, w1 = self:parts()
  local x2, y2, z2, w2 = other:parts()
	return Quaternion(
		w1*x2 + x1*w2 + y1*z2 - z1*y2,
		w1*y2 - x1*z2 + y1*w2 + z1*x2,
		w1*z2 + x1*y2 - y1*x2 + z1*w2,
		w1*w2 - x1*x2 - y1*y2 - z1*z2
  )
end