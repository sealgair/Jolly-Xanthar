--require 'utils'
--require 'position'
--require 'star'
--
local sector = ...
--local sector = Sector.deserialize(sector)
local channel = love.thread.getChannel("stars")

--local starBatch = {}
--local batchSize = 1

channel.push('started')
--sector:makeStars(function(i, star)
--  table.insert(starBatch, star:serialize())
--  if #starBatch >= batchSize then
--    channel.push(starBatch)
--    starBatch = {}
--  end
--end)