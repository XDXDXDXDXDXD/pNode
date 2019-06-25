local config = require "config"
local req_timer = tmr.create()
-- Helper Functions
function createDevice()
    post_url = config.server.url..'api/devices'
    print(post_url)
    http.post(post_url,
  'Content-Type: application/x-www-form-urlencoded\r\n',
  'name='..config.device.name..'&password='..config.device.key,
  function(code, body, headers)
    if (code < 0) then
      print("err: HTTP request failed")
    else
        ok, t = pcall(sjson.decode,body)
        if ok then
            config.device.token = t["token"]
            tmr.register(req_timer, 5000, tmr.ALARM_AUTO, updateDevice)
            tmr.start(req_timer)
            pcall(print,token)
        else
            print("err: failed to parse JSON response")
        end
    end
  end)
end
function renewToken()
    tmr.stop(req_timer)
    post_url = config.server.url..'api/renew/'..config.device.name
    print(post_url)
    http.post(post_url,
  'Content-Type: application/x-www-form-urlencoded\r\n',
  'name='..config.device.name..'&password='..config.device.key,
  function(code, body, headers)
    if (code < 0) then
      print("err: HTTP request failed")
    else
        print(body)
        ok, t = pcall(sjson.decode,body)
        if ok then
            config.device.token = t["token"]
            pcall(print,token)
            tmr.start(req_timer)
        else
            renewToken()
            print("err: failed to parse JSON response")
        end
    end
  end)
end
function updateDevice()
    get_url = config.server.url..'api/update/'..config.device.name..'?m=0'
    print(get_url)
    print("HTTP GET using token: "..config.device.token)
    http.get(get_url,
    'x-access-token:'..config.device.token..'\r\n',
    function(code, body, headers)
    if (code < 0) then
      print("HTTP request failed")
    else
      ok, t = pcall(sjson.decode,body)
      if ok then
          if(t["auth"] ~= nil and t["auth"] == false) then
            renewToken()
          end
      else
          print("err: failed to parse JSON response")
      end
    end
  end)
end
function motionDetected()
    get_url = config.server.url..'api/update/'..config.device.name..'?m=1'
    print(get_url)
    print("HTTP GET using token: "..config.device.token)
    http.get(get_url,
    'x-access-token:'..config.device.token..'\r\n',
    function(code, body, headers)
    if (code < 0) then
      print("HTTP request failed")
    else
      ok, t = pcall(sjson.decode,body)
      if ok then
          if(t["auth"] ~= nil and t["auth"] == false) then
            renewToken()
          end
      else
          print("err: failed to parse JSON response")
      end
    end
  end)
end
function startDevice()
    print("Device "..config.device.name.." bootstraped")
    tmr.register(req_timer, 5000, tmr.ALARM_AUTO, updateDevice)
    tmr.start(req_timer)
end
function blinkLED()
    gpio.write(1, gpio.HIGH)
    tmr.delay(1000 * 1000) --1sec
    gpio.write(1, gpio.LOW)
end


--end of Helper Functions
last_state = 1
pin = 2 --GPIO4

gpio.mode(pin, gpio.INPUT)
gpio.mode(1, gpio.OUTPUT) --GPIO5

tmr.alarm(0,100, 1, function()
    if gpio.read(pin) ~= last_state then
		last_state = gpio.read(pin)
        if last_state == 1 then
            motionDetected()
            blinkLED()
        end
    end
end)

if (config.device.token == "") then
    createDevice()
else
    startDevice()
end
