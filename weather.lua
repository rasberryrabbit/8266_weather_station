
function getweather()
  _G.rtm=rtctime.get()
  tm=rtctime.epoch2cal(_G.rtm)
  if tm["year"]==1970 then
    return
  end
  
  -- current weather
  _G.to_send="GET /data/2.5/weather?lat=".._G.lat.."&lon=".._G.lon.."&appid=".._G.appid.."&units=metric HTTP/1.1\r\nHost: api.openweathermap.org\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
  ck:connect(80,"api.openweathermap.org")

  -- forecast
  -- wait current weather
  waithttp=tmr.create()
  waithttp:register(1500,tmr.ALARM_AUTO,function()
    if _G.weinfo["h0"] then
      waithttp:unregister()
      _G.to_send="GET /data/2.5/forecast?lat=".._G.lat.."&lon=".._G.lon.."&appid=".._G.appid.."&units=metric HTTP/1.1\r\nHost: api.openweathermap.org\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
      sk:connect(80,"api.openweathermap.org")
    end
  end)
  waithttp:start()
end

weathertmr=tmr.create()
weathertmr:register(300000, tmr.ALARM_AUTO, function()
  if not pcall(getweather) then
    _G.weinfo["h2"]=nil
    if wifi.getmode()==wifi.STATION and wifi.sta.status()~=wifi.STA_GOTIP then
      tryWiFiConnect(false)
    end
  end
end)

timedisp=tmr.create()
indisp=false
timedisp:register(1500, tmr.ALARM_AUTO, function()
  if indisp then
    return
  end
  indisp=true
  pcall(function()
    -- draw weather info
    if _G.weinfo["h0"] and _G.weinfo["h1"] and _G.weinfo["h2"] then
      disp:setDrawColor(0)
      disp:drawBox(0,10,127,31)
      disp:setDrawColor(1)
      for i=0,2 do
        DrawXBM(i*32+(i*12),64-32,32,32,_G.weinfo["h"..i]["icon"])
        disp:drawStr(i*32+(i*12),20,string.format("%2d",(_G.weinfo["h"..i]["tmin"]+_G.weinfo["h"..i]["tmax"])/2))
        disp:drawStr(i*32+(i*12),30,string.format("%2d%% %.2dm",_G.weinfo["h"..i]["humi"],_G.weinfo["h"..i]["wind"]))
        if i>0 then
          local tm = rtctime.epoch2cal(_G.weinfo["h"..i]["wtime"]+_G.timeoffset)
          disp:drawStr(i*32+(i*12),40,string.format("%02d",tm["hour"]))
        end
        _G.weinfo["h"..i]=nil
        MsgUpdate()
      end
      --_G.weinfo={}
      --collectgarbage()
    end
    -- draw local time
    local tm = rtctime.epoch2cal(rtctime.get()+_G.timeoffset)
    disp:setDrawColor(0)
    disp:drawBox(0,0,128,10+1)
    disp:setDrawColor(1)
    disp:drawStr(0,9,string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
    MsgUpdate()
  end)
  indisp=false
end)

timesynctmr=tmr.create()
timesynctmr:register(1000, tmr.ALARM_AUTO, function()
  tm = rtctime.epoch2cal(rtctime.get())
  if tm["year"]==1970 then
    MsgSystem("Wait Time Sync")
    MsgUpdate()
    pcall(function() sntp.sync(nil,nil,nil,1) end)
  else
    timesynctmr:unregister()
    timedisp:start()
    getweather()
    weathertmr:start()
  end
end)

timesynctmr:start()

