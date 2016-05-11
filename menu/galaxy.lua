class = require 'lib/30log/30log'
require 'menu.abstractMenu'
require 'position'
require 'camera'
require 'utils'
require 'star'

local SectorSize = 50

function safeAlpha(a)
  return math.max(math.min(a, 255), 0)
end

Sector = class("Sector")

function Sector:init(pos, density, seed)
  self.box = Rect(pos, Size(SectorSize, SectorSize, SectorSize))
  self.seed = coalesce(seed, os.time()) .. tostring(pos:round(5))
  local starCount = self.box:area() * density
  local variance = .25

  randomSeed(self.seed)
  local starFactor = math.random() * .25 + (1 - variance/2)
  starCount = round(starFactor * starCount)
  self.stars = {}
  for i=1,starCount do
    local star = Star(Point(
      self.box.x + math.random() * self.box.w,
      self.box.y + math.random() * self.box.h,
      self.box.z + math.random() * self.box.d
    ), self.seed)
    table.insert(self.stars, star)
  end
end

Galaxy = Menu:extend("Galaxy")

function Galaxy:init(fsm, opts)
  Galaxy.super.init(self, {
    fsm = fsm,
    itemGrid = {
      {'back', 'telescope'},
      {'near', 'telescope'},
      {'size', 'telescope'},
      {'bright', 'telescope'},
      {'metal', 'telescope'},
      {'galaxy', 'telescope'},
    },
    initialItem = Point(1, 2)
  })
  self.itemDescriptions = {
    back = "Exit NavCom",
    near = "Nearest Stars",
    metal = "Most Metallic Stars",
    size = "Biggest Stars",
    bright = "Hottest Stars",
    galaxy = "Galactic Features",
    telescope = "Navigate",
  }

  self.starFilters = {
    near = function(star) return star:squaredDistance(self.camera.position) end,
    size = function(star) return -star.mass end,
    bright = function(star) return -star.luminosity end,
    metal = function(star) return -star.metalicity end,
    galaxy = function(star) return -star:squaredDistance(self.camera.position) end,
  }
  self.currentFilterKey = "near"
  self.currentFilterLimit = 1000

  self.seed = 1000
  self.sector = Sector(Point(0,0,0), 0.14, self.seed)

  self.fsmOpts = opts
  if self.fsmOpts and self.fsmOpts.ship then
    self.ship = self.fsmOpts.ship
  else
    self.ship = Save:shipNames()[1]
  end
  self.shipStar = Save:shipStar(self.ship)
  self.shipPlanet = Save:shipPlanet(self.ship)

  if self.shipStar then
    self.shipPos = self.shipStar.pos
  else
    self.shipPos = self.sector.box:center()
  end
  self.starShader = love.graphics.newShader("shaders/stars.glsl")
  self.camera = Camera(self.shipPos, Orientations.front, Size(GameSize))
  self.galaxyRect = Rect(0, 0, Size(GameSize)):inset(16)
  self.rotationDir = Point(0, 0, 0)
  self:filterStars()

  self.background = love.graphics.newImage('assets/galaxy.png')
  local sw, sh = self.background:getDimensions()
  self.menuQuads = {}
  local w, h = 14, 14
  for r, row in ipairs(self.itemGrid) do
    local item = row[1]
    local x = 0
    local y = (r - 1) * 16
    self.menuQuads[item] = love.graphics.newQuad(x, y, w, h, sw, sh)
  end
end

function Galaxy:allStars()
  return table.ifilter(self.sector.stars, function(star)
    return star:apparentLuminosity(self.camera.position) > 1
  end)
end

function Galaxy:filterStars()
  self.filteredStars = {}
  local stars = self:allStars()
  local f = self.starFilters[self.currentFilterKey]
  table.sort(stars, function(a, b)
    return f(a) < f(b)
  end)
  local starVerts = {}
  for i = 1, self.currentFilterLimit do
    local star = stars[i]
    self.filteredStars[i] = star
    local p = star.pos - self.camera.position
    table.insert(starVerts, {
      p.x, p.y, p.z,
      255, 255, 255, 255
    })
  end
  local vertexFormat = {
    {"VertexPosition", "float", 2},
    {"VertexZPosition", "float", 1},
    {"VertexColor", "byte", 4},
  }

  self.starsMesh = love.graphics.newMesh(vertexFormat, starVerts, "points", "static")
  self:drawCanvas()
end

function Galaxy:chooseItem(item)
  if self.starDetails then
    Save:saveShip(self.ship, nil, self.selectedStar)
    self.fsm:advance('back', self.fsmOpts)
  end
  if item == 'back' then
    self.fsm:advance('back', self.fsmOpts)
  elseif item == 'telescope' then
    if self.orienting then
      self.starDetails = self.selectedStar
    else
      self.orienting = true
    end
  elseif self.starFilters[item] then
    self.currentFilterKey = item
    self:filterStars()
  end
