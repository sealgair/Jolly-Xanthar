PlayerController = {
  listeners = {}
}

function PlayerController:load()
  local controlData = love.filesystem.load('controls.lua')
  print(controlData)
  self.controls = controlData()
end

function PlayerController:keypressed(key)
  action = self.controls[key]
  if action then
    for key, listener in pairs(self.listeners) do
      listener:controlStart(action)
    end
  end
end

function PlayerController:keyreleased(key)
  action = self.controls[key]
  if action then
    for key, listener in pairs(self.listeners) do
      listener:controlStop(action)
    end
  end
end

function PlayerController:register(listener)
  table.insert(self.listeners, listener)
end
