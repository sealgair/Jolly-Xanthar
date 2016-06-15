require 'menu.abstractMenu'
require 'star'

StarSystem = Menu:extend("StarSystem")

function StarSystem:init(fsm, opts)
  self.fsmOpts = opts

  if self.fsmOpts and self.fsmOpts.ship then
    self.ship = self.fsmOpts.ship
  else
    self.ship = Ship.firstShip()
  end
  self.planets = self.ship.star:planets()
  self.selectedPlanet = 0
  for p, planet in ipairs(self.planets) do
    if planet == self.shipPlanet then
      self.selectedPlanet = p
    end
  end
  self.background = love.graphics.newImage('assets/starsystem.png')

  self.screenRect = Rect(0, 0, Size(GameSize)):inset(16)
  self.windowCanvas = love.graphics.newCanvas(self.screenRect:size():parts())

  StarSystem.super.init(self, {
    fsm = fsm,
    itemGrid = {
      {'back', 'planets'},
      {'galaxy', 'planets'},
    },
  })

  local sw, sh = self.background:getDimensions()
  self.menuQuads = {
    back = love.graphics.newQuad(0, 0, 14, 14, sw, sh),
    galaxy = love.graphics.newQuad(0, 16, 14, 15, sw, sh),
  }

  self:drawScreenCanvas()
  self.canvasAnimOffset = self.canvasOffset
end

function StarSystem:changeMenuItem(direction)
  if self:selectedItem() == 'planets' then
    if direction == Direction.up then
      self.selected = Point(1, 1)
    elseif direction == Direction.down then
      self.selected = Point(1, 2)
    else
      local next = self.selectedPlanet + direction.x
      if next < 1 or next > #self.planets then
        StarSystem.super.changeMenuItem(self, direction)
      else
        self.selectedPlanet = next
      end
    end
  else
    StarSystem.super.changeMenuItem(self, direction)
  end
  self:drawScreenCanvas()
end

function StarSystem:chooseItem(item)
  if item == 'planets' then
    self.ship.planet = self.planets[self.selectedPlanet]
    self.ship:save()
    self.selected.x = 1
    self:drawScreenCanvas()
  else
    self.fsm:advance(item, self.fsmOpts)
  end
end

function StarSystem:drawScreenCanvas()
  self.canvasOffset = Point()
  self.screenCanvas = love.graphics.newCanvas()
  graphicsContext({canvas=self.screenCanvas, origin=true, color=Colors.white, lineWidth=0.5}, function()
    local p = Point(-32, 32)
    self.ship.star:drawClose(p, 64)
    p = p + Point(64, 0)
    local planetPos = 0
    local selPlanetPos = 0
    for pi, planet in ipairs(self.planets) do
      p = p + Point(planet.drawRadius * 1.5, 0)

      if planet == self.ship.planet then
        selPlanetPos = p.x
        local radius = planet.drawRadius + 4.5
        love.graphics.setColor(Colors.blue)
        love.graphics.circle("fill", p.x, p.y, radius, 20)
      end

      if pi == self.selectedPlanet then
        if self:selectedItem() == 'planets' then
          love.graphics.setColor(Colors.red)
          love.graphics.circle("fill", p.x, p.y, planet.drawRadius + 2.5, 20)
        end
        planetPos = p.x
      end

      planet:draw(p)
      p = p + Point(planet.drawRadius * 1.5, 0)
    end
    if planetPos == 0 then planetPos = selPlanetPos end
    local centerX = self.screenRect.w / 2
    if planetPos > centerX then
      self.canvasOffset = Point(planetPos - centerX, 0)
    end
  end)
end

function StarSystem:update(dt)
  self.canvasAnimOffset = animateOffset(self.canvasAnimOffset, self.canvasOffset, dt * 200)
end

function StarSystem:draw()
  graphicsContext({canvas = self.windowCanvas, origin = true}, function()
    love.graphics.clear()
    love.graphics.translate((-self.canvasAnimOffset):parts())
    love.graphics.draw(self.screenCanvas)
  end)
  love.graphics.draw(self.windowCanvas, self.screenRect:origin():parts())

  love.graphics.draw(self.background)
  local sel = self:selectedItem()
  local quad = self.menuQuads[sel]
  if quad then
    graphicsContext({color = Colors.red}, function()
      local x, y, w, h = quad:getViewport( )
      love.graphics.draw(self.background, quad, x, y)
    end)
  end

  graphicsContext({color = {0, 128, 0}, font = Fonts.small}, function()
    local details
    if self.ship.planet then
      details = self.ship.planet:name()
    else
      details = self.ship.star:name()
    end
    love.graphics.print(details, self.screenRect.x + 2, self.screenRect:bottom() + 2)
  end)
end