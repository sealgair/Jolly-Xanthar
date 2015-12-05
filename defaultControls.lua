function controls(...)
  local ctl = {}
  for i, c in ipairs({...}) do
    ctl[c] = 1
  end
  return ctl
end

return {
  {
    up = controls('gp1:LSY-', 'gp1:Up', 'up'),
    down = controls('gp1:LSY+', 'gp1:Down', 'down'),
    left = controls('gp1:LSX-', 'gp1:Left', 'left'),
    right = controls('gp1:LSX+', 'gp1:Right', 'right'),

    select = controls('gp1:Back', ',', 'rshift'),
    start = controls('gp1:Start', '.', 'return'),
    b = controls('gp1:A', 'gp1:X', 'm'),
    a = controls('gp1:B', 'gp1:Y', 'n'),
  },
  {
    up = controls('gp2:LSY-', 'gp2:Up', 'w'),
    down = controls('gp2:LSY+', 'gp2:Down', 's'),
    left = controls('gp2:LSX-', 'gp2:Left', 'a'),
    right = controls('gp2:LSX+', 'gp2:Right', 'd'),

    select = controls('gp2:Back', 'f'),
    start = controls('gp2:Start', 'g'),
    b = controls('gp2:A', 'gp2:X', 'j'),
    a = controls('gp2:B', 'gp2:Y', 'h'),
  },
  {
    up = controls('gp3:LSY-', 'gp3:Up'),
    down = controls('gp3:LSY+', 'gp3:Down'),
    left = controls('gp3:LSX-', 'gp3:Left'),
    right = controls('gp3:LSX+', 'gp3:Right'),

    select = controls('gp3:Back'),
    start = controls('gp3:Start'),
    b = controls('gp3:A', 'gp3:X'),
    a = controls('gp3:B', 'gp3:Y'),
  },
  {
    up = controls('gp4:LSY-', 'gp4:Up'),
    down = controls('gp4:LSY+', 'gp4:Down'),
    left = controls('gp4:LSX-', 'gp4:Left'),
    right = controls('gp4:LSX+', 'gp4:Right'),

    select = controls('gp4:Back'),
    start = controls('gp4:Start'),
    b = controls('gp4:A', 'gp4:X'),
    a = controls('gp4:B', 'gp4:Y'),
  }
}
