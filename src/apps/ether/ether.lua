module(..., package.seeall)

local datagram = require("lib.protocol.datagram")
local ethernet = require("lib.protocol.ethernet")
local link = require("core.link")

Swap = {}
function Swap:new (arg)
   local conf = config.parse_app_arg(arg)
   if conf.src then conf.src = ethernet:pton(conf.src) end
   if conf.dst then conf.dst = ethernet:pton(conf.dst) end
   return setmetatable(conf, {__index = Swap})
end
function Swap:push ()
   local input = self.input.input
   local output = self.output.output
   for _=1,link.nreadable(input) do
      local p = link.receive(input)
      local hdr = ethernet:new_from_mem(p.data, 14)
      if self.src then hdr:src(self.src) end
      if self.dst then hdr:dst(self.dst) end
      if self.type then hdr:type(self.type) end

      link.transmit(output, p)
   end
end

Encap = {}
function Encap:new (arg)
   local conf = config.parse_app_arg(arg)
   return setmetatable({
      hdr = ethernet:new({
         src = ethernet:pton(conf.src),
         dst = ethernet:pton(conf.dst),
         type = conf.type
      })
   }, {__index = Encap})
end
function Encap:push ()
   local input = self.input.input
   local output = self.output.output
   for _=1,link.nreadable(input) do
      local p = link.receive(input)
      local d = datagram:new(p)
      d:push(self.hdr)
      link.transmit(output, p)
   end
end

Decap = { }
function Decap:new ()
   return setmetatable({}, { __index = Decap })
end
function Decap:push ()
   local input = self.input.input
   local output = self.output.output
   for _=1,link.nreadable(input) do
      packet.shiftleft(p, ether:sizeof())
      link.transmit(output, p)
   end
end
