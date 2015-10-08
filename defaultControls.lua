function controls(...)
  local ctl = {}
  for i, c in ipairs({...}) do
    ctl[c] = 1
  end
  return ctl
end

return {
  {
    up = controls('joy1:leftStick'),
    down = controls('joy1:leftStick'),
    left = controls('joy1:leftStick'),
    right = controls('joy1:leftStick'),

    a = controls('joy1:a', 'joy1:x'),
    b = controls('joy1:b', 'joy1:y'),
    select = controls('joy1:back'),
    start = controls('joy1:start'),
  },
  {
    up = controls('joy1:rightStick'),
    down = controls('joy1:rightStick'),
    left = controls('joy1:rightStick'),
    right = controls('joy1:rightStick'),

    a = controls('f'),
    b = controls('g'),
    select = controls('r'),
    start = controls('y'),
  },
  {
    up = controls('joy1:dpup'),
    down = controls('joy1:dpdown'),
    left = controls('joy1:dpleft'),
    right = controls('joy1:dpright'),

    a = controls('l'),
    b = controls(';'),
    select = controls('o'),
    start = controls('p'),
  },
  {
    up = controls('up'),
    down = controls('down'),
    left = controls('left'),
    right = controls('right'),

    a = controls('n'),
    b = controls('m'),
    select = controls(',', 'rshift'),
    start = controls('.', 'return'),
  }
}
