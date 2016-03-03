-- require('lib/cupid')

function love.conf(t)
  t.version = "0.10.1"
  t.window.title = "Jolly Xanthar"

  t.window.center = true
  t.window.width = 256
  t.window.height = 240
  t.window.fullscreen = true
  t.window.fullscreentype = "exclusive"

  t.modules.physics = false
end