require 'controller'
require 'utils'
require 'world'
require 'save'
require 'menu.ships'
require 'menu.recruit'
require 'menu.splash'
require 'menu.keyboard'
require 'menu.controls'

GameSize = Size{ w = 256, h = 240 }
GameScale = { x = 3, y = 3 }
Fonts = {}
math.randomseed( os.time() )

local StateMachine = {
  states = {},
  transitions = {},
}

function StateMachine:advance(input, options)
  local nextState
  if self.currentState then
    local transition = self.transitions[self.currentState.class]
    nextState = transition[input]
    self.currentState.active = false
    if self.currentState.deactivate then
      self.currentState:deactivate()
    end
  else
    nextState = self.transitions.initial[input]
  end
  self.currentState = nextState(self, options)
  self.currentState.active = true
  if self.currentState.activate then
    self.currentState:activate()
  end
end

function love.load(arg)
  Save:load()

  if arg[#arg] == "-debug" then require("mobdebug").start() end
  love.window.setMode(GameSize.w * GameScale.x, GameSize.h * GameScale.y)
  love.graphics.setDefaultFilter("nearest", "nearest")

  local glyphs = " "..
  "abcdefghijklmnopqrstuvwxyz"..
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ"..
  "1234567890"..
  ".,!?-+/():;%&`'*#=[]\\\"_|Ø"
  Fonts[10] = love.graphics.newImageFont("assets/fonts/font10.png", glyphs)
  Fonts[16] = love.graphics.newImageFont("assets/fonts/font16.png", glyphs)

  Controller:load()
  StateMachine.transitions = {
    initial = {
      menu = Splash,
    },
    [Splash] = {
      continue = Ships,
      new = Keyboard,
      controls = Controls,
    },
    [Ships] = {
      done = World
    },
    [Keyboard] = {
      done = Recruit
    },
    [Controls] = {
      done = Splash,
    },
    [Recruit] = {
      done = World
    },
    [World] = {
      quit = Splash
    },
  }
  StateMachine:advance("menu")
end

function love.update(dt)
  Controller:update(dt)
  local state = StateMachine.currentState
  if state and state.update then
    state:update(dt)
  end
end

function love.draw()
  love.graphics.scale(GameScale.x, GameScale.y)
  local state = StateMachine.currentState
  if state and state.draw then
    state:draw()
  end
end

function love.keypressed(key)
  Controller:keypressed(key)
end

function love.keyreleased(key)
  Controller:keyreleased(key)
end

function love.joystickpressed(joystick, button)
  Controller:joystickpressed(joystick, button)
end

function love.joystickreleased(joystick, button)
  Controller:joystickreleased(joystick, button)
end

function love.joystickaxis(joystick, axis, value)
  Controller:joystickaxis(joystick, axis, value)
end
