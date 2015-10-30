function round(num)
  if num >= 0 then
    return math.floor(num + .5)
  else
    return math.ceil(num - .5)
  end
end

function invert(t)
  local inverted = {}
  for key, value in pairs(t) do
    inverted[value] = key
  end
  return inverted
end

function last(t)
  return t[#t]
end

function setDefault(t, key, value)
  if t[key] == nil then
    t[key] = value
  end
end

function string:startsWith(substring)
  return self:sub(1, substring:len()) == substring
end

function string:endsWith(substring)
  return substring == '' or self:sub(-substring:len()) == substring
end

function string:contains(substring)
  return self:find(substring) ~= nil
end

function bounded(min, value, max)
  if value < min then
    return min
  elseif value > max then
    return max
  else
    return value
  end
end

function wrapping(value, max, min)
  if min == nil then
    min = 1
  end
  if value < min then
    return max
  elseif value > max then
    return min
  else
    return value
  end
end

function keyCount(table)
  local n = 0
  for _, _ in pairs(table) do
    n = n + 1
  end
  return n
end

function table.filter(t, filterIter)
  local out = {}

  for k, v in pairs(t) do
    if filterIter(v, k, t) then out[k] = v end
  end

  return out
end

function table.removeValue(t, value)
  for k, v in pairs(t) do
    if v == value then
      table.remove(t, k)
    end
  end
end

function coalesce(...)
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    if v ~= nil then return v end
  end
  return nil
end

function values(t)
  local k, v
  return function()
    k, v = next(t, k)
    return v
  end
end

function map(t, func)
  local result = {}
  for k, v in pairs(t) do
    result[k] = func(v)
  end
  return result
end

function sign(n)
  if n > 0 then
    return 1
  elseif n < 0 then
    return -1
  else
    return 0
  end
end

function join(strings, separator)
  local res = ""
  for s in values(strings) do
    res = res .. s .. separator
  end
  return res:sub(1, res:len() - separator:len())
end

function palletSwapShader(fromColors, toColors)
  local function serializeColors(colors)
    return join(map(colors, function(color)
      local translated = map(color, function(c) return c / 255 end)
      if #translated == 3 then table.insert(translated, 1.0) end
      return "vec4(" .. join(translated, ", ") .. ")"
    end), ", ")
  end

  local fromArray = serializeColors(fromColors)
  local toArray = serializeColors(toColors)

  local shader = love.graphics.newShader([[
  vec4 fromColor[] = vec4[]( ]] .. fromArray .. [[ );
  vec4 toColor[] = vec4[]( ]] .. toArray .. [[ );

  bool same_color( vec4 a, vec4 b ) {
    float tolerance = 1.0/255.0;
    for (int i = 0; i < 4; i++) {
      if (a[i] <= b[i] - tolerance || a[i] >= b[i] + tolerance) {
        return false;
      }
    }
    return true;
  }

  vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ) {
    vec4 texcolor = Texel(texture, texture_coords);

    for (int i = 0; i < fromColor.length(); i++) {
      if (same_color(texcolor, fromColor[i])) {
        return toColor[i];
      }
    }
    return texcolor;
  }
  ]])
  return shader
end

function HSVtoRGB(h, s, v)
  if s <= 0 then return v, v, v end
  h, s, v = h / 256 * 6, s / 255, v / 255
  local c = v * s
  local x = (1 - math.abs((h % 2) - 1)) * c
  local m, r, g, b = (v - c), 0, 0, 0
  if h < 1 then r, g, b = c, x, 0
  elseif h < 2 then r, g, b = x, c, 0
  elseif h < 3 then r, g, b = 0, c, x
  elseif h < 4 then r, g, b = 0, x, c
  elseif h < 5 then r, g, b = x, 0, c
  else r, g, b = c, 0, x
  end return {(r + m) * 255, (g + m) * 255, (b + m) * 255}
end