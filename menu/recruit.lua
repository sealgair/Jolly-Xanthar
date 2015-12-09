class = require 'lib/30log/30log'
require 'utils'
require 'mobs.human'

Slot = class('Slot')

function Slot:init(rect)
  self.rect = rect
  self:newLifeForm()
  self.recruited = false
end

function Slot:newLifeForm()
  love.graphics.push()
  love.graphics.origin()
  self.lifeForm = Human(self.rect:origin() + Point(2,2))
  love.graphics.pop()
end

function Slot:draw(active)
  love.graphics.push()

  if self.recruited then
    local r = self.rect
    love.graphics.setColor(0, 63, 0)
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h)
    love.graphics.setColor(255, 255, 255)
  end

  if active then
    local r = self.rect:inset(2)
    love.graphics.setColor(127, 0, 0)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", r.x, r.y, r.w, r.h)
    love.graphics.setColor(255, 255, 255)
  end

  self.lifeForm:draw()
  love.graphics.setFont(Fonts[5])
  local pos = self.rect:origin() + Point(4, 22)
  local weapons = "A:"..self.lifeForm.weapons.a.name
  weapons = weapons.." B:"..self.lifeForm.weapons.b.name
  love.graphics.printf(weapons, pos.x, pos.y, self.rect.w, "left")

  local namePos = self.rect:origin() + Point(4, 36)
  love.graphics.printf(self.lifeForm.name, namePos.x, namePos.y, 126, "left")

  love.graphics.pop()
end

Recruit = {
}

function Recruit:load(fsm, remaining)
  self.fsm = fsm
  Controller:register(self, 1)
  self.background = love.graphics.newImage('assets/Recruit.png')
  self.remaining = coalesce(remaining, 6)

  local sw, sh = 127, 47
  local sx1, sx2 = 0, 129

  self.slots = {}

  for y = 49, GameSize.h, 48 do
    table.insert(self.slots,
      {Slot(Rect(sx1,  y, sw, sh)), Slot(Rect(sx2,  y, sw, sh))}
    )
  end
  self.activeID = Point(1, 1)
end

function Recruit:setDirection(direction)
  if direction ~= self.controlDirection then
    self.controlDirection = direction
    self.activeID.y = wrapping(self.activeID.y + self.controlDirection.y, # self.slots)
    self.activeID.x = wrapping(self.activeID.x + self.controlDirection.x, # self.slots[self.activeID.y])
  end
end

function Recruit:controlStop(action)
  local item = self.slots[self.activeID.y][self.activeID.x]
  if action == 'a'then
    item.recruited = true
  end
  if action == 'b'then
    if item.recruited then
      item.recruited = false
    else
      item:newLifeForm()
    end
  end
end

function Recruit:update(dt)
end

function Recruit:draw()
  love.graphics.draw(self.background, 0, 0)

  for y, slotRow in ipairs(self.slots) do
    for x, slot in ipairs(slotRow) do
      local active = self.activeID == Point(x, y)
--      print("slot", Point(x, y), self.activeID, active)
      slot:draw(active)
    end
  end
end