end

function Galaxy:cancelItem(item)
  if self.starDetails then
    self.starDetails = nil
  elseif item == 'telescope' then
    self.orienting = false
  end
end

function Galaxy:setDirection(direction)
  if self.orienting then
    if self.starDetails then return end
    local speed = math.pi/16
    if direction:isDiagonal() then
      -- diagonal, use pythagoras
      speed = speed / 1.414
    end
    self.rotationDir = Point(
      -direction.y * speed,
      direction.x * speed
    )
  else
    Galaxy.super.setDirection(self, direction)
  end
end

function Galaxy:update(dt)
  if self.rotationDir.x ~= 0 or self.rotationDir.y ~= 0 then
    local rot = self.rotationDir * dt
    self.camera:rotate(rot.x, rot.y)
    self:drawCanvas()
  end
end

function Galaxy:drawBackground(canvas)
  if canvas == nil then
    canvas = love.graphics.newCanvas(GameSize.w, GameSize.h)
  end
  local r = Rect(Point(), GameSize)

  self:drawStars(canvas)
  graphicsContext({canvas=canvas, color=Colors.white, origin=true}, function()
    local c = r:center() - Point(16, 16)
    if self.shipPlanet then
      self.shipPlanet:draw(c, 2)
    elseif self.shipStar then
      self.shipStar:drawClose(c, 45)
    end
  end)
  return canvas
end

function Galaxy:drawCanvas()
  local size = self.galaxyRect:size()
  if not self.canvas then
    self.canvas = love.graphics.newCanvas(size.w, size.h)
  end
  self:drawStars(self.canvas)
end

function Galaxy:drawStars(canvas)
  self.starShader:send("quatAngle", self.camera.orientation)
  graphicsContext({canvas=canvas, shader=self.starShader, color=Colors.white, origin=true}, function()
    love.graphics.clear()
    love.graphics.draw(self.starsMesh)
  end)
end

function Galaxy:drawStarDetails(star)
  local r = self.galaxyRect
  local o = r:origin() + Point(5, 5)
  graphicsContext({font = Fonts.medium, color = Colors.white}, function()
    star:drawClose(o + Point(15, 15), 20)
    love.graphics.print(star:name(), (o + Point(40, 0)):parts())
    local d = star:distance(self.camera.position)
    local t = star:tripTime(self.camera.position)
    local p = o + Point(0, 40)
    love.graphics.print("Distance: ".. round(d, 1) .. " parsecs", p:parts())
    p = p + Point(0, 10)
    love.graphics.print("Travel time: ".. round(t, 2) .. " years", p:parts())
  end)
end

function Galaxy:draw()
  local r = self.galaxyRect

  if self.starDetails then
    self:drawStarDetails(self.starDetails)
  else
    love.graphics.draw(self.canvas, r.x, r.y)
  end

  love.graphics.draw(self.background)
  local quad = self.menuQuads[self.currentFilterKey]
  if quad then
    graphicsContext({color = Colors.yellow}, function()
      local x, y, w, h = quad:getViewport( )
      love.graphics.draw(self.background, quad, x, y)
    end)
  end

  local sel = self:selectedItem()
  local quad = self.menuQuads[sel]
  if quad then
    graphicsContext({color = Colors.red}, function()
      local x, y, w, h = quad:getViewport( )
      love.graphics.draw(self.background, quad, x, y)
    end)
  elseif sel == 'telescope' and not self.orienting then
    graphicsContext({color = Colors.red, lineWidth=1}, function()
      local r = Rect(15, 15, 225, 209)
      r:draw('line')
      love.graphics.setColor(colorWithAlpha(Colors.red, 128))
      r:inset(1):draw('line')
    end)
  end
  local desc = self.itemDescriptions[sel]

  if self.starDetails then
    desc = "A: Travel   B: Cancel"
  elseif self.orienting then
    desc = "A: Examine   B: Cancel"
  end

  graphicsContext({color = Colors.menuBlue, font = Fonts.medium}, function()
    if desc then
      love.graphics.print(desc, 18, 5)
    end

    local detailStar
    if self.orienting then
      detailStar = self.selectedStar
    else
      detailStar = self.shipStar
    end
    if detailStar then
      love.graphics.setColor({0, 128, 0})
      love.graphics.setFont(Fonts.small)
      love.graphics.print(detailStar:details(self.shipPos), self.galaxyRect.x + 2, self.galaxyRect:bottom() + 2)
    end
  end)
end