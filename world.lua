require 'playerController'
World = {}

function World:load()
  self.players = {
    Player(16, 16),
    Player(16, 208),
    Player(224, 16),
    Player(224, 208),
  }
  for i, player in ipairs(self.players) do
    PlayerController:register(player, i)
  end
end

function World:update(dt)
  for i, dude in ipairs(self.players) do
    dude:update(dt)
  end
end

function World:draw()
  for i, dude in ipairs(self.players) do
    dude:draw()
  end
end
