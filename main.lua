require 'playerController'
require 'player'
require 'utils'

function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  Scale = {x=3, y=3}
  love.window.setMode(256 * Scale.x, 240 * Scale.y)
  PlayerController:load()
  Dude = Player()
  PlayerController:register(Dude)
end

function love.update(dt)
  PlayerController:update(dt)
  Dude:update(dt)
end

function love.draw()
  love.graphics.scale(Scale.x, Scale.y)
  Dude:draw()
end

function love.keypressed(key)
  PlayerController:keypressed(key)
end

function love.keyreleased(key)
  PlayerController:keyreleased(key)
end
