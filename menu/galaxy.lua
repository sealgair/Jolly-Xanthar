class = require 'lib/30log/30log'
bit32 = require('lib.numberlua')
require 'menu.abstractMenu'
require 'position'
require 'camera'
require 'utils'
require 'star'

function safeAlpha(a)
  return math.max(math.min(a, 255), 0)
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
  self.currentFilterLimit = 2000

  self.seed = 1000
  self.sector = Sector(Point(0,0,0), 0.14, self.seed)

  self.fsmOpts = opts
  if self.fsmOpts and self.fsmOpts.ship then
    self.ship = self.fsmOpts.ship
  else
    self.ship = Ship.firstShip()
  end

  if self.ship.star then
    self.shipPos = self.ship.star.pos
  else
    self.shipPos = self.sector.box:center()
  end
  self.starShader = love.graphics.newShader("shaders/stars.glsl")
  self.starLegsShader = love.graphics.newShader("shaders/starlegs.glsl")
  self.camera = Camera(self.shipPos, Size(GameSize))
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

function intToPixel(id)
  return {
    bit32.band(id, 255),
    bit32.band(bit32.rshift(id, 8), 255),
    bit32.band(bit32.rshift(id, 16), 255),
  }
end

function pixelToInt(p)
  return bit32.bor(p[1], bit32.lshift(p[2], 8), bit32.lshift(p[3], 16))
end

function Galaxy:filterStars()
  self.filteredStars = {}
  local stars = self:allStars()
  local f = self.starFilters[self.currentFilterKey]
  table.sort(stars, function(a, b)
    return f(a) < f(b)
  end)
  local starVerts = {}
  local starIdVerts = {}
  for i = 1, math.min(self.currentFilterLimit, #stars) do
    local star = stars[i]
    self.filteredStars[i] = star
    local p = star.pos - self.camera.position
    local c = star:color()
    local b = star:apparentBrightness(self.camera.position) * 255
    table.insert(starVerts, {
      p.x, p.y, p.z,
      c[1], c[2], c[3], b
    })
    local px = intToPixel(i)
    table.insert(starIdVerts, {
      p.x, p.y, p.z,
      px[1], px[2], px[3], 255
    })
  end
  local vertexFormat = {
    {"VertexPosition", "float", 2},
    {"VertexZPosition", "float", 1},
    {"VertexColor", "byte", 4},
  }

  self.starsMesh = love.graphics.newMesh(vertexFormat, starVerts, "points", "static")
  self.starIdsMesh = love.graphics.newMesh(vertexFormat, starIdVerts, "points", "static")
  self:drawCanvas()
end

function Galaxy:chooseItem(item)
  if self.starDetails then
    self.ship.star = self.selectedStar
    self.ship.planet = nil
    self.ship:save()
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
    self:centerStar()
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
    if self.ship.planet then
      self.ship.planet:draw(c, 2)
    elseif self.ship.star then
      self.ship.star:drawClose(c, 45)
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
  local c = Rect(Point(), size):center() - Point(0.5, 0.5)
  graphicsContext({canvas=self.canvas, origin=true, color={0, 255, 0, 200}}, function()
    local r = 3
    love.graphics.line(c.x, c.y - r, c.x, c.y + r)
    love.graphics.line(c.x - r, c.y, c.x + r, c.y)

    if self.selectedStar then
      local s = self.selectedStarCoord
      love.graphics.circle("line", s.x, s.y, 3, 4)
    end
  end)
end

function Galaxy:centerStar()
  local size = self.galaxyRect:size()
  if self.centerStarCanvas == nil then
    self.centerStarCanvas = love.graphics.newCanvas(size:parts())
  end
  graphicsContext({canvas=self.centerStarCanvas, shader=self.starShader, origin=true}, function()
    love.graphics.clear()
    love.graphics.draw(self.starIdsMesh)
  end)
  local w, h = size:parts()
  local prect = Rect(0, 0, 8, 8)
  prect:setCenter(size:center())
  local pixels = self.centerStarCanvas:newImageData(prect:parts())
  local minDist = 10^10
  local pixel
  local coord
  local c = prect:size():center()
  pixels:mapPixel(function(x, y, r, g, b, a)
    if a > 0 then
      local d = c:distanceToSquared(Point(x, y))
      if d < minDist then
        minDist = d
        pixel = {r, g, b }
        coord = Point(x, y)
      end
    end
    return r, g, b, a
  end)
  if pixel ~= nil then
    local starID = pixelToInt(pixel)
    self.selectedStar = self.filteredStars[starID]
    self.selectedStarCoord = coord + prect:origin()
  else
    self.selectedStar = nil
    self.selectedStarCoord = nil
  end
end

function Galaxy:drawStars(canvas)
  local tmpCanvas = love.graphics.newCanvas(canvas:getDimensions())
  self.starShader:send("quatAngle", self.camera.orientation:raw())
  graphicsContext({canvas=tmpCanvas, shader=self.starShader, origin=true}, function()
    love.graphics.draw(self.starsMesh)
  end)
  graphicsContext({canvas=canvas, shader=self.starLegsShader, origin=true}, function()
    love.graphics.clear()
    love.graphics.draw(tmpCanvas)
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
      detailStar = self.ship.star
    end
    if detailStar then
      love.graphics.setColor({0, 128, 0})
      love.graphics.setFont(Fonts.small)
      love.graphics.print(detailStar:details(self.shipPos), self.galaxyRect.x + 2, self.galaxyRect:bottom() + 2)
      detailStar:drawClose(Point(self.galaxyRect:right() - 8, self.galaxyRect:bottom() + 8), 6)
    end
  end)
end