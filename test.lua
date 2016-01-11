require 'menu.galaxy'
require 'position'
require 'utils'

GameSize = Size{ w = 256, h = 240 }

local tests = {
  front = {
    Point(10, 10, 20),
    Point(10, 15, 20),
    Point(10, 05, 20),
    Point(15, 10, 20),
    Point(05, 10, 20),
  },
  back = {
    Point(10, 10, 0),
    Point(10, 15, 0),
    Point(10, 05, 0),
    Point(15, 10, 0),
    Point(05, 10, 0),
  },
  left = {
    Point(0, 10, 10),
    Point(0, 15, 10),
    Point(0, 5, 10),
    Point(0, 10, 15),
    Point(0, 10, 5),
  },
  right = {
    Point(20, 10, 10),
    Point(20, 15, 10),
    Point(20, 5, 10),
    Point(20, 10, 15),
    Point(20, 10, 5),
  },
  up = {
    Point(10, 0, 10),
    Point(15, 0, 10),
    Point(5, 0, 10),
    Point(10, 0, 15),
    Point(10, 0, 5),
  },
  down = {
    Point(10, 20, 10),
    Point(15, 20, 10),
    Point(5, 20, 10),
    Point(10, 20, 15),
    Point(10, 20, 5),
  },
}

local screen = Size(100, 100)
for dir, points in pairs(tests) do
  print("proj "..dir)
  local cam = Camera(Point(10, 10, 10), Orientations[dir], screen)
  for p in values(points) do
    local b = cam:project(p, true)
  end
end
