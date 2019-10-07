station_cfg={}
station_cfg.ssid=""
station_cfg.pwd=""
if file.list()["eus_params.lua"] then
  p=dofile("eus_params.lua")
  station_cfg.ssid=p.wifi_ssid
  station_cfg.pwd=p.wifi_password
end

wifi.setmode(wifi.STATION)
wifi.sta.config(station_cfg)
wifi.sta.connect()

conntry=15
aptried={}

conntmr=tmr.create()

reboottmr=tmr.create()
reboottmr:register(300000,tmr.ALARM_SINGLE,function()
  node.restart()
end)
    
function listap(t)
  for ssid,v in pairs(t) do
    local authmode, _, _, _ = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
    if (not aptried[ssid]) and authmode=="0" then
      aptried[ssid]=0
      wifi.sta.disconnect()
      wifi.setmode(wifi.STATION)
      station_cfg.ssid=ssid
      station_cfg.pwd=""
      wifi.sta.config(station_cfg)
      wifi.sta.connect()
      conntmr:start()
      conntry=15
      break
    end
  end
  if conntry==0 then
    MsgSystem("No Internet.")
    wifi.sta.disconnect()
    wifi.setmode(wifi.STATIONAP)
    wifi.ap.config({ssid="Weather_"..node.chipid(), auth=wifi.OPEN})
    enduser_setup.manual(true)
    enduser_setup.start(
      function()
        print("WiFi as:" .. wifi.sta.getip())
        --node.restart()
      end,
      function(err, str)
        print("Err #" .. err .. ": " .. str)
      end
    )
    reboottmr:start()
  end
end

conntmr:register(2000,tmr.ALARM_AUTO,function()
    if wifi.sta.getip() == nil then
        MsgSystem("IP unavailable, Wait")
        conntry=conntry-1
        if conntry==0 then
          conntmr:stop()
          
          wifi.sta.getap(0,listap)
        end
    else
        conntmr:unregister()
        print("WiFi mode: " .. wifi.getmode())
        print("MAC: " .. wifi.ap.getmac())
        MsgSystem("IP: "..wifi.sta.getip())

        sntp.sync(nil,nil,nil,1)

        if file.list()["weather.lua"]~=nil then
          dofile("weather.lua")
        end
    end
end)
conntmr:start()


