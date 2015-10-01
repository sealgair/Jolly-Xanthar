function round(num)
   if num >= 0 then
     return math.floor(num+.5)
   else
     return math.ceil(num-.5)
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
  return t[# t]
end
