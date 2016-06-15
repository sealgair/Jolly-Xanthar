require 'menu.abstractMenu'

HUD = Menu:extend('HUD')

local hudBorder = 4

function HUD:init(world, playerIndex)
  HUD.super.init(self, {
    controlPlayer=playerIndex
  })
  self.font = Fonts.small
  self.world = world
  self.index = playerIndex
  self.barHeight = self.font:getHeight() + 4
  self.maxMenuHeight = 64
  self.menuHeight = self.maxMenuHeight
  self.active = true
  self.embarked = true

  self.rect = Rect(hudBorder, hudBorder, 64, self.barHeight)
  if self.index == 2 or self.index == 4 then
    self.rect.x = GameSize.w - self.rect.w - hudBorder
  end
  if self.index == 3 or self.index == 4 then
    self.rect.y = GameSize.h - self.rect.h - hudBorder
  end

  self.color = PlayerColors[self.index]
  self.shadowColor = map(self.color, function(c)
    return c * 0.5
  end)

  if self.player then
    self.prevHealth = math.max(self.player.health / self.player.maxHealth, 0)
  else
    self.prevHealth = 0
  end

  self.canvas = love.graphics.newCanvas()
  graphicsContext({canvas=self.canvas, origin=true}, function()
    self:drawBase()
  end)

  self.menuCanvas = love.graphics.newCanvas(self.rect.w, GameSize.h)
  self.menuOffset = 0
  self.newMenuOffset = self.menuOffset
end

function HUD:inShip()
  return class.isInstance(self.world, ShipWorld)
end

function HUD:drawBase()
  local x = self.rect.x
  local y = self.rect.y
  local w = self.rect.w
  local h = self.barHeight
  graphicsContext({}, function()
    love.graphics.setColor(self.shadowColor)
    if self.index > 2 then
      y = self.rect.y + self.rect.h - h
    end
    love.graphics.rectangle("fill", x, y, w, h)

    love.graphics.setColor(self.color)
    x = x + 1
    y = y + 1
    w = w - 2
    h = h - 2
    love.graphics.rectangle("fill", x, y, w, h)

    love.graphics.setColor(0, 0, 0)
    x = x + 1
    y = y + 1
    w = w - 2
    h = h - 2
    love.graphics.rectangle("fill", x, y, w, h)
  end)
  self.healthRect = Rect{ x = x, y = y, w = w, h = h, }
end

function HUD:drawMenuCanvas()
  local y = 1
  local w = self.rect.w
  local font = self.font
  local fh = font:getHeight()
  local offset = 0

  graphicsContext({canvas=self.menuCanvas, origin=true, font=font}, function()
    love.graphics.clear(Colors.menuBack)
    for r, row in ipairs(self.itemGrid) do
      local item = row[1]

      local rowHeight = fh * math.ceil(font:getWidth(item.name) / w)

      if r == self.selected.y then
        love.graphics.setColor(255, 0, 0)
        offset = y
      else
        love.graphics.setColor(255, 255, 255)
      end
      love.graphics.printf(item.name, 0, y, w, "center")
      y = y + rowHeight + 1
    end
    self.menuHeight = math.min(y, self.menuHeight)
  end)
  self.newMenuOffset = math.min(offset, y - self.menuHeight)
end

function HUD:playerAction(action)
  if action.action == "quit" then
    self.world:quit()
  elseif action.action == "drop out" then
    self.world:removePlayer(self.index)
  elseif action.action == "disembark" then
    self.world:disembark()
  elseif action.action == "switch" then
    self.itemGrid = map(self.world:remainingRoster(), function(n) return {n} end)
    self.selected.y = 1
    self.world:removePlayer(self.index)
    self:drawMenuCanvas()
  elseif action.action == "pause" then
    self.world.paused = not self.world.paused
  end
end

