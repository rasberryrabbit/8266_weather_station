_G.ContLen=-1
_G.last_remain=""
_G.timeoffset=9*3600
_G.to_send=""
_G.imgoffset=0
_G.weinfo={}
_G.rtm=rtctime.get()

ck=net.createConnection(net.TCP, 0)
ck:on("receive", function(sck, cwinfo)
  -- strip header
  if _G.ContLen==-1 then
    i=nil
    jh=0
    repeat
      iposh=jh+1
      ih,jh = string.find(cwinfo,"\n",iposh)
      if ih==nil or iposh==jh then
        i=iposh
        break
      end
    until ih==nil

    if i~=nil then
      _G.ContLen=tonumber(string.match(cwinfo,"Content%-Length:%s+(%d+)"))
      cwinfo=string.sub(cwinfo,i,-1)
    end
  end
  local t=sjson.decode(cwinfo)
  temmin=t.main["temp_min"]
  temmax=t.main["temp_max"]
  windspd=t.wind["speed"]
  hum=t.main["humidity"]
  weicon="we_"..string.sub(t.weather[1]["icon"],1,-1)..".xbm"
  _G.weinfo["h0"]={tmin=temmin, tmax=temmax, humi=hum, icon=weicon, wtime=_G.rtm, wind=windspd}
  _G.timeoffset=t["timezone"]
  --print("Current")
  cwinfo=nil
end)
ck:on("connection", function(sck, cwinfo)
  _G.weinfo["h0"]=nil
  _G.last_remain=""
  _G.ContLen=-1
  sck:send(_G.to_send)
  _G.to_send=nil
end)
ck:on("disconnection", function(sck) print("ck disconnect") end)

sk=net.createConnection(net.TCP, 0)
sk:on("receive", function(sck, c)
    if _G.ContLen==-1 then
      i=nil
      jh=0
      repeat
        iposh=jh+1
        ih,jh = string.find(c,"\n",iposh)
        if ih==nil or iposh==jh then
          i=iposh
          break
        end
      until ih==nil

      if i~=nil then
        _G.ContLen=tonumber(string.match(c,"Content%-Length:%s+(%d+)"))
        c=string.sub(c,i,-1)
      end
    end
    ilen=string.len(c)
    _G.ContLen=_G.ContLen-ilen
    if _G.ContLen<=0 then
      _G.weinfo["h3"]=1
    end
    if _G.weinfo["h2"]~=nil then
      c=nil
      return
    end
    c=_G.last_remain..c
    _G.last_remain=""
    if _G.imgoffset>2 then
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
        _G.last_remain=string.sub(c,epos)
        break
      else
        spos=epos
        epos=i
        if spos~=nil then
          local t=sjson.decode(string.sub(c,spos,epos-2))
          dayw=tonumber(t["dt"])
          if _G.imgoffset<3 and dayw>_G.rtm and dayw-6*3600<=_G.rtm then
              temmin=t.main["temp_min"]
              temmax=t.main["temp_max"]
              windspd=t.wind["speed"]
              hum=t.main["humidity"]
              weicon="we_"..string.sub(t.weather[1]["icon"],1,-1)..".xbm"
              _G.weinfo["h".._G.imgoffset]={tmin=temmin, tmax=temmax, humi=hum, icon=weicon, wtime=dayw, wind=windspd}
              _G.imgoffset=_G.imgoffset+1
              --print("Forecast")
          end
        end
        cpos=i+1
      end
    end
    c=nil
end)
sk:on("connection", function(sck, c)
  _G.weinfo["h1"]=nil
  _G.weinfo["h3"]=nil
  _G.last_remain=""
  _G.ContLen=-1
  _G.imgoffset=1
  sck:send(_G.to_send)
  _G.to_send=nil
end)
sk:on("disconnection", function(sck) print("sk disconnect") end)

  