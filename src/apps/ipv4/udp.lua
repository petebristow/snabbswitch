module(..., package.seeall)

local ipv4 = require("lib.protocol.ipv4")
local udp = require("lib.protocol.udp")
local datagram = require("lib.protocol.datagram")

Encap = { }
function Encap:new (arg)
   local conf = config.parse_app_arg(arg)
   local ip = ipv4:new({ dst = ipv4:pton(conf.dst), src = ipv4:pton(conf.src), protocol=17, ttl=255 })
   local udp = udp:new({ src_port = conf.src_port, dst_port = conf.dst_port })
   return setmetatable({ ip = ip, udp = udp }, { __index = Encap })
end
function Encap:push ()
   local input = self.input.input
   local output = self.output.output
   for _=1,link.nreadable(input) do
      local p = link.receive(input)
      local d = datagram:new(p)
      self.ip:total_length(p.length + udp:sizeof() + ipv4:sizeof())
      self.udp:length(p.length + udp:sizeof())
      d:push(self.udp)
      d:push(self.ip)
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
      packet.shiftleft(p, ipv4:sizeof() + udp:sizeof())
      link.transmit(output, p)
   end
end
