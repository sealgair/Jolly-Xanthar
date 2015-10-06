require 'playerController'
require 'player'
require 'utils'
require 'world'
require 'menu'

local StateMachine = {
  states = {}
}

function StateMachine:advance(option)
  if self.current == self.states.menu then
    if option == 'start' then
      self.current = self.states.world
    end
  end
end

function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  Scale = {x=3, y=3}
  love.window.setMode(256 * Scale.x, 240 * Scale.y)
  love.graphics.setDefaultFilter("nearest", "nearest")

  PlayerController:load()
  StateMachine.states = {
    world = World,
    menu = Menu,
  }
  StateMachine.current = StateMachine.states.menu

  for k, state in pairs(StateMachine.states) do
    state:load(StateMachine)
  end
end

function love.update(dt)
  PlayerController:update(dt)
  StateMachine.current:update(dt)
end

function love.draw()
  love.graphics.scale(Scale.x, Scale.y)
  StateMachine.current:draw()
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
