class = require 'lib/30log/30log'
require 'utils'
require 'mobs.human'

Slot = class('Slot')

function Slot:init(rect)
  self.rect = rect
  self.lifeForm = Human(rect:origin() + Point(2,2))
  self.confirmImage = love.graphics.newImage('assets/confirm.png')

  local sw, sh = self.confirmImage:getWidth(), self.confirmImage:getHeight()
  local w, h = 16, 16
  self.yesQuads = {
      inactive = love.graphics.newQuad(0, 0, w, h, sw, sh),
      active   = love.graphics.newQuad(w, 0, w, h, sw, sh),
      chosen   = love.graphics.newQuad(w*2, 0, w, h, sw, sh),
  }
  self.noQuads = {
      inactive = love.graphics.newQuad(0, h, w, h, sw, sh),
      active   = love.graphics.newQuad(w, h, w, h, sw, sh),
      chosen   = love.graphics.newQuad(w*2, h, w, h, sw, sh),
  }
end

function Slot:draw()
  love.graphics.push()
  self.lifeForm:draw()

  love.graphics.setFont(Fonts[5])
  local pos = self.rect:origin() + Point(4, 22)
  local weapons = "A:"..self.lifeForm.weapons.a.name
  weapons = weapons.." B:"..self.lifeForm.weapons.b.name
  love.graphics.printf(weapons, pos.x, pos.y, self.rect.w, "left")

  local namePos = self.rect:origin() + Point(4, 36)
  love.graphics.printf(self.lifeForm.name, namePos.x, namePos.y, 126, "left")

  local yesPos = self.rect:origin() + Point(96, 0) + Point(-2, 2)
  love.graphics.draw(self.confirmImage, self.yesQuads.inactive, yesPos.x, yesPos.y)
  local noPos = yesPos + Point(16, 0)
  love.graphics.draw(self.confirmImage, self.noQuads.inactive, noPos.x, noPos.y)
  love.graphics.pop()
end

Recruit = {
}

function Recruit:load(fsm, remaining)
  self.fsm = fsm
  self.background = love.graphics.newImage('assets/Recruit.png')
  self.remaining = coalesce(remaining, 6)

  local sw, sh = 127, 46
  local sx1, sx2 = 0, 129
  self.slots = {
    {Slot(Rect(sx1,  49, sw, sh)), Slot(Rect(sx2,  49, sw, sh))},
    {Slot(Rect(sx1,  97, sw, sh)), Slot(Rect(sx2,  97, sw, sh))},
    {Slot(Rect(sx1, 145, sw, sh)), Slot(Rect(sx2, 145, sw, sh))},
    {Slot(Rect(sx1, 193, sw, sh)), Slot(Rect(sx2, 193, sw, sh))},
  }
end

function Recruit:setDirection(direction)
  if direction ~= self.controlDirection then
    self.controlDirection = direction
    self.activeItem = wrapping(self.activeItem + self.controlDirection.y, # self.items)
  end
end

function Recruit:draw()
  love.graphics.draw(self.background, 0, 0)

  for slotRow in values(self.slots) do
    for slot in values(slotRow) do
      slot:draw()
    end
  end
end