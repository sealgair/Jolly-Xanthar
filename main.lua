require 'controller'
require 'utils'
require 'world'
require 'ship'
require 'save'
require 'menu.ships'
require 'menu.recruit'
require 'menu.splash'
require 'menu.keyboard'
require 'menu.controls'

GameSize = Size{ w = 256, h = 240 }
GameScale = Point(3, 3)
GameOffset = Point(0, 0)
Fonts = {}
math.randomseed( os.time() )

Colors = {
  red      = { 255, 0, 0 },
  white    = { 255, 255, 255 },
  menuBlue = { 0, 128, 255 },
  menuGray = { 128, 128, 128 },
  menuRed  = { 128, 0, 0 },
}


local StateMachine = {
  states = {},
  transitions = {},
}

function StateMachine:advance(input, options)
  print("fsm advance", self.currentState, input)

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
  print("fsm adfance to", nextState)
  self.currentState = nextState(self, options)
  self.currentState.active = true
  if self.currentState.activate then
    self.currentState:activate()
  end
end

function love.load(arg)
  Save:load()

  if arg[#arg] == "-debug" then require("mobdebug").start() end
  local w, h = love.graphics.getDimensions()
  print('dims', w, h)
  local sw = math.floor(w / GameSize.h)
  local sh = math.floor(h / GameSize.h)
  local s = math.min(sw, sh)
  GameScale.x = s
  GameScale.y = s

  GameOffset.x = (w - s * GameSize.w) / 2
  GameOffset.y = (h - s * GameSize.h) / 2
  print('offset', GameOffset)
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.mouse.setVisible(false)

  local glyphs = " "..
  "abcdefghijklmnopqrstuvwxyz"..
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ"..
  "1234567890"..
  ".,!?-+/():;%&`'*#=[]\\\"_|Ø"..
  "←↑→↓"
  for fontFile in values(love.filesystem.getDirectoryItems("assets/fonts")) do
    if fontFile:find(".png$") then
      local fontName = fontFile:gsub(".png", "")
      Fonts[fontName] = love.graphics.newImageFont("assets/fonts/" .. fontFile, glyphs, 1)
    end
  end

  Controller:load()
  StateMachine.transitions = {
    initial = {
      menu = Splash,
    },
    [Splash] = {
      continue = ShipMenu,
      new = Keyboard,
      controls = Controls,
      quit = function() love.event.quit(); return {} end,
    },
    [ShipMenu] = {
      done = Ship,
    },
    [Ship] = {
      land = World,
      quit = Splash,
    },
    [Keyboard] = {
      done = Recruit,
    },
    [Controls] = {
      done = Splash,
    },
    [Recruit] = {
      done = Ship,
    },
    [World] = {
      descend = World,
      quit = Ship,
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
  love.graphics.translate(GameOffset.x, GameOffset.y)
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
