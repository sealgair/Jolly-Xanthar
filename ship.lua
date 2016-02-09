require 'world'

Ship = World:extend('Ship')

function rotateCopy(tbl)
  local rot = {}
  for r, row in ipairs(tbl) do
    for t, tile in ipairs(row) do
      if rot[t] == nil then
        table.insert(rot, t, {})
      end
      local col = rot[t]
      table.insert(col, tile)
    end
  end
  return rot
end

function mirrorCopy(tbl)
  local mirror = {}
  for r, row in ipairs(tbl) do
    table.insert(mirror, reverseCopy(row))
  end
  return mirror
end

function Ship:init(fsm, ship)
  self.shipFile = "myship.world"
  local data = self:loadModule("assets/worlds/barracks.world", Direction.right)
  self:writeShip(data)
  Ship.super.init(self, fsm, ship, self.shipFile, "assets/worlds/ship.png", 0)
end

function Ship:loadModule(module, dir)
  local data = {}
  for line in love.filesystem.lines(module) do
    local row = {}
    for tile in line:gmatch"." do table.insert(row, tile) end
    table.insert(data, row)
  end

  if dir == Direction.down then
    data = reverseCopy(data)
  elseif dir == Direction.left then
    data = rotateCopy(data)
  elseif dir == Direction.right then
    data = rotateCopy(data)
    data = mirrorCopy(data)
  end

  return data
end

function Ship:writeShip(data)
  local text = ""
  for r, row in ipairs(data) do
    for t, tile in ipairs(row) do
      text = text .. tile
    end
    text = text .. "\n"
  end
  love.filesystem.write(self.shipFile, text)
end