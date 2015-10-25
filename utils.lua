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
    if g == gob then
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