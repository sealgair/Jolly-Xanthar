require 'controller'
require 'player'
require 'utils'
require 'world'
require 'menu/splash'
require 'menu/controls'

local StateMachine = {
  states = {},
  transitions = {},
  current = "none"
}

function StateMachine:currentState()
  return self.states[self.current]
end

function StateMachine:advance(input, options)
  local transition = self.transitions[self.current]
  if transition then
    next = transition[input]
    if self.states[next] then
      self:currentState().active = nil
      self.current = next
      self:currentState().active = true
    end
  end
end

function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  Scale = {x=3, y=3}
  love.window.setMode(256 * Scale.x, 240 * Scale.y)
  love.graphics.setDefaultFilter("nearest", "nearest")

  Controller:load()
  StateMachine.states = {
    world = World,
    menu = Splash,
    controls = Controls,
  }
  StateMachine.transitions = {
    menu = {
      start = "world",
      controls = "controls"
    },
    controls = {
      done = "menu"
    },
    world = {
      quit = "menu"
    }
  }
  StateMachine.current = "menu"
  Splash.active = true

  for k, state in pairs(StateMachine.states) do
    state:load(StateMachine)
  end
end

function love.update(dt)
  Controller:update(dt)
  state = StateMachine:currentState()
  if state.update then
    state:update(dt)
  end
end

function love.draw()
  love.graphics.scale(Scale.x, Scale.y)
  state = StateMachine:currentState()
  if state.draw then
    state:draw()
  end
end

function love.keypressed(key)
  Controller:keypressed(key)
end

function love.keyreleased(key)
  Controller:keyreleased(key)
end

function love.gamepadpressed(joystick, button)
  Controller:gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
  Controller:gamepadreleased(joystick, button)
end
