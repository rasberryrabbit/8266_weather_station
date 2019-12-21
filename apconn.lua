station_cfg={}
station_cfg.ssid=""
station_cfg.pwd=""

conntry=15
aptry={}
connectionMode=true

conntmr=tmr.create()

function listap(t)
  for ssid,v in pairs(t) do
    local authmode, _, _, _ = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
    if aptry[ssid]==nil and authmode=="0" then
      aptry[ssid]=0
    end
  end
end

conntmr:register(2000,tmr.ALARM_AUTO,function()
    if wifi.sta.getip() == nil then
      MsgSystem("IP unavailable, Wait")
      conntry=conntry-1
      if conntry==0 then
        conntmr:stop()
        
        wifi.sta.getap(0,listap)
        for ssid, id in pairs(aptry) do
          if id==0 then
            aptry[ssid]=1
            wifi.sta.disconnect()
            wifi.setmode(wifi.STATION)
            station_cfg.ssid=ssid
            station_cfg.pwd=""
            wifi.sta.config(station_cfg)
            wifi.sta.connect()
            conntry=15
            conntmr:start()
            break
          end
        end
        -- no network
        if conntry==0 then
          aptry={}
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
          if connectionMode then
            MsgSystem("No Internet.")
            reboottmr=tmr.create()
            reboottmr:register(300000,tmr.ALARM_SINGLE,function()
              node.restart()
            end)
            reboottmr:start()
          end
        end
      end
    else
      conntmr:stop()
      aptry={}
      print("MAC: " .. wifi.ap.getmac())
      MsgSystem("IP: "..wifi.sta.getip())

      pcall(function() sntp.sync(nil,nil,nil,1) end)
      _G.gotip=true
    end
end)

function doWiFiConnect(reconnect)
    conntry=15
    aptry={}
    connectionMode=reconnect
    _G.gotip=false

    if file.exists("eus_params.lua") then
      p=dofile("eus_params.lua")
      station_cfg.ssid=p.wifi_ssid
      station_cfg.pwd=p.wifi_password
      p=nil
    end

    wifi.setmode(wifi.STATION)
    wifi.sta.config(station_cfg)
    wifi.sta.connect()

    conntmr:start()
end

doReconn=0

function tryWiFiConnect(reconn)
  if doReconn~=0 then
    return
  end
  doReconn=1
  if pcall(doWiFiConnect,reconn) then
    wifitmr=tmr.create()
    wifitmr:register(60000,tmr.ALARM_AUTO,function()
      if wifi.getmode()==wifi.STATION and wifi.sta.status()==wifi.STA_GOTIP then
        wifitmr:unregister()
        wifitmr=nil
        doReconn=0
      end
    end)
    wifitmr:start()
  else
    doReconn=0
  end
end

tryWiFiConnect(true)

