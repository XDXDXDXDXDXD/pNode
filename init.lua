
local config = require "config"

--init.lua
wifi.setmode(wifi.STATION)
wifi.sta.config {ssid=config.wifi.ssid, pwd=config.wifi.pwd}
wifi.sta.connect()
tmr.alarm(1, 1000, 1, function()
	if wifi.sta.getip() == nil then
		print(config.device.name .. " is trying to connecto to " .. config.wifi.ssid)
	else
		tmr.stop(1)
		print(wifi.sta.getip())
		dofile ("app.lua")
	end
end)
