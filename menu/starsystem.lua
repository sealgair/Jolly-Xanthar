require 'menu.abstractMenu'
require 'star'

StarSystem = Menu:extend("StarSystem")

function StarSystem:init(fsm, opts)
  StarSystem.super.init(self, {
    fsm = fsm,
    itemGrid = {
      {'exit', 'telescope'},
      {'galaxy', 'telescope'},
    },
  })
  self.fsmOpts = opts
  self.ship = coalesce(self.fsmOpts.ship, Save:shipNames()[1])
  self.shipStar = Save:shipStar(self.ship)
  self.background = love.graphics.newImage('assets/starsystem.png')
  self.screenRect = Rect(0, 0, Size(GameSize)):inset(16)

  self:drawScreenCanvas()
end

function StarSystem:drawScreenCanvas()
  local r = Rect(Point(), self.screenRect:size())
  self.screenCanvas = love.graphics.newCanvas(self.screenRect.w, self.screenRect.h)
  graphicsContext({canvas=self.screenCanvas, origin=true, color=Colors.white, lineWidth=0.5}, function()
    self.shipStar:drawClose(r:center(), 10)
    local maxDist = list_max(map(self.shipStar:planets(), function(p) return p.dist end))
    local sc = r:center()
    for planet in values(self.shipStar:planets()) do
      love.graphics.setColor({255, 255, 255, 128})
      local radius = (planet.dist / maxDist) * ((r.h / 2) - 15) + 12
      love.graphics.circle("line", sc.x, sc.y, radius, 50)
      local pc = sc + (Point(math.cos(planet.rot), math.sin(planet.rot)) * radius)

      love.graphics.setColor({255, 255, 0})
      love.graphics.circle("fill", pc.x, pc.y, math.log10(planet.radius) * 3 + 2, 10)
    end
  end)
end

function StarSystem:draw()
  love.graphics.draw(self.background)
  love.graphics.draw(self.screenCanvas, self.screenRect.x, self.screenRect.y)
end