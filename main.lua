require 'playerController'
require 'player'
require 'utils'
require 'world'
require 'menu'

function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  Scale = {x=3, y=3}
  love.window.setMode(256 * Scale.x, 240 * Scale.y)
  love.graphics.setDefaultFilter("nearest", "nearest")

  PlayerController:load()
  States = {
    world = World,
    menu = Menu,
  }
  States.current = States.menu
  for k, state in pairs(States) do
    state:load()
  end
end

function love.update(dt)
  PlayerController:update(dt)
  States.current:update(dt)
end

function love.draw()
  love.graphics.scale(Scale.x, Scale.y)
  States.current:draw()
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
