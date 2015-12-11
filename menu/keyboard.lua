class = require 'lib/30log/30log'
require 'menu.abstractMenu'
require 'position'

Keyboard = Menu:extend('Keyboard')

local cursorDur = 0.5

function Keyboard:init(prompt)
  self.prompt = prompt
  self.text = "A Ship"
  self.maxLen = 18
  self.nextCursor = {
    ["Ø"] = "_",
    ["_"] = "Ø",
  }
  self.cursor = "_"
  self.cursorTime = cursorDur

  Keyboard.super.init(self, {
    { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m" },
    { "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" },
    { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M" },
    { "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" },
    { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" },
    { ".", ",", "!", "?", "-", "/", ":", ";", "%", "&", "`", "'", "#" },
    { "Space", "Delete", "Clear", "Done" },
  })
end

function Keyboard:controlStop(action)
  local actionMap = {
    Delete = 'b',
    Clear = 'select',
    Done = 'start',
  }
  if action == 'a' then
    local item = self.itemGrid[self.selected.y][self.selected.x]
    if actionMap[item] ~= nil then
      action = actionMap[item]
    elseif #self.text <= self.maxLen then
      if item == "Space" then item = " " end
      self.text = self.text .. item
    end
  end
  if action == 'b' then
    self.text = string.sub(self.text, 0, #self.text - 1)
  elseif action == 'select' then
    self.text = ""
  elseif action == 'start' then
    self.fsm:advance('done', self.text)
  end
end

function Keyboard:update(dt)
  self.cursorTime = self.cursorTime - dt
  if self.cursorTime <= 0 then
    self.cursor = self.nextCursor[self.cursor]
    self.cursorTime = cursorDur
  end
end

function Keyboard:draw()
  love.graphics.setFont(Fonts[16])

  love.graphics.setColor(0, 64, 255)
  love.graphics.printf(self.prompt, 0, 4, GameSize.w, "center")

  love.graphics.setLineWidth(2)
  love.graphics.line(8, 44, GameSize.w - 8, 45)

  local w = GameSize.w / 2
  local y = 68
  love.graphics.printf("A: type", 0, y, w, "center")
  love.graphics.printf("B: delete", w, y, w, "center")

  y = y + 18
  love.graphics.printf("Select: clear", 0, y, w, "center")
  love.graphics.printf("Start: done", w, y, w, "center")

  love.graphics.setColor(255, 255, 255)
  love.graphics.printf(self.text .. self.cursor, 0, 32, GameSize.w, "center")

  local x, y
  for r, row in ipairs(self.itemGrid) do
    y = 107 + 18 * (r - 1)
    for k, key in ipairs(row) do
      if #key == 1 then
        x = k * 18 - 8
      else
        x = k * 60 - 30
      end

      if Point(self.selected) == Point(k, r) then
        love.graphics.setColor(255, 0, 0)
      end
      love.graphics.printf(key, x, y, 18, "center")
      love.graphics.setColor(255, 255, 255)
    end
  end
end