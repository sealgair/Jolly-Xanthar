class = require 'lib/30log/30log'

Menu = class('Menu')

function Menu:init(opts)
  -- opts: itemGrid, initialItem, controlPlayer
  if opts == nil then opts = {} end
  self.fsm = opts.fsm
  self.itemGrid = coalesce(opts.itemGrid, {})
  self.initial = coalesce(opts.initialItem, Point(1, 1))
  self.navMaps = coalesce(opts.navMaps, {})
  self.selected = self.initial

  local p = coalesce(opts.controlPlayer, 1)
  if not opts.skipRegister then
    Controller:register(self, p)
  end
  self.selected = Point(self.initial)
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

    local map = self.navMaps[self:selectedItem()]
    if map then
      local sel = map[direction:key()]
      if sel then
        self.selected = sel
        return
      end
    end

    self.selected.y = wrapping(self.selected.y + direction.y, #self.itemGrid)
    local row = self.itemGrid[self.selected.y]
    if row then
      self.selected.x = wrapping(self.selected.x + direction.x, #row)
    end
    if self:selectedItem() == '' then
      self.direction = Direction()
      self:setDirection(direction)
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