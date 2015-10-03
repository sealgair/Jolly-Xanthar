require "direction"

PlayerController = {
  listeners = {}
}

local diretionsMap = {
  down = Direction(0, 1),
  up = Direction(0, -1),
  left = Direction(-1, 0),
  right = Direction(1, 0),
}

function PlayerController:load()
  local controlData = love.filesystem.load('controls.lua')
  print(controlData)
  self.controls = controlData()
  self.actions = {}
end

function PlayerController:keypressed(key)
  local action = self.controls[key]

  if action then
    self.actions[action] = 1

    if diretionsMap[action] then
      self:notifyDirection()
    else
      for key, listener in pairs(self.listeners) do
        listener:controlStart(action)
      end
    end
  end
end

function PlayerController:keyreleased(key)
  action = self.controls[key]
  if action then
    self.actions[action] = nil

    if diretionsMap[action] then
      self:notifyDirection()
    else
      for key, listener in pairs(self.listeners) do
        listener:controlStop(action)
      end
    end
  end
end

function PlayerController:notifyDirection()
  local direction = Direction(0,0)
  for control, _ in pairs(self.actions) do
    local ctlDir = diretionsMap[control]
    if ctlDir then
      direction = direction:add(ctlDir)
    end
  end
  for key, listener in pairs(self.listeners) do
    listener:setDirection(direction)
  end
end

function PlayerController:register(listener)
  table.insert(self.listeners, listener)
end
