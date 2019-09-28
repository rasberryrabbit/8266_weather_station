station_cfg={}
station_cfg.ssid="Your wifi"
station_cfg.pwd="Your wifi password"
wifi.setmode(wifi.STATION)
wifi.sta.config(station_cfg)
wifi.sta.connect()

conntmr=tmr.create()
conntmr:register(2000,tmr.ALARM_AUTO,function()
    if wifi.sta.getip() == nil then
        MsgSystem("IP unavailable, Wait")
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


