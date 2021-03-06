--[[
    Copyright (C) 2011 Pau Escrich <pau@dabax.net>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

    The full GNU General Public License is included in this distribution in
    the file called "COPYING".
--]]

local sys = require("luci.sys")
local bmx6json = require("luci.model.bmx6json")

m = Map("bmx6", "bmx6")

-- Getting json and Checking if bmx6-json is avaiable
local options = bmx6json.get("options")
if options == nil or options.OPTIONS == nil then
	 m.message = "bmx6-json plugin is not running or some mistake in luci-bmx6 configuration, check /etc/config/luci-bmx6"
else
	options = options.OPTIONS
end

-- Getting a list of interfaces
local eth_int = luci.sys.net.devices()

-- Getting the most important options from general
local general = m:section(NamedSection,"general","general","General")
general.addremove = false
general:option(Value,"globalPrefix","Global ip prefix","Specify global prefix for interfaces: NETADDR/LENGTH. If you are using IPv6 leave blank to let bmx6 autoassign an ULA IPv6 address.")

if m:get("ipVersion","ipVersion") == "6" then
	general:option(Value,"tun4Address","IPv4 address or range","specify default IPv4 tunnel address and announced range")
end

-- IP section
-- ipVersion section is important, we are allways showing it
local ipV = m:section(NamedSection,"ipVersion","ipVersion","IP options")
ipV.addremove = false
local lipv = ipV:option(ListValue,"ipVersion","IP version")
lipv:value("4","4")
lipv:value("6","6")
lipv.default = "6"

-- rest of ip options are optional, getting them from json
local ipoptions = {}
for _,o in ipairs(options) do
	if o.name == "ipVersion" and o.CHILD_OPTIONS ~= nil then
		ipoptions = o.CHILD_OPTIONS
		break
	end
end

local help = ""
local name = ""
local value = nil

for _,o in ipairs(ipoptions) do
	if o.name ~= nil then
		help = ""
		name = o.name
		if o.help ~= nil then
			help = bmx6json.text2html(o.help)
		end

		if o.syntax ~= nil then
			help = help .. "<br/><strong>Syntax: </strong>" .. bmx6json.text2html(o.syntax)
		end

		if o.def ~= nil then
			help = help .. "<br/><strong> Default: </strong>" .. bmx6json.text2html(o.def)
		end

		value = ipV:option(Value,name,name,help)
		value.optional = true
	end
end

-- Interfaces section
local interfaces = m:section(TypedSection,"dev","Devices","")
interfaces.addremove = true
interfaces.anonymous = true
local intlv = interfaces:option(ListValue,"dev","Device")

for _,i in ipairs(eth_int) do
	intlv:value(i,i)
end

function m.on_commit(self,map)
    local err = sys.call('bmx6 -c --configReload > /tmp/bmx6-luci.err.tmp')
    if err ~= 0 then
        m.message = sys.exec("cat /tmp/bmx6-luci.err.tmp")
    end
end

return m

