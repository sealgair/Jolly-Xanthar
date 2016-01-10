require 'menu.galaxy'
require 'position'
require 'utils'

GameSize = Size{ w = 256, h = 240 }

local c1 = Camera(Point(10, 10, 10), Orientations.front, Size(100, 100))
local c2 = Camera(Point(10, 10, 10), Orientations.back, Size(100, 100))
local c3 = Camera(Point(10, 10, 10), Orientations.up, Size(100, 100))

local tests = {
  Point(10, 10, 20),
  Point(10, 15, 20),
  Point(10, 05, 20),
  Point(15, 10, 20),
  Point(05, 10, 20),

  Point(150, 10, 20),
  Point(11, 11, 11),
  Point(11, 11, 12),
}
for p in values(tests) do
--  c:project(p)
  print("projection", p, c:project(p))
end
