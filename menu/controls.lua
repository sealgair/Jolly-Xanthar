require('utils')

Controls = class('Controls')

local keyTime = 1
local controlTime = 1

function Controls:init(fsm)
  self.fsm = fsm
  self.image = love.graphics.newImage('assets/controls.png')
  local ww, wh = GameSize.w, GameSize.h
  local sw, sh = self.image:getDimensions()
  self.screenQuad = love.graphics.newQuad(0, 0, ww, wh, sw, sh)

  self.items = {
    { 'Done', 'Set All', 'Reset' },
    { 'up' },
    { 'left', 'right', 'select', 'start', 'b', 'a' },
    { 'down' },
  }
  self.itemCoords = {}
  for y, row in ipairs(self.items) do
    for x, item in ipairs(row) do
      self.itemCoords[item] = Point(x, y)
    end
  end
  self.itemRemap = {
    Reset = {
      down = self.itemCoords.b,
    },
    ['Set All'] = {
      down = self.itemCoords.select,
    },
    up = {
      left = self.itemCoords.left,
      right = self.itemCoords.right,
    },
    down = {
      left = self.itemCoords.left,
      right = self.itemCoords.right,
    },
    select = {
      up = self.itemCoords['Set All'],
      down = self.itemCoords['Set All'],
    },
    start = {
      up = self.itemCoords['Set All'],
      down = self.itemCoords['Set All'],
    },
    a = {
      up = self.itemCoords.Reset,
      down = self.itemCoords.Reset,
    },
    b = {
      up = self.itemCoords.Reset,
      down = self.itemCoords.Reset,
    },
  }
  self.renames = {
    up = "↑",
    down = "↓",
    left = "←",
    right = "→",
  }

  local function selectQuad(x, y, w, h)
    return love.graphics.newQuad(ww + x, y, w, h, sw, sh)
  end

  self.selectedQuads = {
    up =    selectQuad(56, 64, 16, 16),
    down =  selectQuad(56, 96, 16, 16),
    left =  selectQuad(40, 80, 16, 16),
    right = selectQuad(72, 80, 16, 16),

    select = selectQuad(104, 80, 32, 15),
    start =  selectQuad(137, 80, 32, 15),

    b = selectQuad(182, 79, 18, 18),
    a = selectQuad(200, 79, 18, 18),
  }

  self.selected = { x = 1, y = 1 }
  self.direction = Direction(0, 0)
  self.selectedPlayer = 1

  Controller:register(self, 1)

  self.controlLocations = {
    up =    { x = 2,   y = 59, w = 60, h = 46 },
    down =  { x = 68,  y = 59, w = 60, h = 46 },
    left =  { x = 130, y = 59, w = 60, h = 46 },
    right = { x = 194, y = 59, w = 60, h = 46 },
    select = { x = 2,  y = 129, w = 60, h = 46 },
    start =  { x = 68, y = 129, w = 60, h = 46 },
    b =      { x = 130, y = 129, w = 60, h = 46 },
    a =      { x = 194, y = 129, w = 60, h = 46 },
  }
  self.controlFont = Fonts.small
  self.setterFont = Fonts.medium
end

function Controls:activate()
  self.selectedPlayer = 1
end

function Controls:selectedItem()
  return self.items[self.selected.y][self.selected.x]
end