function HUD:controlStop(action)
  if action == 'select' and #self.itemGrid > 0 then
    self.selected.y = wrapping(self.selected.y + 1, #self.itemGrid)
    self:drawMenuCanvas()
  elseif action == 'start' then
    self.menuOffset = 0
    local item = self:selectedItem()
    if item then
      self.itemGrid = {}
      if self.player then
        self:playerAction(item)
      else
        self.world:addPlayer(item, self.index)
      end
    else
      self.selected.y = 1
      if self.player then
        self.itemGrid = {
          { { name = "Cancel", action = "cancel" } },
          { { name = "Quit", action = "quit" } },
          --{{name = "Controls"}}, TODO
        }
        if #self.world.players > 1 then
          local drop = { { name = "Drop Out", action = "drop out" } }
          table.insert(self.itemGrid, 2, drop)
        end
        if not self:inShip() then
          local paused = "Pause"
          if self.world.paused then paused = "Resume" end
          table.insert(self.itemGrid, 2, { { name = paused, action = "pause" } })
          table.insert(self.itemGrid, 3, { { name = "Back to Ship", action = "disembark" } })
          table.insert(self.itemGrid, 3, { { name = "Switch", action = "switch" } })
        end
      elseif self:inShip() then
        self.world:addPlayer(self.world:remainingRoster()[1], self.index)
      else
        self.itemGrid = map(self.world:remainingRoster(), function(n) return {n} end)
      end
      self:drawMenuCanvas()
    end
  end
end

function HUD:setDirection(direction)
  if self.player then
    -- don't use direction to swifch item
  else
    HUD.super.setDirection(self, direction)
    if #self.itemGrid > 0 then
      self:drawMenuCanvas()
    end
  end
end

function HUD:update(dt)
  if self.player then
    local newHealth = math.max(self.player.health / self.player.maxHealth, 0)
    if self.prevHealth > newHealth then
      self.prevHealth = self.prevHealth - dt / 3
    end
  end

  if #self.itemGrid > 0 then
    local move = 150 * dt
    if self.menuOffset > self.newMenuOffset then
      self.menuOffset = math.max(
        self.menuOffset - move,
        self.newMenuOffset
      )
    elseif self.menuOffset < self.newMenuOffset then
      self.menuOffset = math.min(
        self.menuOffset + move,
        self.newMenuOffset
      )
    end
    local sw, sh = self.menuCanvas:getDimensions()
    self.menuQuad = love.graphics.newQuad(0, self.menuOffset, sw, self.menuHeight, sw, sh)
  end
end

function HUD:draw()
  love.graphics.push()

  love.graphics.draw(self.canvas)

  local x = self.healthRect.x
  local y = self.healthRect.y
  local w = self.healthRect.w
  local h = self.healthRect.h

  if self.player then
    local healthPercent = math.max(self.player.health / self.player.maxHealth, 0)
    if healthPercent < self.prevHealth then
      local healthColor = {
        255 * math.min(2 + (self.prevHealth * -2), 1),
        255 * math.min(self.prevHealth * 2, 1),
        0
      }
      healthColor = map(healthColor, function(c) return c * 0.75 end)
      love.graphics.setColor(healthColor)
      love.graphics.rectangle("fill", x, y, w * self.prevHealth, h)
    end

    local healthColor = {
      255 * math.min(2 + (healthPercent * -2), 1),
      255 * math.min(healthPercent * 2, 1),
      0
    }
    love.graphics.setColor(healthColor)
    love.graphics.rectangle("fill", x, y, w * healthPercent, h)

    local barWidth = w / self.player.maxHealth
    if barWidth >= 4 then
      healthColor = map(healthColor, function(c) return c * 0.75 end)
      love.graphics.setColor(healthColor)
      local barX = x
      for i = 1, self.player.health - 1 do
        barX = barX + barWidth
        love.graphics.rectangle("fill", barX, y, 1, h)
      end
    end
  else
    love.graphics.setColor(255, 255, 255)
    love.graphics.setFont(self.font)
    love.graphics.printf("PRESS START", x, y, w, "center")
  end
  love.graphics.setColor(255, 255, 255)

  if #self.itemGrid > 0 then
    local x, y = self.rect.x, self.rect:bottom()

    if self.index >= 3 then
      local qx, qy, qw, qh = self.menuQuad:getViewport()
      y = y - qh - self.rect.h
    end
    love.graphics.draw(self.menuCanvas, self.menuQuad, x, y)
  end
  love.graphics.pop()
end