require 'menu.abstractMenu'
require 'utils'
require 'position'
require 'mobs.human'

ShipMenu = Menu:extend('ShipMenu')

function ShipMenu:init(fsm)
  ShipMenu.super.init(self, {fsm=fsm})
  self:loadSaved()
  self.canvas = love.graphics.newCanvas()
  self.offset = 0
  self.newOffset = self.offset
end

function ShipMenu:loadSaved()
  self.itemGrid = {} map(Save:ships(), function(s) return {s} end)
  for ship in values(Save:ships()) do
    ship = shallowCopy(ship)
    ship.roster = map(reverseCopy(ship.roster), function(p)
      return Human(Point(0,0), p)
    end)
    table.insert(self.itemGrid, {ship})
  end
end

function ShipMenu:chooseItem(item)
  self.fsm:advance("done", item.name)
end

function ShipMenu:update(dt)
  local move = 150 * dt
  if self.offset > self.newOffset then
    self.offset = math.max(
      self.offset - move,
      self.newOffset
    )
  elseif self.offset < self.newOffset then
    self.offset = math.min(
      self.offset + move,
      self.newOffset
    )
  end
end

function ShipMenu:draw()
  local y = 0
  local h = 48
  local w = GameSize.w-2

  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.push()
  love.graphics.origin()

  local centerY = 0
  local maxY = 0

  love.graphics.setLineWidth(2)
  for r, row in ipairs(self.itemGrid) do
    local ship = row[1]

    if r == self.selected.y then
      graphicsContext({color = {63, 0, 0}},
      function()
        love.graphics.rectangle("fill", 2, y+2, w-2, h-2)
      end)
      centerY = y + h/2
    end

    maxY = math.max(maxY, y + 1 + h)
    love.graphics.rectangle("line", 1, y+1, w, h)
    love.graphics.setFont(Fonts.large)
    love.graphics.print(ship.name, 4, y + 4)
    love.graphics.setFont(Fonts.medium)
    love.graphics.print(os.date("%y.%m.%d[%H.%M.%S]", ship.saved), 4, y + 4 + 18)

    local yoff = 18
    local xoff = yoff
    local pos = Point(w - xoff/2, y + 4)
    for player in values(ship.roster) do
      pos = pos + Point(-xoff/2, yoff)
      yoff = yoff * -1
      player.position = pos
      player:draw()
    end

    y = y + h
  end

  love.graphics.pop()
  love.graphics.setCanvas()
  local offset = centerY - GameSize.h / 2
  offset = math.min(offset, maxY - GameSize.h)
  offset = math.max(1, offset)
  offset = -offset
  if offset ~= self.newOffset then
    self.newOffset = offset
  end
  love.graphics.draw(self.canvas, 0, self.offset)
end