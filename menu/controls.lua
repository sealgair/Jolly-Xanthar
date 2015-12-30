require('utils')
require('menu.abstractMenu')

KeyMenuItem = class('KeyMenuItem')

function KeyMenuItem:init(text, opts)
  opts = coalesce(opts, {})
  self.text = text
  self.font = coalesce(opts.font, Fonts.small)
  self.border = coalesce(opts.border, true)
  self.showInactive = opts.showInactive
  self.w = opts.width
end

function KeyMenuItem:draw(pos, selected)
  local color
  if selected then
    color = Colors.red
  else
    color = Colors.white
  end

  graphicsContext({font=self.font, color=color, lineWidth=1}, function()
    if self.border then
      local border = Rect(pos, self:width(), self:height(0))
      border:draw("line")
      pos = pos + Point(1, 1)
    end
    love.graphics.print(self.text, pos.x, pos.y)
  end)
end

function KeyMenuItem:width()
  if self.w then return self.w end
  local w = self.font:getWidth(self.text)
  if self.border then w = w + 2 end
  return w
end

function KeyMenuItem:height(padding)
  if padding == nil then padding = 2 end
  local h = self.font:getHeight() + padding
  if self.border then h = h + 2 end
  return h
end

KeyMenuKey = KeyMenuItem:extend('KeyMenuKey')

function KeyMenuKey:init(text, opts)
  opts = coalesce(opts, {})
  opts.showInactive = true
  opts.border = false
  KeyMenuKey.super.init(self, text, opts)
  self.key = true
end

function KeyMenuKey:draw(pos, selected)
  KeyMenuKey.super.draw(self, pos)
  if selected then
    graphicsContext({color=Colors.red, font=self.font}, function()
      love.graphics.printf("X", pos.x - 16, pos.y, 16, "right")
    end)
  end
end

EmptyMenuItem = KeyMenuItem:extend('EmptyMenuKey')

function EmptyMenuItem:init()
  EmptyMenuItem.super.init(self, '', {border=false})
  self.selectable = false
end

KeyMenu = Menu:extend('KeyMenu')

function KeyMenu:init(player, action)
  KeyMenu.super.init(self)
  self.player = player
  self.action = action
  local controls = Controller.playerControls[player]
  self.keyset = controls[action]
  self.originalKeyset = self.keyset

  local opts = {fonts=Fonts.medium}
  self.rightItems = {
    KeyMenuItem('Save', opts),
    KeyMenuItem('Cancel', opts),
    KeyMenuItem('Clear', opts),
  }
  self.newKeyItem = KeyMenuItem('New key', {width=64})
  self:buildMenu()
end

function KeyMenu:buildMenu()
  self.leftItems = {
    self.newKeyItem
  }
  for key in keys(self.keyset) do
    local item = KeyMenuKey(key)
    table.insert(self.leftItems, item)
  end
  self.itemColumns = {self.leftItems, self.rightItems}
end

