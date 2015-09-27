function round(num)
     if num >= 0 then return math.floor(num+.5)
     else return math.ceil(num-.5) end
 end

function love.load()
  love.window.setMode(256*2, 240*2)

  Critters = love.graphics.newImage('assets/critters.png')
  Critters:setFilter("nearest", "nearest")
  local w, h = 32, 32
  local tw, th = Critters:getWidth(), Critters:getHeight()
  DudeQuads = {
    down = love.graphics.newQuad(0, 64, w, h, tw, th),
    up = love.graphics.newQuad(0, 96, w, h, tw, th),
    right = love.graphics.newQuad(0, 128, w, h, tw, th),
    left = love.graphics.newQuad(0, 160, w, h, tw, th),
  }
  DudeQuad = DudeQuads.down
  DudePos = {10, 10}
end

function love.update(dt)
  local dpos = dt*20
  if love.keyboard.isDown("up") then
    DudePos[2] = DudePos[2] - dpos
  elseif love.keyboard.isDown("down") then
    DudePos[2] = DudePos[2] + dpos
  elseif love.keyboard.isDown("left") then
    DudePos[1] = DudePos[1] - dpos
  elseif love.keyboard.isDown("right") then
    DudePos[1] = DudePos[1] + dpos
  end
end

function love.draw()
  love.graphics.scale(2, 2)
  love.graphics.draw(Critters, DudeQuad, round(DudePos[1]), round(DudePos[2]))
end

function love.keypressed(key)
  if DudeQuads[key] then
    DudeQuad = DudeQuads[key]
  end
end
