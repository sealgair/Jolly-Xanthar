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

  if self.selectedKey ~= nil then
    local keyset = self:currentKeyset()
    self.selectedKey = wrapping(self.selectedKey + direction.y, dictSize(keyset))
    print('new selected key', self.selectedKey)
    return
  end

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

function Controls:currentKeyset()
  local selectedItem = self:selectedItem()
  local controls = Controller.playerControls[self.selectedPlayer]
  return controls[selectedItem]
end

function Controls:controlStop(action)
  local keyset = self:currentKeyset()
  if keyset then
    if self.selectedKey == nil then
      if action == 'a' or action == 'start' then
        self.selectedKey = 1
      end
    else
      if action == 'start' then
        self.selectedKey = nil
      end
    end
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
    if self.selectedKey ~= nil then
      graphicsContext({font=Fonts.medium, color=Colors.menuRed}, function()
        local keys = "[B]\n[A]\n[SELECT]\n[START]"
        local actions = "delete key\nadd key\nclear keys\nsave keys"
        local x, y, w = 115, 133, 64
        love.graphics.printf(keys, x, y, w, "right")
        love.graphics.setColor(Colors.menuBlue)
        love.graphics.print(actions, x + w + 3, y)
      end)
    end
    local pos = Point(30, 135)
    love.graphics.setFont(Fonts.large)
    local itemName = coalesce(self.renames[selectedItem], selectedItem:upper())
    love.graphics.print("["..itemName.."]", pos.x, pos.y)
    pos = pos + Point(0, Fonts.large:getHeight() + 3)

    local lineHeight = Fonts.small:getHeight() + 2
    love.graphics.setFont(Fonts.small)
    local k = 1
    for key, _ in pairs(keyset) do
      local color = Colors.white
      if k == self.selectedKey then
        color = Colors.red
      end
      graphicsContext({color=color}, function()
        love.graphics.print(key, pos.x, pos.y)
      end)
      pos = pos + Point(0, lineHeight)
      k = k + 1
    end
  end
end
