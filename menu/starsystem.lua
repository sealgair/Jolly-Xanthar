require 'menu.abstractMenu'
require 'star'

StarSystem = Menu:extend("StarSystem")

function StarSystem:init(fsm, opts)
  self.fsmOpts = opts
  self.ship = coalesce(self.fsmOpts.ship, Save:shipNames()[1])
  self.shipStar = Save:shipStar(self.ship)
  self.shipPlanet = Save:shipPlanet(self.ship)
  self.planets = self.shipStar:planets()
  self.background = love.graphics.newImage('assets/starsystem.png')

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
  self.screenRect = Rect(0, 0, Size(GameSize)):inset(16)

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
  local r = Rect(Point(), self.screenRect:size())
  self.screenCanvas = love.graphics.newCanvas(self.screenRect.w, self.screenRect.h)
  graphicsContext({canvas=self.screenCanvas, origin=true, color=Colors.white, lineWidth=0.5}, function()
    local p = Point(-32, 32)
    self.shipStar:drawClose(p, 64)
    p = p + Point(64, 0)
    for planet in values(self.planets) do
      p = p + Point(planet.drawRadius * 1.5, 0)

      if planet == self.shipPlanet then
        print("draw selected planet", planet.index)
        love.graphics.setColor(Colors.blue)
        love.graphics.circle("fill", p.x, p.y, planet.drawRadius + 4.5, 20)
      end

      if planet == self:selectedItem() then
        love.graphics.setColor(Colors.red)
        love.graphics.circle("fill", p.x, p.y, planet.drawRadius + 2.5, 20)
      end

      planet:draw(p)
      p = p + Point(planet.drawRadius * 1.5, 0)
    end
  end)
end

function StarSystem:draw()
  love.graphics.draw(self.screenCanvas, self.screenRect.x, self.screenRect.y)

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