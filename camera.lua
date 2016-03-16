local Carbon = require("Carbon")
local Quaternion = Carbon.Math.Quaternion
local Vec3 = Carbon.Math.Vector3

local pi = math.pi
Orientations = {
  front = Quaternion:NewFromLooseAngles(0, 0, 0),
  back  = Quaternion:NewFromLooseAngles(0, 0, pi),
  left  = Quaternion:NewFromLooseAngles(0, -pi/2, 0),
  right = Quaternion:NewFromLooseAngles(0, pi/2, 0),
  up    = Quaternion:NewFromLooseAngles(pi/2, 0, 0),
  down  = Quaternion:NewFromLooseAngles(-pi/2, 0, 0),
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
  if p.z < 0 then
    return nil
  end
  local vec = Vec3(p.x, p.y, p.z)
  local d = self.orientation:TransformVector(vec)
  local x, y, z = d[1], d[2], d[3]
  local b = Point(
    x / -z,
    y / -z
  )
  b = (b + Point(1, 1)) * .5 * self.screenSize
  return b
end

function Camera:rotate(yaw, pitch)
  local rot = Quaternion:NewFromLooseAngles(pitch, 0, yaw)
  self.orientation = rot:Multiply(self.orientation)
end