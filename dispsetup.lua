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
  disp:setDrawColor(0)
  disp:drawBox(0,0,128,u8g2_fontHeight+1)
  disp:setDrawColor(1)
  disp:drawStr(0,9,str)
  disp:sendBuffer()
end

--[[function DrawXBM(x,y,w,h,str)
  if file.exists(str) then
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
      buf=nil
      disp:drawXBM(x,y,w,h,obuf)
      obuf=nil
    end
  else
    disp:drawBox(x,y,w,h)
    disp:drawStr(x,y,'?')
    disp:sendBuffer()
  end
end]]--

-- draw GIMP XBM file
function DrawXBM(x,y,w,h,str)
  if file.exists(str) then
    local obuf=""
    local bpl=math.ceil(w/8)
    local xx=0
    local yy=0
    local buf=""
    f=file.open(str,"r")
    buf=f:readline()
    while buf~=nil do
      for wv in string.gmatch(buf,"0x[^%s,]+") do
        v=bit.band(bit.bnot(tonumber(wv,16)),0xff)
        obuf=obuf..string.char(v)
        xx=xx+1
        if xx>=bpl then
          disp:drawXBM(x,y+yy,w,1,obuf)
          obuf=""
          xx=0
          yy=yy+1
          if yy>=h then
            break
          end
        end
      end
      buf=f:readline()
    end
    f:close()
  else
    disp:drawBox(x,y,w,h)
    disp:drawStr(x,y,'?')
    disp:sendBuffer()
  end
end

--[[
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
]]--

MsgSystem("Display Init Success")