if file.list()["dispsetup.lua"]~=nil then 
  dofile("dispsetup.lua")
end
starttmr=tmr.create()
tcount=15
starttmr:register(1000, tmr.ALARM_AUTO,function()
  if tcount==0 then
    starttmr:unregister()
    if file.list()["apconn.lua"]~=nil then
      dofile("apconn.lua")
    end
  else
    tcount=tcount-1
  end
  MsgSystem(string.format("Wait %d second(s)",tcount))
end)
starttmr:start()
