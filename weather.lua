
waithttp=tmr.create()
  
function getweather()
  _G.rtm=rtctime.get()
  tm=rtctime.epoch2cal(_G.rtm)
  if tm["year"]==1970 then
    return
  end
  _G.weinfo["h3"]=nil

  _G.to_send="GET /data/2.5/onecall?lat=".._G.lat.."&lon=".._G.lon.."&exclude=minutely,daily,alerts&appid=".._G.appid.."&units=metric HTTP/1.1\r\nHost: api.openweathermap.org\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
  sk:connect(80,"api.openweathermap.org")
end

weathertmr=tmr.create()
weathertmr:register(300000, tmr.ALARM_AUTO, function()
  if waithttp:state()~=nil then
    waithttp:unregister()
  end
  if _G.weinfo["h3"]==nil then
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
    MsgSystem(string.format("%2d/%2d %02d:%02d:%02d",tm["mon"],tm["day"],tm["hour"],tm["min"],tm["sec"]))
    -- draw weather info
    if _G.weinfo["h0"]~=nil and _G.weinfo["h1"]~=nil and _G.weinfo["h2"]~=nil and _G.weinfo["h3"]~=nil then
      disp:setDrawColor(0)
      disp:drawBox(0,10,127,31)
      disp:setDrawColor(1)
      for i=0,2 do
        DrawXBM(i*32+(i*12)+node.random(0,1),64-32,32,32,_G.weinfo["h"..i]["icon"])
        disp:drawStr(i*32+(i*12)+node.random(0,7),20,string.format("%2d",_G.weinfo["h"..i]["temp"]))
        disp:drawStr(i*32+(i*12)+node.random(0,1),30,string.format("%2d%%",_G.weinfo["h"..i]["humi"]))
        disp:drawStr(i*32+(i*12)+21+node.random(0,1),30,string.format("%d",_G.weinfo["h"..i]["wind"]))
        if i>0 then
          local tm = rtctime.epoch2cal(_G.weinfo["h"..i]["wtime"]+_G.timeoffset)
          disp:drawStr(i*32+(i*12)-node.random(0,7),40,tm["hour"]..string.format(",%d",_G.weinfo["h"..i]["pop"]))
        end
        disp:sendBuffer()
      end
      --_G.weinfo={}
	  _G.weinfo["h0"]=nil
	  _G.weinfo["h1"]=nil
	  _G.weinfo["h2"]=nil
      collectgarbage()
      print("ok")
    end
  end)
  indisp=nil
end)

timesynctmr=tmr.create()
timesynctmr:register(1000, tmr.ALARM_AUTO, function()
  local tm = rtctime.epoch2cal(rtctime.get())
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