function KeyMenu:setDirection(direction)
  if self.direction ~= direction then
    self.direction = direction

    self.selected.y = wrapping(self.selected.y + direction.y, #self.itemColumns[self.selected.x])
    self.selected.x = wrapping(self.selected.x + direction.x, 2)
    if self.selected.x == 1 then
      self.selected.y = wrapping(self.selected.y, #self.leftItems)
    else
      self.selected.y = wrapping(self.selected.y, #self.rightItems)
    end
  end
end

function KeyMenu:selectedItem(action)
  return self.itemColumns[self.selected.x][self.selected.y]
end

function KeyMenu:chooseItem(item)
  print('chose', item.text, item.key)
  if item.key then
    self.keyset[item.text] = nil
    self:buildMenu()
  elseif item.text == "New key" then
    Controller:forwardAll(self)
    self.keyListener = {}
  elseif item.text == "Save" then
    self.originalKeyset = self.keyset
    if dictSize(self.keyset) > 0 or self.player ~= 1 then
      -- don't let player 1 set keys to nil: they need to work the menu!
      Controller.playerControls[self.player][self.action] = self.keySet
    end
    self.active = false
  elseif item.text == "Clear" then
    self.keyset = {}
    self:buildMenu()
  elseif item.text == "Cancel" then
    self.keyset = self.originalKeyset
    self:buildMenu()
    self.active = false
  end
end

function KeyMenu:draw(pos)
  local lpos = Point(pos)
  local rpos = lpos + Point(96, 0)

  for i, item in ipairs(self.leftItems) do
    if self.active or item.showInactive then
      item:draw(lpos, Point(1, i) == Point(self.selected))
    end
    lpos = lpos + Point(0, item:height())
  end
  if self.active then
    for i, item in ipairs(self.rightItems) do
      item:draw(rpos, Point(2, i) == Point(self.selected))
      rpos = rpos + Point(0, item:height())
    end
  end
end

Controls = class('Controls')

local keyTime = 1

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

  self.keyMenuExtras = {
    "New key",
    "Save",
    "Clear",
    "Cancel",
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
  if self.keyMenu and self.keyMenu.active then
    self.keyMenu:setDirection(direction)
    return
  end

  if self.direction == direction then return end
  self.direction = direction
  if self.direction == Direction() then return end

  if self.selectedKey ~= nil then
    self.selectedKey = wrapping(self.selectedKey + direction.y, #self:keyMenu())
  else
    local selected = self:selectedItem()
    local dirstr = tostring(direction)
    local remap = self.itemRemap[selected]
    if remap and remap[dirstr] then
      local newSelected = remap[dirstr]
      self.selected.x = newSelected.x
      self.selected.y = newSelected.y
    else
      self.selected.y = wrapping(self.selected.y + direction.y, #self.items)
      local row = self.items[self.selected.y]
      self.selected.x = wrapping(self.selected.x + direction.x, #row)
    end
    self:setKeyMenu()
  end
end

function Controls:currentKeyset()
  local selectedItem = self:selectedItem()
  local controls = Controller.playerControls[self.selectedPlayer]
  return controls[selectedItem]
end

function Controls:setKeyMenu()
  local selectedItem = self:selectedItem()
  if self:currentKeyset() then
    self.keyMenu = KeyMenu(self.selectedPlayer, self:selectedItem())
  else
    self.keyMenu = nil
  end
end

function Controls:controlStop(action)
  local selectedItem = self:selectedItem()
  if self.keyMenu then
    if self.keyMenu.active then
      self.keyMenu:controlStop(action)
    else
      if action == 'a' or action == 'start' then
        self.keyMenu.active = true
      end
    end
  else
    if selectedItem == 'Done' then
      Controller:saveControls()
      self.fsm:advance('done')
    elseif selectedItem == 'Reset' then
      Controller:resetControls()
      self.selectedPlayer = 1
    end
  end
end

function Controls:keypressed(key)
  if self.keyListener.key == nil then
    self.keyListener.key = key
    self.keyListener.time = keyTime
  end
end

function Controls:keyreleased(key)
  if self.keyListener and self.keyListener.key == key then
    self.keyListener.key = nil
    self.keyListener.time = nil
  end
end

function Controls:update(dt)
  if self.keyListener then
    if self.keyListener.time ~= nil then
      self.keyListener.time = self.keyListener.time - dt
      if self.keyListener.time <= 0 then
        table.insert(self.keyList, self.keyListener.key)
        self.keyListener = nil
        Controller:endForward(self)
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

  if self.keyMenu then
    local pos = Point(30, 135)
    love.graphics.setFont(Fonts.medium)
    local itemName = coalesce(self.renames[selectedItem], selectedItem:upper())
    graphicsContext({ color = Colors.menuBlue }, function()
      love.graphics.print("Edit keys for ["..itemName.."] button", pos.x, pos.y)
    end)
    pos = pos + Point(0, Fonts.medium:getHeight() + 3)
    self.keyMenu:draw(pos)
  end
end
