require "direction"
defaultControls = require "defaultControls"
local serialize = require "lib/Ser/ser"

Controller = {
  listeners = {},
  actions = {},
  waningActions = {},
  axisTracker = {},
}

local directionsMap = {
  down = Direction(0, 1),
  up = Direction(0, -1),
  left = Direction(-1, 0),
  right = Direction(1, 0),
}

local saveFile = "customControls.lua"

function Controller:load()
  local loaded = love.filesystem.load(saveFile)
  if loaded then
    self.playerControls = loaded()
  else
    self.playerControls = defaultControls
  end
  self.listeners[0] = {}
  for player, controls in pairs(self.playerControls) do
    self.actions[player] = {}
    self.waningActions[player] = {}
    self.listeners[player] = {}
  end
end

function Controller:updatePlayerAction(player, action, keys)
  self.playerControls[player][action] = keys
end

function Controller:saveControls()
  local data = serialize(self.playerControls)
  love.filesystem.write(saveFile, data)
end

function Controller:resetControls()
  self.playerControls = defaultControls
end

function Controller:actionsForKey(key)
  actions = {}
  for player, controls in ipairs(self.playerControls) do
    for action, keySet in pairs(controls) do
      if keySet[key] then
        setDefault(actions, player, {})
        table.insert(actions[player], action)
      end
    end
  end
  return actions
end

function Controller:actionsForButton(joystick, button)
  local key = "joy" .. joystick:getID() .. ":" .. button
  return self:actionsForKey(key)
end

function Controller:update(dt)
  for player, waning in pairs(self.waningActions) do
    for action, time in pairs(waning) do
      if time > dt then
        waning[action] = time - dt
      else
        waning[action] = nil
      end
    end
  end

  local gpAxes = {'leftx', 'lefty', 'rightx', 'righty', 'triggerleft', 'triggerright'}
  for _, js in ipairs(love.joystick.getJoysticks()) do
    for a=1,js:getAxisCount() do
      self:trackAxis(js, a)
    end
  end
end

function Controller:trackAxis(joystick, axis)
  local deadZone = 0.25
  local key = "joy" .. joystick:getID() .. ":ax" .. axis
  local newDir = joystick:getAxis(axis)
  if newDir > deadZone then
    newDir = "+"
  elseif newDir < -deadZone then
    newDir = "-"
  else
    newDir = nil
  end
  local oldDir = self.axisTracker[key]
  self.axisTracker[key] = newDir
  if newDir ~= oldDir then
    if oldDir ~= nil then
      self:keyreleased(key .. oldDir)
    end
    if newDir ~= nil then
      self:keypressed(key .. newDir)
    end
  end
end

function Controller:startActions(playerActions)
  for player, actions in pairs(playerActions) do
    for _, action in pairs(actions) do
      self.actions[player][action] = 1

      if directionsMap[action] then
        self:notifyDirection(player)
      else
        for _, listener in pairs(self:getListeners(player)) do
          if listener and listener.controlStart then
            listener:controlStart(action)
          end
        end
      end
    end
  end
end

function Controller:stopActions(playerActions)
  for player, actions in pairs(playerActions) do
    for _, action in pairs(actions) do
      self.actions[player][action] = nil
      self.waningActions[player][action] = 0.2

      if directionsMap[action] then
        self:notifyDirection(player)
      else
        for _, listener in pairs(self:getListeners(player)) do
          if listener and listener.controlStop then
            listener:controlStop(action)
          end
        end
      end
    end
  end
end

function Controller:keypressed(key)
  if key == ' ' then key = 'space' end
  if self.forward then
    if self.forward.keypressed then
      self.forward:keypressed(key)
    end
  else
    local playerActions = self:actionsForKey(key)
    self:startActions(playerActions)
  end
end

function Controller:keyreleased(key)
  if key == ' ' then key = 'space' end
  if self.forward then
    if self.forward.keyreleased then
      self.forward:keyreleased(key)
    end
  else
    local playerActions = self:actionsForKey(key)
    self:stopActions(playerActions)
  end
end

function Controller:joystickpressed(joystick, button)
  local key = "joy" .. joystick:getID() .. ":" .. button
  self:keypressed(key)
end

function Controller:joystickreleased(joystick, button)
  local key = "joy" .. joystick:getID() .. ":" .. button
  self:keyreleased(key)
end

function Controller:directionFromActions(actions)
    local direction = Direction(0,0)
    for control, _ in pairs(actions) do
      local ctlDir = directionsMap[control]
      if ctlDir then
        direction = direction:add(ctlDir)
      end
    end
    return direction
end

function Controller:notifyDirection(player)
  local direction = self:directionFromActions(self.actions[player])
  for _, listener in pairs(self:getListeners(player)) do
    if direction == Direction(0, 0) then
        local waningDirection = self:directionFromActions(self.waningActions[player])
        if listener.setDirection then
          listener:setDirection(waningDirection)
        end
    end
    listener:setDirection(direction)
  end
end

function Controller:register(listener, player)
  table.insert(self.listeners[player], listener)
end

function Controller:forwardAll(to)
  self.forward = to
end

function Controller:endForward(to)
  self.forward = nil
end

function Controller:getListeners(player)
  return table.filter(self.listeners[player], function(o, k, i)
    return o.active
  end)
end
