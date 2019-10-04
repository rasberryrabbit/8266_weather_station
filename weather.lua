
appid="Your Openweathermap appid"
country="Your country"
city="Your City"
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
    tm = rtctime.epoch2cal(rtm)
    if tm["year"]==1970 then
      MsgSystem("Wait Time Sync")
      return
    end
    
    -- current weather
    ck_to_send ="GET /data/2.5/weather?q="..city..","..country.."&appid="..appid.."&units=metric HTTP/1.1\r\nHost: api.openweathermap.org\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
    last_remain=""

    ck_header=""
    ck=net.createConnection(net.TCP, 0)
    ck:on("receive", function(sck, cwinfo)
        if ck_header=="" then
          i=HttpGetHeader(cwinfo)
          if i~=nil then
            ck_header=" " --string.sub(cwinfo,1,i-1)
            cwinfo=string.sub(cwinfo,i,-1)
          end
        end
        local t=sjson.decode(cwinfo)
        tem=(t.main["temp_max"]+t.main["temp_min"])/2
        hum=t.main["humidity"]
        weicon="we_"..string.sub(t.weather[1]["icon"],1,-2).."d.xbm"
        weinfo["h0"]={temp=tem, humi=hum, icon=weicon}
        print("-current-")
    end)
    ck:on("connection", function(sck, cwinfo)
        last_remain=""
        ck_header=""
        sck:send(ck_to_send)
    end)
    ck:connect(80,"api.openweathermap.org")
    
    -- forecast
    sk_to_send ="GET /data/2.5/forecast?q="..city..","..country.."&appid="..appid.."&units=metric HTTP/1.1\r\nHost: api.openweathermap.org\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
    last_remain=""

    sk_header=""
    sk=net.createConnection(net.TCP, 0)
    sk:on("receive", function(sck, c)
        if sk_header=="" then
          i=HttpGetHeader(c)
          if i~=nil then
            sk_header=" " --string.sub(c,1,i-1)
            c=string.sub(c,i,-1)
          end
        end
        c=last_remain..c
        cpos=1
        spos=1
        epos=nil
        slen=string.len(c)
        local i,j
        while cpos<slen do
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
              if imgoffset<3 and dayw>rtm and dayw-6*3600<rtm then
                  datastr=string.format("h%d",imgoffset)
                  tem=(t.main["temp_max"]+t.main["temp_min"])/2
                  hum=t.main["humidity"]
                  weicon="we_"..string.sub(t.weather[1]["icon"],1,-2).."d.xbm"
                  weinfo[datastr]={temp=tem, humi=hum, icon=weicon}
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
        sk_header=""
        imgoffset=1
        sck:send(sk_to_send)
    end)
    -- wait current weather
    waithttp=tmr.create()
    waithttp:register(1000,tmr.ALARM_AUTO,function()
      if weinfo["h0"] then
        waithttp:unregister()
        ck:close()        
        sk:connect(80,"api.openweathermap.org")
      end
    end)
    waithttp:start()

    -- draw weather info
    drawtimer=tmr.create()
    drawtimer:register(1000,tmr.ALARM_AUTO,function()
      if weinfo["h0"] and weinfo["h1"] and weinfo["h2"] then
        sk:close()
        drawtimer:unregister()
        disp:setDrawColor(0)
        disp:drawBox(0,10,127,31)
        disp:setDrawColor(1)
        for i=0,2 do
            datastr=string.format("h%d",i)
            DrawXBM(i*40+4,64-32,32,32,weinfo[datastr]["icon"])
            disp:drawStr(i*40+5,20,string.format("%2.1f",weinfo[datastr]["temp"]))
            disp:drawStr(i*40+5,30,string.format("%2d%%",weinfo[datastr]["humi"]))
            disp:sendBuffer()
        end
        weinfo={}
      end
    end)
    drawtimer:start()
end

weathertmr=tmr.create()
weathertmr:register(300000, tmr.ALARM_AUTO, function()
  getweather()
end)

timedisp=tmr.create()
timedisp:register(1000, tmr.ALARM_AUTO, function()
  tm = rtctime.epoch2cal(rtctime.get()+timeoffset)
  MsgSystem(string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
end)

timesynctmr=tmr.create()
timesynctmr:register(1000, tmr.ALARM_AUTO, function()
    tm = rtctime.epoch2cal(rtctime.get())
    if tm["year"]==1970 then
      MsgSystem("Wait Time Sync")
    else
      timesynctmr:unregister()
      timedisp:start()
      getweather()      
    end
end)

timesynctmr:start()
weathertmr:start()
