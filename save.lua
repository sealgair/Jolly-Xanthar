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

function Save:serializeStar(star)
  return {
    pos = {x = star.pos.x, y = star.pos.y, z = star.pos.z},
    seed = star.seed
  }
end

function Save:deserializeStar(starData)
  return Star(Point(starData.pos), starData.seed)
end

function Save:saveShip(shipName, roster, star)
  if star then star = self:serializeStar(star) end
  local oldData = self.data[shipName]
  if oldData then
    roster = coalesce(roster, oldData.roster)
    star = coalesce(star, oldData.star)
  end
  self.data[shipName] = {
    name = shipName,
    roster = roster,
    saved = os.time(),
    star = star,
  }
  love.filesystem.write(self.filename, serialize(self.data))
end

function Save:shipRoster(shipName)
  return self.data[shipName].roster
end

function Save:shipStar(shipName)
  local sd = self.data[shipName].star
  if sd then
    return Save:deserializeStar(sd)
  end
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

function Save:nameIsValid(shipName)
  local nameSet = invert(self:shipNames())
  return nameSet[shipName] == nil
end