function controls(...)
  local ctl = {}
  for i, c in ipairs({...}) do
    ctl[c] = 1
  end
  return ctl
end

return {
  {
    up = controls('joy1:LSY-', 'joy1:Up', 'up'),
    down = controls('joy1:LSY+', 'joy1:Down', 'down'),
    left = controls('joy1:LSX-', 'joy1:Left', 'left'),
    right = controls('joy1:LSX+', 'joy1:Right', 'right'),

    select = controls('joy1:Back', ',', 'rshift'),
    start = controls('joy1:Start', '.', 'return'),
    b = controls('joy1:A', 'joy1:X', 'm'),
    a = controls('joy1:B', 'joy1:Y', 'n'),
  },
  {
    up = controls('joy2:LSY-', 'joy2:Up', 'w'),
    down = controls('joy2:LSY+', 'joy2:Down', 's'),
    left = controls('joy2:LSX-', 'joy2:Left', 'a'),
    right = controls('joy2:LSX+', 'joy2:Right', 'd'),

    select = controls('joy2:Back', 'f'),
    start = controls('joy2:Start', 'g'),
    b = controls('joy2:A', 'joy2:X', 'j'),
    a = controls('joy2:B', 'joy2:Y', 'h'),
  },
  {
    up = controls('joy3:LSY-', 'joy3:Up'),
    down = controls('joy3:LSY+', 'joy3:Down'),
    left = controls('joy3:LSX-', 'joy3:Left'),
    right = controls('joy3:LSX+', 'joy3:Right'),

    select = controls('joy3:Back'),
    start = controls('joy3:Start'),
    b = controls('joy3:A', 'joy3:X'),
    a = controls('joy3:B', 'joy3:Y'),
  },
  {
    up = controls('joy4:LSY-', 'joy4:Up'),
    down = controls('joy4:LSY+', 'joy4:Down'),
    left = controls('joy4:LSX-', 'joy4:Left'),
    right = controls('joy4:LSX+', 'joy4:Right'),

    select = controls('joy4:Back'),
    start = controls('joy4:Start'),
    b = controls('joy4:A', 'joy4:X'),
    a = controls('joy4:B', 'joy4:Y'),
  }
}
