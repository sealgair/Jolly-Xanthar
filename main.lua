require 'playerController'
require 'player'
require 'utils'
require 'world'
require 'menu'
require 'changeControls'

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

  PlayerController:load()
  StateMachine.states = {
    world = World,
    menu = Menu,
    controls = ChangeControls,
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
  Menu.active = true

  for k, state in pairs(StateMachine.states) do
    state:load(StateMachine)
  end
end

function love.update(dt)
  PlayerController:update(dt)
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
