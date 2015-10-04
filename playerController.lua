require "direction"

PlayerController = {
  listeners = {},
  actions = {},
  waningActions = {},
}

local directionsMap = {
  down = Direction(0, 1),
  up = Direction(0, -1),
  left = Direction(-1, 0),
  right = Direction(1, 0),
}

function PlayerController:load()
  local controlData = love.filesystem.load('controls.lua')
  self.playerControls = controlData()
  for player, _ in pairs(self.playerControls) do
    self.actions[player] = {}
    self.waningActions[player] = {}
    self.listeners[player] = {}
  end
end

function PlayerController:actionsForKey(key)
  actions = {}
  for player, controls in ipairs(self.playerControls) do
    for action, k in pairs(controls) do
      if k == key then
        setDefault(actions, player, {})
        table.insert(actions[player], action)
      end
    end
  end
  return actions
end

function PlayerController:update(dt)
  for player, waning in pairs(self.waningActions) do
    for action, time in pairs(waning) do
      if time > dt then
        waning[action] = time - dt
      else
        waning[action] = nil
      end
    end
  end
end

function PlayerController:keypressed(key)
  local playerActions = self:actionsForKey(key)

  for player, actions in pairs(playerActions) do
    for _, action in pairs(actions) do
      self.actions[player][action] = 1

      if directionsMap[action] then
        self:notifyDirection(player)
      else
        for _, listener in pairs(self.listeners[player]) do
          listener:controlStart(action)
        end
      end
    end
  end
end

function PlayerController:keyreleased(key)
  local playerActions = self:actionsForKey(key)

  for player, actions in pairs(playerActions) do
    for _, action in pairs(actions) do
      self.actions[player][action] = nil
      self.waningActions[player][action] = 0.2

      if directionsMap[action] then
        self:notifyDirection(player)
      else
        for _, listener in pairs(self.listeners[player]) do
          listener:controlStop(action)
        end
      end
    end
  end
end

function PlayerController:directionFromActions(actions)
    local direction = Direction(0,0)
    for control, _ in pairs(actions) do
      local ctlDir = directionsMap[control]
      if ctlDir then
        direction = direction:add(ctlDir)
      end
    end
    return direction
end

function PlayerController:notifyDirection(player)
  local direction = self:directionFromActions(self.actions[player])
  for _, listener in pairs(self.listeners[player]) do
    if direction == Direction(0, 0) then
        local waningDirection = self:directionFromActions(self.waningActions[player])
        listener:setDirection(waningDirection)
    end
    listener:setDirection(direction)
  end
end

function PlayerController:register(listener, player)
  table.insert(self.listeners[player], listener)
end
