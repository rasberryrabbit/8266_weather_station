XBMList = {'we_01d.xbm','we_01n.xbm','we_02d.xbm','we_02n.xbm','we_03d.xbm','we_03n.xbm','we_04d.xbm','we_04n.xbm',
           'we_09d.xbm','we_09n.xbm','we_10d.xbm','we_10n.xbm','we_11d.xbm','we_11n.xbm','we_13d.xbm','we_13n.xbm',
		   'we_50d.xbm','we_50n.xbm'}

function ConvXBM(w,h,str)
  if file.exists(str) then
    nf=string.gsub(str,".xbm",".bin")
    if file.exists(nf) then
	  return
	end
    fo=file.open(nf,"w")
    local obuf=""
    local bpl=math.ceil(w/8)
    local xx=0
    local yy=0
    local buf
    f=file.open(str,"r")
    buf=f:readline()
    while buf~=nil do
      for wv in string.gmatch(buf,"0x[^%s,]+") do
        v=bit.band(bit.bnot(tonumber(wv,16)),0xff)
        obuf=obuf..string.char(v)
        xx=xx+1
        if xx>=bpl then
		  fo:write(obuf)
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
    f=nil
	fo:close()
	fo=nil
  end
end

print("Convert XBM Files")
MsgSystem("Convert XBM Files")
for k,v in pairs(XBMList) do
  ConvXBM(32,32,v)
end
XBMList=nil