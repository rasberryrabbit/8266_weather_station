station_cfg={}
station_cfg.ssid="Your wifi"
station_cfg.pwd="Your wifi password"
wifi.setmode(wifi.STATION)
wifi.sta.config(station_cfg)
wifi.sta.connect()

conntry=15
aptried={}

conntmr=tmr.create()

function listap(t)
  for ssid,v in pairs(t) do
    local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
    if (not aptried[ssid]) and authmode=="0" then
      aptried.insert(ssid,0)
      wifi.setmode(wifi.STATION)
      station_cfg.ssid=ssid
      station_cfg.pwd=""
      wifi.sta.config(station_cfg)
      wifi.sta.connect()
      conntmr:start()
      conntry=30
      break
    end
  end
  if conntry==0 then
    MsgSystem("No Internet")
  end
end

conntmr:register(2000,tmr.ALARM_AUTO,function()
    if wifi.sta.getip() == nil then
        MsgSystem("IP unavailable, Wait")
        conntry=conntry-1
        if conntry==0 then
          conntmr:stop()
          
          -- try reconnect other AP
          wifi.disconnect()
          wifi.setmode(wifi.STATIONAP)
          wifi.sta.getap(0,listap)
        end
    else
        conntmr:stop()
        conntmr:unregister()
        print("ESP8266 mode is: " .. wifi.getmode())
        print("The module MAC address is: " .. wifi.ap.getmac())
        MsgSystem("IP: "..wifi.sta.getip())
        
        local udp_response = wifi.sta.getip().."\n"..string.format("%x",node.chipid()).."\nWEATHER\n"
        udp50k = net.createUDPSocket()
        udpcasttmr = tmr.create()
        udpcasttmr:register(3000, tmr.ALARM_AUTO, function()
          udp50k:send(50000, wifi.sta.getbroadcast(), udp_response)
        end)
        udpcasttmr:start()
        
        sntp.sync(nil,nil,nil,1)
        
        if file.list()["weather.lua"]~=nil then
          dofile("weather.lua")
        end
    end
end)
conntmr:start()


