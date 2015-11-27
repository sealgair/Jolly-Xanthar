class = require 'lib/30log/30log'

Wall = class('Wall')


function Wall:collidesWith(b)
  return "slide", 1
end

function Wall:collide(cols)
end