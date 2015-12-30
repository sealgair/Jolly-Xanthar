require('utils')
require('menu.abstractMenu')

local keyTime = 1

KeyMenuItem = class('KeyMenuItem')

function KeyMenuItem:init(text, opts)
  opts = coalesce(opts, {})
  self.text = text
  self.font = coalesce(opts.font, Fonts.small)
  self.border = coalesce(opts.border, true)
  self.showInactive = opts.showInactive
  self.w = opts.width
end

function KeyMenuItem:draw(pos, selected, text)
  local color
  if selected then
    color = Colors.red
  else
    color = Colors.white
  end

  if text == nil then text = self.text end

  graphicsContext({font=self.font, color=color, lineWidth=1}, function()
    if self.fillPercent then
      local fill = Rect(pos, self:width() * self.fillPercent, self:height(0))
      fill:draw("fill")
      love.graphics.setColor(Colors.menuGray)
    end
    if self.border then
      local border = Rect(pos, self:width(), self:height(0))
      border:draw("line")
      pos = pos + Point(1, 1)
    end
    love.graphics.print(text, pos.x, pos.y)
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
  KeyMenu.super.init(self, {skipRegister = true})
  self.player = player
  self.action = action
  self:resetKeyset()

  local opts = {fonts=Fonts.medium}
  self.rightItems = {
    KeyMenuItem('Save', opts),
    KeyMenuItem('Cancel', opts),
    KeyMenuItem('Clear', opts),
  }
  self.newKeyItem = KeyMenuItem('Add New key', {width=64})
  self:buildMenu()
end

function KeyMenu:resetKeyset()
  local controls = Controller.playerControls[self.player]
  self.keyset = shallowCopy(controls[self.action])
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
  if item.key then
    self.keyset[item.text] = nil
  elseif item == self.newKeyItem then
    Controller:forwardAll(self)
    self.keyListener = {}
  elseif item.text == "Save" then
    if dictSize(self.keyset) > 0 or self.player ~= 1 then
      -- don't let player 1 set keys to nil: they need to work the menu!
      Controller.playerControls[self.player][self.action] = self.keyset
    end
    self.active = false
  elseif item.text == "Clear" then
    self.keyset = {}
  elseif item.text == "Cancel" then
    self:resetKeyset()
    self.active = false
  end
  self:buildMenu()
  if not self.active then
    self.selected = self.initial
  end
end


function KeyMenu:keypressed(key)
  if self.keyListener.key == nil then
    self.keyListener.key = key
    self.keyListener.time = keyTime
  end
end

function KeyMenu:keyreleased(key)
  if self.keyListener and self.keyListener.key == key then
    self.keyListener.key = nil
    self.keyListener.time = nil
  end
end

function KeyMenu:update(dt)
  if self.keyListener then
    if self.keyListener.time ~= nil then
      self.keyListener.time = self.keyListener.time - dt
      if self.keyListener.time <= 0 then
        self.keyset[self.keyListener.key] = true
        self:buildMenu()
        self.keyListener = nil
        Controller:endForward(self)
        return
      end
    end
    if self.keyListener.time then
      self.newKeyItem.fillPercent = 1 - (self.keyListener.time / keyTime)
    else
      self.newKeyItem.fillPercent = 0
    end
  else
    self.newKeyItem.fillPercent = nil
  end
end

function KeyMenu:draw(pos)
  local lpos = Point(pos)
  local rpos = lpos + Point(96, 0)

  for i, item in ipairs(self.leftItems) do
    if self.active or item.showInactive then
      local text
      if item == self.newKeyItem and self.keyListener then
        text = "hold a key"
        if self.keyListener.key then
          text = self.keyListener.key
        end
      end
      item:draw(lpos, Point(1, i) == Point(self.selected), text)
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

  self.helpText = {
    Done = "Save all changed mappings and exit",
    ["Set All"] = "Edit keys for each button in turn",
    Reset = "Reset all keys to factory defaults",
  }

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
    elseif selectedItem == 'Set All' then
      self.selected = self.itemCoords.up
      self:setKeyMenu()
      self.keyMenu.active = true
      self.nextSelected = {
        self.itemCoords.down,
        self.itemCoords.left,
        self.itemCoords.right,
        self.itemCoords.select,
        self.itemCoords.start,
        self.itemCoords.b,
        self.itemCoords.a,
      }
    end
  end
end

function Controls:update(dt)
  if self.keyMenu then
    self.keyMenu:update(dt)
    if self.nextSelected and self.keyMenu.active == false then
      self.selected = table.remove(self.nextSelected, 1)
      self:setKeyMenu()
      self.keyMenu.active = true
      if #self.nextSelected <= 0 then
        self.nextSelected = nil
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
  else
    local help = self.helpText[self:selectedItem()]
    local pos = Point(20, 33)
    if help then
      graphicsContext({ color = Colors.menuBlue , font=Fonts.medium}, function()
        love.graphics.print(help, pos.x, pos.y)
      end)
    end
  end
end
