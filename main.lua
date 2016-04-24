-- Initialize Graphene
local MyGame = require("graphene")

-- Let Graphene know that 'Carbon' is a standalone library
MyGame:AddGrapheneSubmodule("Carbon")

-- You can now reference Carbon as MyGame.Carbon!
local Carbon = MyGame.Carbon

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
require 'menu.galaxy'
require 'menu.starsystem'

GameSize = Size{ w = 256, h = 240 }
GameScale = Point(3, 3)
GameOffset = Point(0, 0)
Fonts = {}
math.randomseed( os.time() )

Colors = {
  red =      { 255, 0, 0 },
  yellow =   { 255, 255, 0 },
  green =    { 0, 255, 0 },
  blue =     { 0, 0, 255 },
  white =    { 255, 255, 255 },
  black =    { 0, 0, 0 },
  menuBlue = { 0, 128, 255 },
  halfGray = { 128, 128, 128 },
  menuGray = { 128, 128, 128 },
  menuRed =  { 128, 0, 0 },
  menuBack = { 0, 0, 0, 128 }
}
PlayerColors = {
  { 255, 0, 0 },
  { 80, 80, 255 },
  { 0, 255, 0 },
  { 255, 255, 0 },
}

function colorWithAlpha(c, a)
  return { c[1], c[2], c[3], a }
end

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
  love.graphics.setDefaultFilter("nearest", "nearest", 0)
  Save:load()

  if arg[#arg] == "-debug" then require("mobdebug").start() end
  local w, h = love.graphics.getDimensions()
  local sw = math.floor(w / GameSize.h)
  local sh = math.floor(h / GameSize.h)
  local s = math.min(sw, sh)
  GameScale.x = s
  GameScale.y = s

  GameOffset.x = (w - s * GameSize.w) / 2
  GameOffset.y = (h - s * GameSize.h) / 2
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.mouse.setVisible(false)

  local glyphs = " "..
  "abcdefghijklmnopqrstuvwxyz"..
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ"..
  "1234567890"..
  ".,!?-+/():;%&`'*#=[]\\\"_|Ø"..
  "←↑→↓⊙°"
  for fontFile in values(love.filesystem.getDirectoryItems("assets/fonts")) do
    if fontFile:find(".png$") then
      local fontName = fontFile:gsub(".png", "")
      Fonts[fontName] = love.graphics.newImageFont("assets/fonts/" .. fontFile, glyphs, 1)
      Fonts[fontName]:setLineHeight(1.2)
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
      galaxy = Galaxy,
      controls = Controls,
      quit = function() love.event.quit(); return {} end,
    },
    [ShipMenu] = {
      done = Ship,
    },
    [Ship] = {
      land = World,
      quit = Splash,
      navPlanet = StarSystem,
      navStar = Galaxy,
    },
    [StarSystem] = {
      back = Ship,
      galaxy = Galaxy,
    },
    [Galaxy] = {
      back = Ship,
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
      disembark = Ship,
      quit = Splash,
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
