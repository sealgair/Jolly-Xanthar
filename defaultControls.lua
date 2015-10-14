function controls(...)
  local ctl = {}
  for i, c in ipairs({...}) do
    ctl[c] = 1
  end
  return ctl
end

return {
  {
    up = controls('joy1:ax2-', 'joy1:12', 'up'),
    down = controls('joy1:ax2+', 'joy1:13', 'down'),
    left = controls('joy1:ax1-', 'joy1:14', 'left'),
    right = controls('joy1:ax1+', 'joy1:15', 'right'),

    select = controls('joy1:10', ',', 'rshift'),
    start = controls('joy1:9', '.', 'return'),
    b = controls('joy1:1', 'joy1:3', 'm'),
    a = controls('joy1:2', 'joy1:4', 'n'),
  },
  {
    up = controls('joy2:ax2-', 'joy2:12', 'w'),
    down = controls('joy2:ax2+', 'joy2:13', 's'),
    left = controls('joy2:ax1-', 'joy2:14', 'a'),
    right = controls('joy2:ax1+', 'joy2:15', 'd'),

    select = controls('joy2:10', 'f'),
    start = controls('joy2:9', 'g'),
    b = controls('joy2:1', 'joy2:3', 'j'),
    a = controls('joy2:2', 'joy2:4', 'h'),
  },
  {
    up = controls('joy3:ax2-', 'joy3:12'),
    down = controls('joy3:ax2+', 'joy3:13'),
    left = controls('joy3:ax1-', 'joy3:14'),
    right = controls('joy3:ax1+', 'joy3:15'),

    select = controls('joy3:10'),
    start = controls('joy3:9'),
    b = controls('joy3:1', 'joy3:3'),
    a = controls('joy3:2', 'joy3:4'),
  },
  {
    up = controls('joy4:ax2-', 'joy4:12'),
    down = controls('joy4:ax2+', 'joy4:13'),
    left = controls('joy4:ax1-', 'joy4:14'),
    right = controls('joy4:ax1+', 'joy4:15'),

    select = controls('joy4:10'),
    start = controls('joy4:9'),
    b = controls('joy4:1', 'joy4:3'),
    a = controls('joy4:2', 'joy4:4'),
  }
}
