require 'utils'
local serialize = require "lib/Ser/ser"

Save = {
  filename = "savegame.lua",
}

function Save:load()
  local data = love.filesystem.load(self.filename)
  if data then
    self.data = data()
  else
    self.data = {}
  end
end

function Save:saveShip(shipName, roster)
  self.data[shipName] = roster
  love.filesystem.write(self.filename, serialize(self.data))
end

function Save:loadShip(shipName)
  return self.data[shipName]
end

function Save:shipNames()
  local names = {}
  for name in keys(self.data) do
    table.insert(names, name)
  end
  return names
end