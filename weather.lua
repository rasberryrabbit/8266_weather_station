
appid="Your Openweathermap appid"
country="kr"
city="Yeosu"
imgoffset=0

timeoffset=9*3600

function getweather()
    rtm=rtctime.get()+timeoffset
    tm = rtctime.epoch2cal(rtm)
    if tm["year"]==1970 then
      MsgSystem("Wait Time Sync")
      return
    end
    
    to_send ="GET /data/2.5/forecast?q="..city..","..country.."&appid="..appid.." HTTP/1.1\r\nHost: api.openweathermap.org\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
    last_remain=""

    sk=net.createConnection(net.TCP, 0)
    sk:on("receive", function(sck, c)
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
              -- print table
              t=sjson.decode(string.sub(c,spos,epos-2))
              --dayw=str2epoch(t["dt_txt"])
              dayw=tonumber(t["dt"])
              if imgoffset<3 and dayw+3*3600>=rtm and dayw-6*3600<=rtm then
                  tem=t.main["temp"]-273.15
                  --print("temp",tem)
                  hum=t.main["humidity"]
                  --print("humidity",hum)
                  weicon="we_"..string.sub(t.weather[1]["icon"],1,-2).."d.xbm"
                  DrawXBM(imgoffset*40+4,64-32,32,32,weicon)
                  disp:drawStr(imgoffset*40+5,20,string.format("%2.1f",tem))
                  disp:drawStr(imgoffset*40+5,30,string.format("%2d%%",hum))
                  disp:sendBuffer()
                  --print("icon",weicon)
                  --wid=t.weather[1]["id"]
                  --print("id",wid)
                  imgoffset=imgoffset+1
                  print(t["dt_txt"])
                  print("-----")                  
              end
            end
            cpos=i+1
          end
        end
        
    end)
    sk:on("connection", function(sck, c)
        last_remain=""
        imgoffset=0
        -- clear text area
        disp:setDrawColor(0)
        disp:drawBox(0,10,127,31)
        disp:setDrawColor(1)
        sck:send(to_send)
    end)
    sk:connect(80,"api.openweathermap.org")
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
