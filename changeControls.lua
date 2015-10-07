
ChangeControls = class('ChangeControls')

function ChangeControls:load(fsm)
  self.fsm = fsm
  self.image = love.graphics.newImage('assets/controls.png')
  ww, wh = 256, 240
  local sw, sh = self.image:getDimensions()
  self.screenQuad = love.graphics.newQuad(0, 0, ww, wh, sw, sh)

  self.items = {
    {'done'},
    {'up', 'down', 'left', 'right'},
    {'select', 'start', 'a', 'b'},
    {'p1', 'p2', 'p3', 'p4'},
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

    p1 =     selectQuad(46,  182, pw, ph),
    p2 =     selectQuad(88,  182, pw, ph),
    p3 =     selectQuad(142, 182, pw, ph),
    p4 =     selectQuad(188, 182, pw, ph),
  }

  self.selected = {x = 1, y = 1}
  self.direction = Direction(0, 0)

  PlayerController:register(self)
end

function ChangeControls:selectedItem()
  return self.items[self.selected.y][self.selected.x]
end

function ChangeControls:setDirection(direction)
  if self.direction ~= direction then
    self.direction = direction
    self.selected.y = wrapping(self.selected.y + direction.y, # self.items)
    local row = self.items[self.selected.y]
    self.selected.x = wrapping(self.selected.x + direction.x, # row)
  end
end

function ChangeControls:controlStop(action)
  if action == 'attack' or action == 'pause' then
    if self:selectedItem() == 'done' then
      self.fsm:advance('done')
    end
  end
end

function ChangeControls:draw()
  love.graphics.draw(self.image, self.screenQuad, 0, 0)
  local selectedItem = self:selectedItem()
  local selectedQuad = self.selectedQuads[selectedItem]
  qx, qy, qw, qh = selectedQuad:getViewport()
  qx = qx - ww
  love.graphics.draw(self.image, selectedQuad, qx, qy)
end
