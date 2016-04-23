require 'menu.abstractMenu'
require 'star'

StarSystem = Menu:extend("StarSystem")

function StarSystem:init(fsm, opts)
  self.fsmOpts = opts
  self.ship = coalesce(self.fsmOpts.ship, Save:shipNames()[1])
  self.shipStar = Save:shipStar(self.ship)
  self.planets = self.shipStar:planets()
  table.sort(self.planets, function(a, b)
    return a.dist < b.dist
  end)
  self.background = love.graphics.newImage('assets/starsystem.png')

  StarSystem.super.init(self, {
    fsm = fsm,
    itemGrid = {
      table.iconcat({'exit'}, self.planets),
      table.iconcat({'galaxy'}, self.planets),
    },
  })

  local sw, sh = self.background:getDimensions()
  self.menuQuads = {
    exit = love.graphics.newQuad(0, 0, 14, 14, sw, sh),
    galaxy = love.graphics.newQuad(0, 16, 14, 15, sw, sh),
  }
  self.screenRect = Rect(0, 0, Size(GameSize)):inset(16)

  self:drawScreenCanvas()
end

function StarSystem:changeMenuItem(direction)
  StarSystem.super.changeMenuItem(self, direction)
  self:drawScreenCanvas()
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
      if planet == self:selectedItem() then
        love.graphics.setColor({255, 0, 0, 200})
        love.graphics.circle("fill", p.x, p.y, planet.drawRadius + 2, 20)
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
end