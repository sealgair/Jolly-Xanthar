require "direction"
defaultControls = require "defaultControls"
local serialize = require "lib/Ser/ser"

Controller = {
  listeners = {},
  actions = {},
  axisTracker = {},
}

local gamepadPrefix = "gp"

local buttonSymbols = {
  a = "A",
  b = "B",
  x = "X",
  y = "Y",
  back = "Back",
  guide = "Home",
  start = "Start",
  dpup = "Up",
  dpdown = "Down",
  dpleft = "Left",
  dpright = "Right",
  leftstick = "LS-Click",
  rightstick = "RS-Click",
  leftshoulder = "L",
  rightshoulder = "R",
}

local axisSymbols = {
  leftx = "LSX",
  lefty = "LSY",
  rightx = "RSX",
  righty = "RSY",
  triggerleft = "L-Trig",
  triggerright = "R-Trig",
}

local extraMappings = {
  ["NES PC Game Pad"] = {
    axes = {
      axisSymbols.leftx,
      axisSymbols.lefty,
      axisSymbols.lefty,
      axisSymbols.lefty,
      axisSymbols.lefty,
    },
    buttons = {
      buttonSymbols.a,
      buttonSymbols.b,
      buttonSymbols.back,
      buttonSymbols.start,
    }
  },
  ["USB Gamepad"] = {
    axes = {
      '',
      '',
      '',
      axisSymbols.leftx,
      axisSymbols.lefty,
    },
    buttons = {
      '',
      buttonSymbols.b,
      buttonSymbols.a,
      '',
      '',
      '',
      '',
      '',
      buttonSymbols.back,
      buttonSymbols.start,
    }
  }
}

function gamepadButton(joystick, button)
  local jsName = joystick:getName()
  if extraMappings[jsName] then
    local result = extraMappings[jsName].buttons[button]
    return result
  elseif joystick:isGamepad() then
    for key, symbol in pairs(buttonSymbols) do
      local inputtype, inputindex, hatdirection = joystick:getGamepadMapping(key)
      if inputindex == button then
        return symbol
      end
    end
  end
  return button
end

function gamepadAxis(joystick, axis)
  local jsName = joystick:getName()
  if extraMappings[jsName] then
    local result = extraMappings[jsName].axes[axis]
    return result
  elseif joystick:isGamepad() then
    for key, symbol in pairs(axisSymbols) do
      local inputtype, inputindex, hatdirection = joystick:getGamepadMapping(key)
      if inputindex == axis then
        return symbol
      end
    end
  end
  return "ax" .. axis
end

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
  local weakmeta = {
    __mode = "k"
  }
  self.listeners = {}
  setmetatable(self.listeners, weakmeta)
  for player, controls in pairs(self.playerControls) do
    self.actions[player] = {}
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
  local actions = {}
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
  local key = gamepadPrefix .. joystick:getID() .. ":" .. button
  return self:actionsForKey(key)
end

function Controller:update(dt)
  if self.delayedDirection then
    self.delayedDirection.timer = self.delayedDirection.timer - dt
    if self.delayedDirection.timer <= 0 then
      for listener in values(self:getListeners(self.delayedDirection.player)) do
        listener:setDirection(self.delayedDirection.dir)
      end
      self.delayedDirection = nil
    end
  end
end

function Controller:startActions(playerActions)
  for player, actions in pairs(playerActions) do
    for action in values(actions) do
      self.actions[player][action] = 1

      if directionsMap[action] then
        self:notifyDirection(player)
      else
        for listener in values(self:getListeners(player)) do
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
    for action in values(actions) do
      self.actions[player][action] = nil
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
  if button == nil then return end
  button = gamepadButton(joystick, button)
  local key = gamepadPrefix .. joystick:getID() .. ":" .. button
  self:keypressed(key)
end

function Controller:joystickreleased(joystick, button)
  if button == nil then return end
  button = gamepadButton(joystick, button)
  local key = gamepadPrefix .. joystick:getID() .. ":" .. button
  self:keyreleased(key)
end

function Controller:joystickaxis(joystick, axis, value)
  if axis == nil then return end

  axis = gamepadAxis(joystick, axis)
  local key = gamepadPrefix .. joystick:getID() .. ":" .. axis

  local oldDir = self.axisTracker[key]
  if string.find(axis, "[LR]-Trig") then
    local newDir
    if value > -0.9 then
      newDir = 1
    else
      newDir = nil
    end
    self.axisTracker[key] = newDir

    if newDir ~= oldDir then
      if newDir == nil then
        self:keyreleased(key)
      else
        self:keypressed(key)
      end
    end
  else
    local deadZone = 0.25
    local newDir = value
    if newDir > deadZone then
      newDir = "+"
    elseif newDir < -deadZone then
      newDir = "-"
    else
      newDir = nil
    end
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
end

function Controller:directionFromActions(actions)
  local direction = Direction(0, 0)
  for control in pairs(actions) do
    local ctlDir = directionsMap[control]
    if ctlDir then
      direction = direction:add(ctlDir)
    end
  end
  return direction
end

function Controller:notifyDirection(player)
  local direction = self:directionFromActions(self.actions[player])
  if direction ~= self.prevDirection then
    if self.prevDirection and self.prevDirection:isDiagonal() and not direction:isDiagonal() then
      self.delayedDirection = {
        player = player,
        dir = direction,
        timer = 0.05
      }
    else
      self.delayedDirection = nil
      for listener in values(self:getListeners(player)) do
        listener:setDirection(direction)
      end
    end
    self.prevDirection = direction
  end
end

function Controller:register(listener, player)
  table.insert(self.listeners[player], listener)
end

function Controller:unregister(listener, player)
  table.removeValue(self.listeners[player], listener)
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
