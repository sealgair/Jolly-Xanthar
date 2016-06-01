require 'quaternion'

Camera = class("Camera")

function Camera:init(position, screenSize)
  self.position = position
  self.orientation = Quaternion(0, 0, 0, 1)
  self.screenSize = coalesce(screenSize, Size(1,1))
end

function Camera:__tostring()
  return "Camera at "..tostring(self.position).." facing "..tostring(self.orientation)
end

function Camera:rotate(yaw, pitch)
  local rot = Quaternion.euler(pitch, 0, yaw)
  self.orientation = rot * self.orientation
--  self.orientation = rot:Multiply(self.orientation)
end