_G.ContLen=-1
_G.last_remain=""
_G.timeoffset=9*3600
_G.to_send=""
_G.imgoffset=0
_G.weinfo={}
_G.rtm=rtctime.get()

local lastdt=0

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
        if _G.ContLen==nil then
          _G.ContLen=8192
        end
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
    slen=string.len(c)
    stimezone=string.match(c,"timezone_offset\":(%d+)")
    if stimezone~=nil then
      _G.timeoffset=tonumber(stimezone)
    end
    local i,j
    while cpos<=slen do
      i = string.find(c,"\{\"dt\":",cpos)
      j = string.find(c,"\}\]",cpos)
      if i==nil or j==nil or i>=j then           
        _G.last_remain=string.sub(c,cpos)
        break
      else
        sdayw=string.match(c,"dt\":(%d+)",i)
        dayw=tonumber(sdayw)
        if lastdt<dayw and _G.imgoffset<3 and dayw>=_G.rtm and dayw-6*3600<=_G.rtm then
          stemp=string.match(c,"temp\":([0-9%.%-]+)",i)
          ttemp=tonumber(stemp)
          swind=string.match(c,"wind_speed\":([0-9%.]+)",i)
          windspd=tonumber(swind)
          shum=string.match(c,"humidity\":(%d+)",i)
          hum=tonumber(shum)
          sicon=string.match(c,"icon\":\"([^\"]+)\"",i)
          weicon="we_"..sicon..".bin"
          spop=string.match(c,"pop\":([0-9%.]+)",i)
          vpop=tonumber(spop)
          if vpop~=nil then
            vpop=vpop*100
            if vpop==100 then
              vpop=99
            end
          end
          _G.weinfo["h".._G.imgoffset]={temp=ttemp, humi=hum, icon=weicon, wtime=dayw, wind=windspd, pop=vpop}
          _G.imgoffset=_G.imgoffset+1
          --print("Forecast")
        end
        lastdt=dayw
        cpos=j+2
      end
    end
    c=nil
end)
sk:on("connection", function(sck, c)
  _G.weinfo["h0"]=nil
  _G.weinfo["h3"]=nil
  _G.last_remain=""
  _G.ContLen=-1
  _G.imgoffset=0
  lastdt=0
  _G.rtm=rtctime.get()
  sck:send(_G.to_send)
  _G.to_send=nil
end)
  