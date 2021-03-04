
waithttp=tmr.create()
  
function getweather()
  _G.rtm=rtctime.get()
  tm=rtctime.epoch2cal(_G.rtm)
  if tm["year"]==1970 then
    return
  end
  _G.weinfo["h4"]=nil
  -- current weather
  _G.to_send="GET /data/2.5/weather?lat=".._G.lat.."&lon=".._G.lon.."&appid=".._G.appid.."&units=metric HTTP/1.1\r\nHost: api.openweathermap.org\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
  ck:connect(80,"api.openweathermap.org")

  -- forecast
  -- wait current weather
  waithttp:register(1500,tmr.ALARM_AUTO,function()
    if _G.weinfo["h0"]~=nil then
      waithttp:unregister()
      _G.to_send="GET /data/2.5/forecast?lat=".._G.lat.."&lon=".._G.lon.."&appid=".._G.appid.."&units=metric HTTP/1.1\r\nHost: api.openweathermap.org\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
      sk:connect(80,"api.openweathermap.org")
    end
  end)
  waithttp:start()
  print("getweather ok")
end

weathertmr=tmr.create()
weathertmr:register(300000, tmr.ALARM_AUTO, function()
  if waithttp:state()~=nil then
    waithttp:unregister()
  end
  if _G.weinfo["h4"]==nil then
    tryWiFiConnect(false)  
  end
  if not pcall(getweather) then
    _G.weinfo["h2"]=nil
    --if wifi.sta.status()~=wifi.STA_GOTIP then
      collectgarbage()
    --end
  end
end)

timedisp=tmr.create()
indisp=nil
timedisp:register(1000, tmr.ALARM_AUTO, function()
  if indisp~=nil then
    return
  end
  indisp=1
  pcall(function()
    -- draw local time
    local tm = rtctime.epoch2cal(rtctime.get()+_G.timeoffset)
    MsgSystem(string.format("%04d/%02d/%02d %02d:%02d:%02d",tm["year"],tm["mon"],tm["day"],tm["hour"],tm["min"],tm["sec"]))
    -- draw weather info
    if _G.weinfo["h0"]~=nil and _G.weinfo["h1"]~=nil and _G.weinfo["h2"]~=nil and _G.weinfo["h3"]~=nil then
      disp:setDrawColor(0)
      disp:drawBox(0,10,127,31)
      disp:setDrawColor(1)
      for i=0,2 do
        DrawXBM(i*32+(i*12),64-32,32,32,_G.weinfo["h"..i]["icon"])
        disp:drawStr(i*32+(i*12),20,string.format("%2d",(_G.weinfo["h"..i]["tmin"]+_G.weinfo["h"..i]["tmax"])/2))
        disp:drawStr(i*32+(i*12),30,string.format("%2d%%",_G.weinfo["h"..i]["humi"]))
        disp:drawStr(i*32+(i*12)+21,30,string.format("%dm",_G.weinfo["h"..i]["wind"]))
        if i>0 then
          local tm = rtctime.epoch2cal(_G.weinfo["h"..i]["wtime"]+_G.timeoffset)
          disp:drawStr(i*32+(i*12),40,tm["hour"])
        end
        disp:sendBuffer()
      end
      _G.weinfo={}
      collectgarbage()
      print("ok")
    end
  end)
  indisp=nil
end)

timesynctmr=tmr.create()
timesynctmr:register(1000, tmr.ALARM_AUTO, function()
  tm = rtctime.epoch2cal(rtctime.get())
  if tm["year"]==1970 then
    MsgSystem("Wait Time Sync")
    pcall(function() sntp.sync(nil,nil,nil,1) end)
  else
    timesynctmr:unregister()
    timedisp:start()
    getweather()
    weathertmr:start()
  end
end)

timesynctmr:start()

