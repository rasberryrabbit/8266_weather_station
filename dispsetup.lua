-- SDA and SCL can be assigned freely to available GPIOs
id  = 0
sda = 1
scl = 2
i2c.setup(id, sda, scl, i2c.FAST)
-- set up the display
sla = 0x3c
disp = u8g2.ssd1306_i2c_128x64_noname(id, sla)
disp:setFont(u8g2.font_6x10_tf)

u8g2_fontHeight=10

function MsgSystem(str)
  local w=disp:getStrWidth(str)
  disp:setDrawColor(0)
  disp:drawBox(0,0,128,u8g2_fontHeight+1)
  disp:setDrawColor(1)
  disp:drawStr(0,9,str)
  disp:sendBuffer()
end

function DrawXBM(x,y,w,h,str)
  if file.list()[str]~=nil then
      f=file.open(str,"r")
      local buf=f:read()
      f:close()
      local obuf=""
      i,j=string.find(buf,"%s+\=%s+{")
      if i~=nil then
        local buf=string.sub(buf,j)
        for wv in string.gmatch(buf,"0x[^%s,\,]+") do
          v=bit.band(bit.bnot(tonumber(wv,16)),0xff)
          obuf=obuf..string.char(v)
        end
        buf=""
        disp:drawXBM(x,y,w,h,obuf)
        obuf=""
      end
  else
    disp:drawBox(x,y,w,h)
    disp:sendBuffer()
    print(str)
  end
end

function unix2date(t)
    local jd, f, e, h, y, m, d
    jd = t / 86400 + 2440588
    f = jd + 1401 + (((4 * jd + 274277) / 146097) * 3) / 4 - 38
    e = 4 * f + 3
    h = 5 * ((e % 1461) / 4) + 2
    d = (h % 153) / 5 + 1
    m = (h / 153 + 2) % 12 + 1
    y = e / 1461 - 4716 + (14 - m) / 12
    return t%86400/3600, t%3600/60, t%60, y, m, d, jd%7+1
end

function date2unix(y, m, d, h, n, s)
    local a, jd
    a = (14 - m) / 12
    y = y + 4800 - a
    m = m + 12*a - 3
    jd = d + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
    return (jd - 2440588)*86400 + h*3600 + n*60 +s
end

function str2epoch(s)
    local y,m,d,h,mi,n=string.match(s,"(%d+)-(%d+)-(%d+)%s+(%d+):(%d+):(%d+)")
    ep=date2unix(y,m,d,h,mi,n)
    return ep
end

MsgSystem("Display Init Success")