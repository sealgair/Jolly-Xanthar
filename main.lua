require 'playerController'
require 'player'
require 'utils'

function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  Scale = {x=3, y=3}
  love.window.setMode(256 * Scale.x, 240 * Scale.y)

  PlayerController:load()

  players = {
    Player(10, 10),
    Player(50, 50),
    Player(100, 100),
  }
  for i, player in ipairs(players) do
    PlayerController:register(player, i)
  end
end

function love.update(dt)
  PlayerController:update(dt)
  for i, dude in ipairs(players) do
    dude:update(dt)
  end
end

function love.draw()
  love.graphics.scale(Scale.x, Scale.y)
  for i, dude in ipairs(players) do
    dude:draw()
  end
end

function love.keypressed(key)
  PlayerController:keypressed(key)
end

function love.keyreleased(key)
  PlayerController:keyreleased(key)
end

function love.gamepadpressed(joystick, button)
  PlayerController:gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
  PlayerController:gamepadreleased(joystick, button)
end
