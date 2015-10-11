
Controls = class('Controls')

local keyTime = 1
local controlTime = 1

function Controls:load(fsm)
  self.fsm = fsm
  self.image = love.graphics.newImage('assets/controls.png')
  ww, wh = 256, 240
  local sw, sh = self.image:getDimensions()
  self.screenQuad = love.graphics.newQuad(0, 0, ww, wh, sw, sh)

  self.items = {
    {'done', 'reset'},
    {'up', 'down', 'left', 'right'},
    {'select', 'start', 'a', 'b'},
  }
  function selectQuad(x, y, w, h)
    return love.graphics.newQuad(ww + x, y, w, h, sw, sh)
  end
  local cw = 56
  local ch = 74
  local pw = 34
  local ph = 46
  self.selectedQuads = {
    done =  selectQuad(0, 0, 64, 24),
    reset = selectQuad(160, 0, 80, 24),

    up =    selectQuad(16,  36, cw, ch),
    down =  selectQuad(73,  36, cw, ch),
    left =  selectQuad(129, 36, cw, ch),
    right = selectQuad(185, 36, cw, ch),

    select = selectQuad(16,  110, cw, ch),
    start =  selectQuad(73,  110, cw, ch),
    a =      selectQuad(129, 110, cw, ch),
    b =      selectQuad(185, 110, cw, ch),
  }
  self.playerQuads = {
    selectQuad(46,  182, pw, ph),
    selectQuad(88,  182, pw, ph),
    selectQuad(142, 182, pw, ph),
    selectQuad(188, 182, pw, ph),
  }

  self.selected = {x = 1, y = 1}
  self.direction = Direction(0, 0)
  self.selectedPlayer = 1

  Controller:register(self, 1)

  self.controlLocations = {
    up =    {x=21, y=59, w=46, h=46},
    down =  {x=77, y=59, w=46, h=46},
    left =  {x=133, y=59, w=46, h=46},
    right = {x=189, y=59, w=46, h=46},

    select = {x=21, y=129, w=46, h=46},
    start =  {x=77, y=129, w=46, h=46},
    a =      {x=133, y=129, w=46, h=46},
    b =      {x=189, y=129, w=46, h=46},
  }
  self.controlFont = love.graphics.newFont(7)
end

function Controls:selectedItem()
  return self.items[self.selected.y][self.selected.x]
end

function Controls:setDirection(direction)
  if self.direction ~= direction then
    self.direction = direction
    self.selected.y = wrapping(self.selected.y + direction.y, # self.items)
    local row = self.items[self.selected.y]
    self.selected.x = wrapping(self.selected.x + direction.x, # row)
  end
end

function Controls:controlStop(action)
  if action == 'select' then
    self.selectedPlayer = wrapping(self.selectedPlayer + 1, 4)
  elseif self:selectedItem() == 'done' then
    if action == 'a' or action == 'start' then
      Controller:saveControls()
      self.fsm:advance('done')
    end
  elseif self:selectedItem() == 'reset' then
    if action == 'a' or action == 'start' then
      Controller:resetControls()
    end
  elseif action == 'a' then
    Controller:forwardAll(self)
    self.setKeysFor = {
      player = self.selectedPlayer,
      action = self:selectedItem(),
      keys = {},
    }
  end
end

function Controls:keypressed(key)
  self.setKeysFor.keys[key] = keyTime
  self.setKeysFor.finalTimer = nil
end

function Controls:keyreleased(key)
  if self.setKeysFor.keys[key] > 0 then
    self.setKeysFor.keys[key] = nil
  end
  local n = 0
  for k, t in pairs(self.setKeysFor.keys) do
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
        Controller:endForward(self)
        Controller:updatePlayerAction(self.setKeysFor.player,
                                      self.setKeysFor.action,
                                      self.setKeysFor.keys)
        self.setKeysFor = nil
      end
    end
  end
end

function Controls:draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.image, self.screenQuad, 0, 0)
  local selectedItem = self:selectedItem()
  local selectedQuad = self.selectedQuads[selectedItem]
  local playerQuad = self.playerQuads[self.selectedPlayer]
  qx, qy, qw, qh = selectedQuad:getViewport()
  qx = qx - ww
  love.graphics.draw(self.image, selectedQuad, qx, qy)

  qx, qy, qw, qh = playerQuad:getViewport()
  qx = qx - ww
  love.graphics.draw(self.image, playerQuad, qx, qy)

  love.graphics.setFont(self.controlFont)
  for action, keyset in pairs(Controller.playerControls[self.selectedPlayer]) do
    local fontHeight = self.controlFont:getHeight()
    local loc = self.controlLocations[action]
    local ystart = loc.y + (loc.h - (fontHeight * keyCount(keyset)))/2
    for key, _ in pairs(keyset) do
      love.graphics.printf(key, loc.x, ystart, loc.w, "center")
      ystart = ystart + fontHeight
    end
  end

  if self.setKeysFor then
    local x, y, w, h = 85, 80, 85, 80
    local fontHeight = self.controlFont:getHeight()
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
      local ty =  y + h - th - 2
      local tw = w * (self.setKeysFor.finalTimer/controlTime)
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
        local tw = w * (time/keyTime)
        love.graphics.setColor(128, 0, 0)
        love.graphics.rectangle("fill", x, y, tw, th)
        love.graphics.setColor(255, 255, 255)
        love.graphics.rectangle("line", x, y, w, th)
      end
      y = y + 1
      love.graphics.setColor(255, 255, 255)
      love.graphics.printf(key, x, y, w, "center")
    end
  end
end
