
Controls = class('Controls')

function Controls:load(fsm)
  self.fsm = fsm
  self.image = love.graphics.newImage('assets/controls.png')
  ww, wh = 256, 240
  local sw, sh = self.image:getDimensions()
  self.screenQuad = love.graphics.newQuad(0, 0, ww, wh, sw, sh)

  self.items = {
    {'done'},
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
    done =   selectQuad(0, 0, 64, 24),

    up =     selectQuad(16,  36, cw, ch),
    down =   selectQuad(73,  36, cw, ch),
    left =   selectQuad(129, 36, cw, ch),
    right =  selectQuad(185, 36, cw, ch),

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

  Controller:register(self)

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
  if self:selectedItem() == 'done' then
    if action == 'a' or action == 'start' then
      Controller:saveControls()
      self.fsm:advance('done')
    end
  elseif action == 'a' then
    Controller:forwardAll(self)
    self.setKeyFor = {
      player = self.selectedPlayer,
      action = self:selectedItem(),
    }
  end
end

function Controls:keypressed(key)
  self.setKeyFor.key = key
end

function Controls:keyreleased(key)
  Controller:endForward(self)
  Controller:updatePlayerAction(self.setKeyFor.player,
                                self.setKeyFor.action,
                                self.setKeyFor.key)
  self.setKeyFor = nil
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
    local loc = self.controlLocations[action]
    local ystart = loc.y
    for key, _ in pairs(keyset) do
      love.graphics.printf(key, loc.x, ystart, loc.w, "center")
      ystart = ystart + self.controlFont:getHeight()
    end
  end

  if self.setKeyFor then
    local x, y, w, h = 85, 80, 85, 80
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(128, 0, 0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setColor(255, 0, 0)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.printf(self.setKeyFor.action:upper(),
                         x, y + 5, w, "center")
    if self.setKeyFor.key then
      love.graphics.setColor(255, 255, 255)
      love.graphics.printf(self.setKeyFor.key,
                           x, y + (h/2), w, "center")
    end
  end
end
