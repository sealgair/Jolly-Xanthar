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
    self:setKeyList()
  end
end

function Controls:currentKeyset()
  local selectedItem = self:selectedItem()
  local controls = Controller.playerControls[self.selectedPlayer]
  return controls[selectedItem]
end

function Controls:setKeyList()
  local keyset = self:currentKeyset()
  if keyset == nil then
    self.keyList = nil
  else
    self.keyList = {}
    for key in keys(keyset) do
      table.insert(self.keyList, key)
    end
  end
end

function Controls:keyMenu()
  if self.keyList ~= nil then
    local menu = {}
    for key in values(self.keyList) do
      table.insert(menu, key)
    end
    for item in values(self.keyMenuExtras) do
      table.insert(menu, item)
    end
    return menu
  else
    return nil
  end
end

function Controls:controlStop(action)
  local selectedItem = self:selectedItem()
  if self:currentKeyset() then
    if self.selectedKey == nil then
      if action == 'a' or action == 'start' then
        self.selectedKey = 1
      end
    else
      if action == 'start' or action == 'a' then
        if self.selectedKey <= #self.keyList then
          table.remove(self.keyList, self.selectedKey)
        else
          local keyAction = self:keyMenu()[self.selectedKey]
          if keyAction == "New key" then
            Controller:forwardAll(self)
            self.selectedKey = #self.keyList + 1  -- off the edge
            self.keyListener = {}
          elseif keyAction == "Save" then
            if #self.keyList > 0 or self.selectedPlayer ~= 1 then
              -- don't let player 1 set keys to nil: they need to work the menu!
              Controller.playerControls[self.selectedPlayer][selectedItem] = valuesSet(self.keyList)
            end
            self:setKeyList()
            self.selectedKey = nil
          elseif keyAction == "Clear" then
            self.keyList = {}
          elseif keyAction == "Cancel" then
            self:setKeyList()
            self.selectedKey = nil
          end
        end
      end
    end
  else
    print('got here')
    if selectedItem == 'Done' then
      Controller:saveControls()
      self.fsm:advance('done')
    elseif selectedItem == 'Reset' then
      Controller:resetControls()
      self:setKeyList()
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

  local controls = Controller.playerControls[self.selectedPlayer]
  local keyset = controls[selectedItem]
  if keyset then
    local pos = Point(30, 135)
    love.graphics.setFont(Fonts.medium)
    local itemName = coalesce(self.renames[selectedItem], selectedItem:upper())
    graphicsContext({ color = Colors.menuBlue }, function()
      love.graphics.print("Edit keys for ["..itemName.."] button", pos.x, pos.y)
    end)
    pos = pos + Point(0, Fonts.medium:getHeight() + 3)

    local lineHeight = Fonts.small:getHeight() + 2
    love.graphics.setFont(Fonts.small)
    if self.keyList ~= nil then
      local items = self.keyList
      if self.selectedKey ~= nil then
        items = self:keyMenu()
      end
      for k, key in ipairs(items) do
        if self.selectedKey == k then
          love.graphics.setColor(Colors.red)
        else
          love.graphics.setColor(Colors.white)
        end
        if k <= #self.keyList then
          if k == self.selectedKey then
            love.graphics.printf("X", pos.x-16, pos.y, 16, "right")
          end
          graphicsContext({color=Colors.white}, function()
            love.graphics.print(key, pos.x, pos.y)
          end)
        else
          local w = 64
          local rect = Rect(pos, w, lineHeight)
          if key == "New key" then
            if self.keyListener then
              if self.keyListener.time ~= nil then
                love.graphics.setColor(Colors.menuRed)
                rect.w = rect.w * (1 - (self.keyListener.time / keyTime))
                rect:draw("fill")
                rect.w = w

                love.graphics.setColor(Colors.white)
                love.graphics.print(self.keyListener.key, rect.x + 1, rect.y + 1)
              else
                love.graphics.setColor(Colors.menuGray)
                love.graphics.print("hold a key", rect.x + 1, rect.y + 1)
              end
              love.graphics.setColor(Colors.red)
            else
              if self.selectedKey == #self.keyList + 1 then
                love.graphics.setColor(Colors.red)
              else
                love.graphics.setColor(Colors.white)
              end
              love.graphics.print(key, rect.x + 1, rect.y + 1)
            end
            pos = pos + Point(0, 2)
          else
            pos = pos + Point(1, 1)
            love.graphics.print(key, pos.x, pos.y)
            pos = pos + Point(-1, 1)
          end
          rect:draw("line")
        end

        pos = pos + Point(0, lineHeight)
      end
    end
  end
end
