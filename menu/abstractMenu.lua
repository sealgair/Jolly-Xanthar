class = require 'lib/30log/30log'

Menu = class('Menu')

function Menu:init(itemGrid, initialItem)
  self.itemGrid = itemGrid
  self.initial = coalesce(initialItem, {x=1, y=1})
end

function Menu:load(fsm)
  self.fsm = fsm
  Controller:register(self, 1)
  self.selected = self.initial
end

function Menu:update(dt)
end

function Menu:setDirection(direction)
  if self.direction ~= direction then
    self.direction = direction
    self.selected.y = wrapping(self.selected.y + direction.y, #self.itemGrid)
    local row = self.itemGrid[self.selected.y]
    self.selected.x = wrapping(self.selected.x + direction.x, #row)
  end
end

function Menu:controlStop(action)
  if action == 'a' then
    local item = self.itemGrid[self.selected.y][self.selected.x]
    self:chooseItem(item)
  end
end

function Menu:chooseItem(item)
end

function Menu:draw(fsm)
end