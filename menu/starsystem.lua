require 'menu.abstractMenu'
require 'star'

StarSystem = Menu:extend("StarSystem")

function StarSystem:init(fsm, opts)
  StarSystem.super.init(self, {
    fsm = fsm,
    itemGrid = {
      {'exit', 'planets'},
      {'galaxy', 'planets'},
    },
  })
  self.fsmOpts = opts
  self.ship = coalesce(self.fsmOpts.ship, Save:shipNames()[1])
  self.shipStar = Save:shipStar(self.ship)
  self.planets = self.shipStar:planets()
  table.sort(self.planets, function(a, b)
    return a.dist < b.dist
  end)
  self.background = love.graphics.newImage('assets/starsystem.png')

  local sw, sh = self.background:getDimensions()
  self.menuQuads = {
    exit = love.graphics.newQuad(0, 0, 14, 14, sw, sh),
    galaxy = love.graphics.newQuad(0, 16, 14, 15, sw, sh),
  }
  self.screenRect = Rect(0, 0, Size(GameSize)):inset(16)

  self:drawScreenCanvas()
end

function StarSystem:changeMenuItem(direction)
  if self:selectedItem() ~= 'planets' then
    StarSystem.super.changeMenuItem(self, direction)
  end

  if self:selectedItem() == 'planets' and direction ~= Direction() then
    if self.selectedPlanet == nil then
      if direction == Direction.up or direction == Direction.left then
        self.selectedPlanet = #self.planets
      else
        self.selectedPlanet = 0
      end
    else
      if direction == Direction.up or direction == Direction.left then
        self.selectedPlanet = self.selectedPlanet + 1
      else
        self.selectedPlanet = self.selectedPlanet - 1
      end
      if self.selectedPlanet < 1 or self.selectedPlanet > #self.planets then
        self.selectedPlanet = nil
      end
    end
    self:drawScreenCanvas()
  end

  if self:selectedItem() == 'planets' and self.selectedPlanet == nil then
    StarSystem.super.changeMenuItem(self, direction)
  end
end

function StarSystem:drawScreenCanvas()
  local r = Rect(Point(), self.screenRect:size())
  self.screenCanvas = love.graphics.newCanvas(self.screenRect.w, self.screenRect.h)
  graphicsContext({canvas=self.screenCanvas, origin=true, color=Colors.white, lineWidth=0.5}, function()
    self.shipStar:drawClose(r:center(), 9)
    local maxDist = self.planets[#self.planets].dist
    local sc = r:center()

    for p, planet in ipairs(self.planets) do
      if p == self.selectedPlanet then
        love.graphics.setColor({255, 0, 0})
      else
        love.graphics.setColor({255, 255, 255, 128})
      end
      local radius = (planet.dist / maxDist) * ((r.h / 2) - 15) + 12
      love.graphics.circle("line", sc.x, sc.y, radius, 50)
    end

    for p, planet in ipairs(self.planets) do
      local radius = (planet.dist / maxDist) * ((r.h / 2) - 15) + 12
      local pc = sc + (Point(math.cos(planet.rot), math.sin(planet.rot)) * radius)
      if p == self.selectedPlanet then
        love.graphics.setColor({255, 0, 0, 200})
        love.graphics.circle("fill", pc.x, pc.y, planet.drawRadius +2, 20)
      end
      planet:draw(pc)
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