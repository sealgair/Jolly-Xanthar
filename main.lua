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
  current = "none"
}

function StateMachine:currentState()
  return self.states[self.current]
end

function StateMachine:advance(input, options)
  local transition = self.transitions[self.current]
  if transition then
    local next = transition[input]
    if self.states[next] then
      self:currentState().active = nil
      if self:currentState().deactivate then
        self:currentState():deactivate()
      end
      self.current = next
      self:currentState().active = true
      if self:currentState().activate then
        self:currentState():activate(options)
      end
    end
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
  StateMachine.states = {
    world = World,
    ships = Ships(),
    recruit = Recruit,
    menu = Splash,
    controls = Controls,
    keyboard = Keyboard("Name Your Ship"),
  }
  StateMachine.transitions = {
    menu = {
      continue = "ships",
      new = "keyboard",
      controls = "controls",
    },
    ships = {
      done = "world"
    },
    keyboard = {
      done = "recruit"
    },
    controls = {
      done = "world",
      quit = "menu",
    },
    recruit = {
      done = "world"
    },
    world = {
      quit = "menu"
    },
  }
  StateMachine.current = "menu"
  Splash.active = true

  for k, state in pairs(StateMachine.states) do
    state:load(StateMachine)
  end
end

function love.update(dt)
  Controller:update(dt)
  local state = StateMachine:currentState()
  if state.update then
    state:update(dt)
  end
end

function love.draw()
  love.graphics.scale(GameScale.x, GameScale.y)
  local state = StateMachine:currentState()
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

function love.joystickpressed(joystick, button)
  Controller:joystickpressed(joystick, button)
end

function love.joystickreleased(joystick, button)
  Controller:joystickreleased(joystick, button)
end

function love.joystickaxis(joystick, axis, value)
  Controller:joystickaxis(joystick, axis, value)
end
