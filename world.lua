require 'controller'

World = {}

setmetatable(World, {
  __newindex = function(self, key, value)
    rawset(self, key, value)
    if key == 'active' then
      for i, player in pairs(self.players) do
        player.active = self.active
      end
    end
  end
})

function World:load()
  self.players = {
    Player(16, 16),
    Player(16, 208),
    Player(224, 16),
    Player(224, 208),
  }
  for i, player in ipairs(self.players) do
    Controller:register(player, i)
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
