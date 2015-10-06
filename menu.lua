Menu = {
  items = {
    'start',
    'controls'
  }
}

function Menu:load()
  self.background = love.graphics.newImage('assets/Splash.png')
  self.menu = love.graphics.newImage('assets/Menu.png')
end

function Menu:update(dt)
end

function Menu:draw()
  love.graphics.draw(self.background, 0, 0)
end
