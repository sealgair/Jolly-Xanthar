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
  self.lifeForm = Human(self.rect:origin() + Point(2, 2))
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
  love.graphics.setFont(Fonts[10])
  local pos = self.rect:origin() + Point(22, 6)
  love.graphics.printf(self.lifeForm.name, pos.x, pos.y, 126, "left")

  pos = self.rect:origin() + Point(4, 22)
  local weapona = "A: " .. self.lifeForm.weapons.a.name
  love.graphics.printf(weapona, pos.x, pos.y, self.rect.w, "left")

  pos = pos + Point(0, 11)
  local weaponb = "B: " .. self.lifeForm.weapons.b.name
  love.graphics.printf(weaponb, pos.x, pos.y, self.rect.w, "left")

  love.graphics.pop()
end

Recruit = {
  recruitCount = 0
}

function Recruit:load(fsm, total)
  self.fsm = fsm
  Controller:register(self, 1)
  self.background = love.graphics.newImage('assets/Recruit.png')
  self.total = coalesce(total, 6)

  local sw, sh = 127, 47
  local sx1, sx2 = 0, 129

  self.slots = {}
  for y = 49, GameSize.h, 48 do
    table.insert(self.slots,
      { Slot(Rect(sx1, y, sw, sh)), Slot(Rect(sx2, y, sw, sh)) })
  end
  self.activeID = Point(1, 1)

  self.rotateSpeed = DefaultAnimateInterval
  self.rotate = self.rotateSpeed
end

function Recruit:activate(ship)
  self.ship = ship
end

function Recruit:setDirection(direction)
  if self:done() then return end
  if direction ~= self.controlDirection then
    self.controlDirection = direction
    self.activeID.y = wrapping(self.activeID.y + self.controlDirection.y, #self.slots)
    self.activeID.x = wrapping(self.activeID.x + self.controlDirection.x, #self.slots[self.activeID.y])
  end
end

function Recruit:controlStop(action)
  if self:done() then
    if action == 'a' then
      self:save()
      return
    elseif action ~= 'b' then
      return
    end
  end

  local slot = self.slots[self.activeID.y][self.activeID.x]
  if action == 'a' and self.recruitCount < self.total then
    slot.recruited = true
    local lf = slot.lifeForm
    lf:setDirection(Direction.down)
  end
  if action == 'b' then
    if slot.recruited then
      slot.recruited = false
    else
      slot:newLifeForm()
    end
  end
end

function Recruit:done()
  return self.recruitCount >= self.total
end

function Recruit:save()
  local roster = {}
  for slotRow in values(self.slots) do
    for slot in values(slotRow) do
      if slot.recruited then
        table.insert(roster, slot.lifeForm:serialize())
      end
    end
  end
  Save:saveShip(self.ship, roster)
  self.fsm:advance('done', self.ship)
end

function Recruit:update(dt)
  if self.rotate <= 0 then
    self.rotate = self.rotateSpeed

    self.recruitCount = 0
    for slotRow in values(self.slots) do
      for slot in values(slotRow) do
        if not slot.recruited then
          local lf = slot.lifeForm
          lf:setDirection(lf:facingDirection():turnRight())
        else
          self.recruitCount = self.recruitCount + 1
        end
      end
    end
  else
    self.rotate = self.rotate - dt
  end
end

function Recruit:draw()
  love.graphics.draw(self.background, 0, 0)

  local r = 0
  for y, slotRow in ipairs(self.slots) do
    for x, slot in ipairs(slotRow) do
      local active = self.activeID == Point(x, y)
      slot:draw(active)
    end
  end

  love.graphics.setFont(Fonts[16])
  love.graphics.printf(self.ship .. ": " ..self.recruitCount .. "/" .. self.total, 0, 6, 256, "center")

  if self:done() then
    love.graphics.setColor(0, 0, 0)
    local w = GameSize.w / 3
    local h = GameSize.h / 3
    love.graphics.rectangle("fill", w, h, w, h)
    love.graphics.setColor(255, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", w, h, w, h)
    love.graphics.setColor(255, 255, 255)

    love.graphics.setFont(Fonts[10])
    love.graphics.printf("A: Accept\nB: Cancel", w, h + h / 2 - 14, w, "center")
  end
end