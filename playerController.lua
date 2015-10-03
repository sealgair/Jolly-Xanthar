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
  self.waningActions = {}
end

function PlayerController:update(dt)
  for action, time in pairs(self.waningActions) do
    if time > dt then
      self.waningActions[action] = time - dt
    else
      self.waningActions[action] = nil
    end
  end
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
    self.waningActions[action] = 0.2

    if diretionsMap[action] then
      self:notifyDirection()
    else
      for key, listener in pairs(self.listeners) do
        listener:controlStop(action)
      end
    end
  end
end

function PlayerController:directionFromActions(actions)
    local direction = Direction(0,0)
    for control, _ in pairs(actions) do
      local ctlDir = diretionsMap[control]
      if ctlDir then
        direction = direction:add(ctlDir)
      end
    end
    return direction
end

function PlayerController:notifyDirection()
  local direction = self:directionFromActions(self.actions)
  for key, listener in pairs(self.listeners) do
    if direction == Direction(0, 0) then
        local waningDirection = self:directionFromActions(self.waningActions)
        listener:setDirection(waningDirection)
    end
    listener:setDirection(direction)
  end
end

function PlayerController:register(listener)
  table.insert(self.listeners, listener)
end
