
appid=""
lat=""
lon=""
to_send=""

if file.list()["weconfig.lua"] then
  dofile("weconfig.lua")
end
imgoffset=0

timeoffset=9*3600
weinfo={}

function HttpGetHeader(buf)
  j=0
  repeat
    ipos=j+1
    i,j = string.find(buf,"\n",ipos)
    if i==nil or ipos==j then
      return ipos
    end
  until i==nil
  return nil
end

function getweather()
    rtm=rtctime.get()
    tm=rtctime.epoch2cal(rtm)
    if tm["year"]==1970 then
      return
    end
    
    -- current weather
    ck_length=-1

    ck=net.createConnection(net.TCP, 0)
    ck:on("receive", function(sck, cwinfo)
        -- strip header
        if ck_length==-1 then
          i=HttpGetHeader(cwinfo)
          if i~=nil then
            ck_length=tonumber(string.match(cwinfo,"Content-Length:%s+(%d+)")) --string.sub(cwinfo,1,i-1)
            cwinfo=string.sub(cwinfo,i,-1)
          end
        end
        local t=sjson.decode(cwinfo)
        temmin=t.main["temp_min"]
        temmax=t.main["temp_max"]
        hum=t.main["humidity"]
        weicon="we_"..string.sub(t.weather[1]["icon"],1,-1)..".xbm"
        weinfo["h0"]={tempmin=temmin, tempmax=temmax, humi=hum, icon=weicon, wtime=rtm}
        timeoffset=t["timezone"]
        --sck:close()
        print("-current-")
    end)
    ck:on("connection", function(sck, cwinfo)
        ck_length=-1
        sck:send(to_send)
        to_send=nil
    end)
    to_send="GET /data/2.5/weather?lat="..lat.."&lon="..lon.."&appid="..appid.."&units=metric HTTP/1.1\r\nHost: api.openweathermap.org\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
    ck:connect(80,"api.openweathermap.org")

    -- forecast
    sk_length=-1

    sk=net.createConnection(net.TCP, 0)
    sk:on("receive", function(sck, c)
        if weinfo["h2"] then
          c=nil
          return
        end
        if sk_length==-1 then
          i=HttpGetHeader(c)
          if i~=nil then
            sk_length=tonumber(string.match(c,"Content-Length:%s+(%d+)")) --string.sub(c,1,i-1)
            c=string.sub(c,i,-1)
          end
        end
        c=last_remain..c
        last_remain=""
        if imgoffset>2 then
          c=nil
          return
        end
        cpos=1
        spos=1
        epos=nil
        slen=string.len(c)
        local i,j
        while cpos<=slen do
          i, j = string.find(c,"\{\"dt\"",cpos)
          if i==nil then
            i, j = string.find(c,"\,\"city\"",cpos)
          end
          if i==nil then           
            if epos==nil then
              epos=1
            end
            last_remain=string.sub(c,epos)
            break
          else
            spos=epos
            epos=i
            if spos~=nil then
              local t=sjson.decode(string.sub(c,spos,epos-2))
              dayw=tonumber(t["dt"])
              if imgoffset<3 and dayw>rtm and dayw-6*3600<=rtm then
                  datastr=string.format("h%d",imgoffset)
                  temmin=t.main["temp_min"]
                  temmax=t.main["temp_max"]
                  hum=t.main["humidity"]
                  weicon="we_"..string.sub(t.weather[1]["icon"],1,-1)..".xbm"
                  weinfo[datastr]={tempmin=temmin, tempmax=temmax, humi=hum, icon=weicon, wtime=dayw}
                  imgoffset=imgoffset+1
                  print("-forcast-")
              end
            end
            cpos=i+1
          end
        end
    end)
    sk:on("connection", function(sck, c)
        last_remain=""
        sk_length=-1
        imgoffset=1
        sck:send(to_send)
        to_send=nil
    end)

    -- wait current weather
    waithttp=tmr.create()
    waithttp:register(1000,tmr.ALARM_AUTO,function()
      if weinfo["h0"] then
        waithttp:unregister()
        to_send="GET /data/2.5/forecast?lat="..lat.."&lon="..lon.."&appid="..appid.."&units=metric HTTP/1.1\r\nHost: api.openweathermap.org\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
        sk:connect(80,"api.openweathermap.org")
      end
    end)
    waithttp:start()
end

weathertmr=tmr.create()
weathertmr:register(300000, tmr.ALARM_AUTO, function()
  getweather()
end)

timedisp=tmr.create()
timedisp:register(1000, tmr.ALARM_AUTO, function()
  -- draw local time
  local tm = rtctime.epoch2cal(rtctime.get()+timeoffset)
  MsgSystem(string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
  -- draw weather info
  if weinfo["h0"] and weinfo["h1"] and weinfo["h2"] then
    timedisp:stop()
    --collectgarbage()
    disp:setDrawColor(0)
    disp:drawBox(0,10,127,31)
    disp:setDrawColor(1)
    for i=0,2 do
        local datastr=string.format("h%d",i)
        DrawXBM(i*32+(i*12),64-32,32,32,weinfo[datastr]["icon"])
        disp:drawStr(i*32+(i*12),20,string.format("%2.0d/%2.0d",weinfo[datastr]["tempmin"],weinfo[datastr]["tempmax"]))
        disp:drawStr(i*32+(i*12),30,string.format("%2d%%",weinfo[datastr]["humi"]))
        if i>0 then
          local tm = rtctime.epoch2cal(weinfo[datastr]["wtime"]+timeoffset)
          disp:drawStr(i*32+(i*12),40,string.format("%02d",tm["hour"]))
        end
        disp:sendBuffer()
    end
    weinfo={}
    timedisp:start()
  end
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
