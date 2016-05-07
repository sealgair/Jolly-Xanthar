require 'menu.abstractMenu'
require 'star'

StarSystem = Menu:extend("StarSystem")

function StarSystem:init(fsm, opts)
  self.fsmOpts = opts

  if self.fsmOpts and self.fsmOpts.ship then
    self.ship = self.fsmOpts.ship
  else
    self.ship = Save:shipNames()[1]
  end
  self.shipStar = Save:shipStar(self.ship)
  self.shipPlanet = Save:shipPlanet(self.ship)
  self.planets = self.shipStar:planets()
  self.background = love.graphics.newImage('assets/starsystem.png')

  self.screenRect = Rect(0, 0, Size(GameSize)):inset(16)
  self.windowCanvas = love.graphics.newCanvas(self.screenRect:size():parts())

  StarSystem.super.init(self, {
    fsm = fsm,
    itemGrid = {
      table.iconcat({'back'}, self.planets),
      table.iconcat({'galaxy'}, self.planets),
    },
  })

  local sw, sh = self.background:getDimensions()
  self.menuQuads = {
    back = love.graphics.newQuad(0, 0, 14, 14, sw, sh),
    galaxy = love.graphics.newQuad(0, 16, 14, 15, sw, sh),
  }

  self:drawScreenCanvas()
end

function StarSystem:changeMenuItem(direction)
  StarSystem.super.changeMenuItem(self, direction)
  self:drawScreenCanvas()
end

function StarSystem:chooseItem(item)
  if class.isInstance(item, Planet) then
    self.shipPlanet = item
    Save:saveShip(self.ship, nil, nil, self.shipPlanet)
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
    self.shipStar:drawClose(p, 64)
    p = p + Point(64, 0)
    local planetPos = 0
    local selPlanetPos = 0
    for planet in values(self.planets) do
      p = p + Point(planet.drawRadius * 1.5, 0)

      if planet == self.shipPlanet then
        selPlanetPos = p.x
        local radius = planet.drawRadius + 4.5
        love.graphics.setColor(Colors.blue)
        love.graphics.circle("fill", p.x, p.y, radius, 20)
      end

      if planet == self:selectedItem() then
        love.graphics.setColor(Colors.red)
        love.graphics.circle("fill", p.x, p.y, planet.drawRadius + 2.5, 20)
        planetPos = p.x
      end

      planet:draw(p)
      p = p + Point(planet.drawRadius * 1.5, 0)
    end
    if planetPos == 0 then planetPos = selPlanetPos end
    local centerX = self.screenRect.w / 2
    if planetPos > centerX then
      self.canvasOffset = Point(planetPos - centerX, 0)
      print("offset", planetPos, centerX, self.canvasOffset)
    end
  end)
end

function StarSystem:draw()
  graphicsContext({canvas = self.windowCanvas, origin = true}, function()
    love.graphics.clear()
    love.graphics.translate((-self.canvasOffset):parts())
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
    if self.shipPlanet then
      details = self.shipPlanet:name()
    else
      details = self.shipStar:name()
    end
    love.graphics.print(details, self.screenRect.x + 2, self.screenRect:bottom() + 2)
  end)
end