function Controls:setDirection(direction)
  if self.direction == direction then return end
  self.direction = direction
  if self.direction == Direction() then return end

  local selected = self:selectedItem()
  local dirstr = tostring(direction)
  local remap = self.itemRemap[selected]
  if remap then
    local newSelected = remap[dirstr]
    if newSelected then
      self.selected.x = newSelected.x
      self.selected.y = newSelected.y
      return
    end
  end

  self.selected.y = wrapping(self.selected.y + direction.y, #self.items)
  local row = self.items[self.selected.y]
  self.selected.x = wrapping(self.selected.x + direction.x, #row)
end

function Controls:controlStop(action)
  if action == 'a' or action == 'start' then
    if self:selectedItem() == 'done' then
      Controller:saveControls()
      self.fsm:advance('done')
    elseif self:selectedItem() == 'reset' then
      Controller:resetControls()
      self.selectedPlayer = 1
    else
      Controller:forwardAll(self)
      self.setKeysFor = {
        player = self.selectedPlayer,
        action = self:selectedItem(),
        keys = {},
      }
      if self:selectedItem() == 'setAll' then
        self.setKeysFor.action = 'up'
        self.setKeysFor.nextAction = { 'down', 'left', 'right', 'select', 'start', 'b', 'a' }
      end
    end
  elseif action == 'select' then
    self.selectedPlayer = wrapping(self.selectedPlayer + 1, 4)
  end
end

function Controls:keypressed(key)
  self.setKeysFor.keys[key] = keyTime
  self.setKeysFor.finalTimer = nil
end

function Controls:keyreleased(key)
  if self.setKeysFor.keys[key] and self.setKeysFor.keys[key] > 0 then
    self.setKeysFor.keys[key] = nil
  end
  local n = 0
  for t in values(self.setKeysFor.keys) do
    if t <= 0 then
      n = n + 1
    end
  end
  if n > 0 then
    self.setKeysFor.finalTimer = controlTime
  end
end

function Controls:update(dt)
  if self.setKeysFor then
    for key, time in pairs(self.setKeysFor.keys) do
      self.setKeysFor.keys[key] = time - dt
    end

    if self.setKeysFor.finalTimer then
      self.setKeysFor.finalTimer = self.setKeysFor.finalTimer - dt
      if self.setKeysFor.finalTimer < 0 then
        Controller:updatePlayerAction(self.setKeysFor.player,
          self.setKeysFor.action,
          self.setKeysFor.keys)
        if self.setKeysFor.nextAction and #self.setKeysFor.nextAction > 0 then
          self.setKeysFor.action = table.remove(self.setKeysFor.nextAction, 1)
          self.setKeysFor.keys = {}
          self.setKeysFor.finalTimer = nil
        else
          Controller:endForward(self)
          self.setKeysFor = nil
        end
      end
    end
  end
end

function Controls:draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.image, self.screenQuad, 0, 0)
  local selectedItem = self:selectedItem()

  love.graphics.setFont(Fonts.large)
  local p = Point(15, 15)
  for i, item in ipairs(self.items[1]) do
    if item == selectedItem then
      love.graphics.setColor(255, 0, 0)
    end
    love.graphics.print(item, p.x, p.y)
    p = p + Point(Fonts.large:getWidth(item) + 25, 0)
    love.graphics.setColor(255, 255, 255)
  end

  love.graphics.setColor(255, 255, 255)
  local selectedQuad = self.selectedQuads[selectedItem]
  if selectedQuad then
    local qx, qy, qw, qh = selectedQuad:getViewport()
    qx = qx - GameSize.w
    love.graphics.draw(self.image, selectedQuad, qx, qy)
  end

  local controls = Controller.playerControls[self.selectedPlayer]
  local keyset = controls[selectedItem]
  if keyset then
    local pos = Point(30, 135)
    love.graphics.setFont(Fonts.large)
    local itemName = coalesce(self.renames[selectedItem], selectedItem:upper())
    love.graphics.print("["..itemName.."]", pos.x, pos.y)
    pos = pos + Point(0, Fonts.large:getHeight() + 3)

    local lineHeight = Fonts.small:getHeight() + 2
    love.graphics.setFont(Fonts.small)
    for key, _ in pairs(keyset) do
      love.graphics.print(key, pos.x, pos.y)
      pos = pos + Point(0, lineHeight)
    end
  end

  if self.setKeysFor then
    love.graphics.push()
    love.graphics.setFont(self.setterFont)

    local x, y, w, h = 85, 80, 85, 80
    local fontHeight = love.graphics.getFont():getHeight()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(128, 0, 0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setColor(255, 0, 0)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.printf(self.setKeysFor.action:upper(), x, y + 5, w, "center")

    x = x + 2
    w = w - 4

    local th = fontHeight + 2
    if self.setKeysFor.finalTimer then
      local ty = y + h - th - 2
      local tw = w * (self.setKeysFor.finalTimer / controlTime)
      love.graphics.setColor(128, 0, 0)
      love.graphics.rectangle("fill", x, ty, tw, th)
      love.graphics.setColor(255, 255, 255)
      love.graphics.rectangle("line", x, ty, w, th)
      ty = ty + 1
      love.graphics.printf("Finalizing...", x, ty, w, "center")
    end

    y = y + 5
    for key, time in pairs(self.setKeysFor.keys) do
      y = y + fontHeight + 2
      if time > 0 then
        local tw = w * (time / keyTime)
        love.graphics.setColor(128, 0, 0)
        love.graphics.rectangle("fill", x, y, tw, th)
        love.graphics.setColor(255, 255, 255)
        love.graphics.rectangle("line", x, y, w, th)
      end
      y = y + 1
      love.graphics.setColor(255, 255, 255)
      love.graphics.printf(key, x, y, w, "center")
    end
    love.graphics.pop()
  end
end
