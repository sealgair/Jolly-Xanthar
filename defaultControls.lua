function controls(...)
  local ctl = {}
  for i, c in ipairs({...}) do
    ctl[c] = 1
  end
  return ctl
end

return {
  {
    up = controls('joy1:leftStick', 'joy1:dpup', 'up'),
    down = controls('joy1:leftStick', 'joy1:dpdown', 'down'),
    left = controls('joy1:leftStick', 'joy1:dpleft', 'left'),
    right = controls('joy1:leftStick', 'joy1:dpright', 'right'),

    a = controls('joy1:a', 'joy1:x', 'n'),
    b = controls('joy1:b', 'joy1:y', 'm'),
    select = controls('joy1:back', ',', 'rshift'),
    start = controls('joy1:start', '.', 'return'),
  },
  {
    up = controls('joy2:leftStick', 'joy2:dpup', 'w'),
    down = controls('joy2:leftStick', 'joy2:dpdown', 's'),
    left = controls('joy2:leftStick', 'joy2:dpleft', 'a'),
    right = controls('joy2:leftStick', 'joy2:dpright', 'd'),

    a = controls('joy2:a', 'joy2:x', 'h'),
    b = controls('joy2:b', 'joy2:y', 'j'),
    select = controls('joy2:back', 'f'),
    start = controls('joy2:start', 'g'),
  },
  {
    up = controls('joy3:leftStick', 'joy3:dpup'),
    down = controls('joy3:leftStick', 'joy3:dpdown'),
    left = controls('joy3:leftStick', 'joy3:dpleft'),
    right = controls('joy3:leftStick', 'joy3:dpright'),

    a = controls('joy3:a', 'joy3:x'),
    b = controls('joy3:b', 'joy3:y'),
    select = controls('joy3:back'),
    start = controls('joy3:start'),
  },
  {
    up = controls('joy4:leftStick', 'joy4:dpup'),
    down = controls('joy4:leftStick', 'joy4:dpdown'),
    left = controls('joy4:leftStick', 'joy4:dpleft'),
    right = controls('joy4:leftStick', 'joy4:dpright'),

    a = controls('joy4:a', 'joy4:x'),
    b = controls('joy4:b', 'joy4:y'),
    select = controls('joy4:back'),
    start = controls('joy4:start'),
  }
}
