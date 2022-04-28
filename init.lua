
if file.exists("dispsetup.lua") then 
    dofile("dispsetup.lua")
	if file.exists("xbmconv.lua") then
	dofile("xbmconv.lua")
	end
    starttmr=tmr.create()
    local tcount=15
    _G.gotip=false
    starttmr:register(1000, tmr.ALARM_AUTO,function()
      if tcount==0 then
        starttmr:unregister()
        if file.exists("apconn.lua") then
          dofile("apconn.lua")
        end
        westart=tmr.create()
        westart:register(1000,tmr.ALARM_AUTO,function()
          if _G.gotip==true then
            westart:unregister()
            if file.exists("weconfig.lua") then
              dofile("weconfig.lua")
            else
              _G.appid=""
              _G.lat=""
              _G.lon=""
              print("please make weconfig.lua")
            end
            if file.exists("weather_sock.lua") then
              dofile("weather_sock.lua")
            end
            if file.exists("weather.lua") then
              dofile("weather.lua")
            end
          end
        end)
        westart:start()
      else
        tcount=tcount-1
      end
      MsgSystem(string.format("Wait %d second(s)",tcount))
    end)
    starttmr:start()
end
