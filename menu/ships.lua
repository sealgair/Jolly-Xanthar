require 'menu.abstractMenu'
require 'utils'
require 'position'
require 'mobs.human'

Ships = Menu:extend('Ships')

function Ships:init()
  Ships.super.init(self, {})
  self:loadSaved()
end

function Ships:loadSaved()
  self.itemGrid = {} map(Save:ships(), function(s) return {s} end)
  for ship in values(Save:ships()) do
    ship = shallowCopy(ship)
    ship.roster = map(reverseCopy(ship.roster), function(p)
      return Human(Point(0,0), p)
    end)
    table.insert(self.itemGrid, {ship})
  end
end

function Ships:chooseItem(item)
  self.fsm:advance("done", item.name)
end

function Ships:draw()
  local y = 0
  local h = 48
  local w = GameSize.w-2

  love.graphics.setLineWidth(2)
  for r, row in ipairs(self.itemGrid) do
    local ship = row[1]

    if r == self.selected.y then
      love.graphics.setColor(63, 0, 0)
      love.graphics.rectangle("fill", 2, y+2, w-2, h-2)
      love.graphics.setColor(255, 255, 255)
    end

    love.graphics.rectangle("line", 1, y+1, w, h)
    love.graphics.setFont(Fonts[16])
    love.graphics.print(ship.name, 4, y + 4)
    love.graphics.setFont(Fonts[10])
    love.graphics.print(os.date("%y.%m.%d[%H.%M.%S]", ship.saved), 4, y + 4 + 18)

    local pos = Point(w, y + 4)
    for player in values(ship.roster) do
      pos = pos - Point(player.w + 2, 0)
      player.position = pos
      player:draw()
    end

    y = y + h
  end
end