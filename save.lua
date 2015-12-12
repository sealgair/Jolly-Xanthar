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
  self.data[shipName] = {
    name = shipName,
    roster = roster,
    saved = os.time(),
  }
  love.filesystem.write(self.filename, serialize(self.data))
end

function Save:shipRoster(shipName)
  return self.data[shipName].roster
end

function Save:ships()
  local ships = {}
  for ship in values(self.data) do
    table.insert(ships, ship)
  end
  table.sort(ships, function(a, b) return a.saved > b.saved end)
  return ships
end

function Save:shipNames()
  local names = map(self:ships(), function(v) return v.name end)
  return names
end