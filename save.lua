require 'utils'
local serialize = require "lib/Ser/ser"
class = require 'lib/30log/30log'
require 'star'

local SaveFile = "savegame.lua"
local SaveData = {}

function loadSaveData()
  local data = love.filesystem.load(SaveFile)
  if data then
    SaveData = data()
  else
    SaveData = {}
  end
end

Ship = class("Ship")

function Ship.allShips()
  local ships = {}
  for shipdata in values(SaveData) do
    table.insert(ships, Ship(shipdata))
  end
  table.sort(ships, function(a, b) return a.saved > b.saved end)
  return ships
end

function Ship.shipNames()
  local names = {}
  for name in keys(SaveData) do
    table.insert(names, name)
  end
  return names
end

function Ship.firstShip()
  return Ship.allShips()[1]
end

function Ship.nameIsValid(name)
  return SaveData[name] == nil
end

function Ship:init(data)
  self.name = data.name
  if data.roster then
    self.roster = map(data.roster, function(d)
      local p = Human(Point(), d)
      p.activePlayer = d.activePlayer
      return p
    end)
  end

  self.saved = coalesce(data.saved, os.time())
  if data.star then
    self.star = Star.deserialize(data.star)
  end
  if data.planet then
    self.planet = Planet.deserialize(data.planet)
  end
end

function Ship:activeRoster()
  local players = {}
  local rostered = false
  for i, player in ipairs(self.roster) do
    if player.activePlayer then
      players[player.activePlayer] = player
      rostered = true
    end
  end
  if not rostered then
    table.insert(players, self.roster[1])
  end
  return players
end

function Ship:activatePlayer(active, index)
  for i, player in ipairs(self.roster) do
    if player.name == active.name then
      player.activePlayer = index
    elseif player.activePlayer == index then
      player.activePlayer = nil
    end
  end
  self:save()
end

function Ship:deactivatePlayer(deact)
  print("deactivating", deact)
  for i, player in ipairs(self.roster) do
    if player.name == deact.name then
      print("deactivated player", player, player.activePlayer)
      player.activePlayer = nil
    end
  end
  self:save()
end

function Ship:serialize()
  print("serializing", self.name)
  local data = {
    name = self.name,
    roster = map(self.roster, function(p)
      local d = p:serialize()
      d.activePlayer = p.activePlayer
      if d.activePlayer then print(d.name, "is active at", d.activePlayer) end
      return d
    end),
    saved = self.saved,
  }
  if self.star then
    data.star = self.star:serialize()
  end
  if self.planet then
    data.planet = self.planet:serialize()
  end

  return data
end

function Ship:__str()
  return self.name
end

function Ship:save()
  SaveData[self.name] = self:serialize()
  love.filesystem.write(SaveFile, serialize(SaveData))
  print("saved", self.name)
end