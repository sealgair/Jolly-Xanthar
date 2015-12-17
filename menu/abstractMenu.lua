class = require 'lib/30log/30log'

Menu = class('Menu')

function Menu:init(opts)
  -- opts: itemGrid, initialItem, controlPlayer
  self.fsm = opts.fsm
  self.itemGrid = coalesce(opts.itemGrid, {})
  self.initial = coalesce(opts.initialItem, {x=1, y=1})
  self.selected = self.initial

  local p = coalesce(opts.controlPlayer, 1)
  Controller:register(self, p)
  self.selected = self.initial
end

function Menu:update(dt)
end

function Menu:selectedItem()
  local row = self.itemGrid[self.selected.y]
  if row then
    return row[self.selected.x]
  end
end

function Menu:setDirection(direction)
  if self.direction ~= direction then
    self.direction = direction
    self.selected.y = wrapping(self.selected.y + direction.y, #self.itemGrid)
    local row = self.itemGrid[self.selected.y]
    if row then
      self.selected.x = wrapping(self.selected.x + direction.x, #row)
    end
  end
end

function Menu:controlStop(action)
  if action == 'a' or action == 'start' then
    self:chooseItem(self:selectedItem())
  end
end

function Menu:chooseItem(item)
end

function Menu:draw(fsm)
end