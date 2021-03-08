-- mx.samples v0.2.1
-- download and play samples
--
-- llllllll.co/t/mxsamples
--
-- 1. plug in a midi controller
-- 2. select a sample.
-- 3. profit.

local UI=require "ui"
mxsamples=include("mx.samples/lib/mx.samples")

engine.name="MxSamples"
skeys=nil
uilist=nil
downloading=false
download_available=0
instrument_current=1
available_instruments={
  {name="alto sax choir",size=17*1.5},
  {name="box violin",size=8*1.5},
  {name="cello",size=22*1.5},
  {name="cello pad",size=4*1.5},
  {name="dictaphone",size=18},
  {name="discord choir",size=18},
  {name="ghost piano",size=40*1.5},
  {name="harmonium",size=535},
  {name="kawai felt",size=62.8*2},
  {name="steinway model b",size=128*1.5},
  {name="tatak piano",size=127*1.5},
}

function init()
  skeys=mxsamples:new()
  update_uilist()

  for _,dev in pairs(midi.devices) do
    if dev.port~=nil then
      m=midi.connect(dev.port)
      m.event=function(data)
        if available_instruments[instrument_current].active~=true then
          do return end
        end
        if (data[1]==144 or data[1]==128) then
          tab.print(data)
          if data[1]==144 and data[3] > 0 then
            skeys:on({name=available_instruments[instrument_current].id,midi=data[2],velocity=data[3]})
          elseif data[1]==128 or data[3] == 0 then
            skeys:off({name=available_instruments[instrument_current].id,midi=data[2]})
          end
        end
      end
    end
  end

  print("available instruments: ")
  tab.print(skeys:list_instruments())
  clock.run(redraw_clock) 
end

function update_uilist()
  -- check if downloaded

  items={}
  for i,a in ipairs(available_instruments) do
    available_instruments[i].id=string.gsub(a.name," ","_")
    local files_for=os.capture("ls /home/we/dust/code/mx.samples/samples/"..available_instruments[i].id.."/*.wav")
    local downloaded=false
    if string.find(files_for,".wav") then
      downloaded=true
    end
    local s=a.name
    available_instruments[i].downloaded=downloaded
    available_instruments[i].active=(downloaded and i==instrument_current)
    if not downloaded then
      s=s.." - get?"
    end
    if available_instruments[i].active then
      s='> '..s..' <'
    else
      s='  '..s
    end
    table.insert(items,s)
  end
  local index = 1
  if uilist ~= nil then 
    index = uilist.index 
  end
  uilist=UI.ScrollingList.new(0,0,index,items)
end

function os.capture(cmd,raw)
  local f=assert(io.popen(cmd,'r'))
  local s=assert(f:read('*a'))
  f:close()
  if raw then return s end
  s=string.gsub(s,'^%s+','')
  s=string.gsub(s,'%s+$','')
  s=string.gsub(s,'[\n\r]+',' ')
  return s
end

function enc(k,d)
  uilist:set_index_delta(d,true)
end

function key(k,z)
  if z==1 then
    local i=uilist.index
    if available_instruments[i].downloaded then
      instrument_current=i
      update_uilist()
    elseif download_available>0 then
      if k==2 then
        download_available=0
      elseif k==3 then
        -- download!
        downloading=true
        redraw()
        clock.run(function()
          download(available_instruments[download_available].id)
          instrument_current=download_available
          update_uilist()
          skeys:add_folder(_path.code.."mx.samples/samples/"..available_instruments[download_available].id.."/")
          download_available=0
          downloading=false
          redraw()
        end)
      end
    else
      download_available=i
    end
  end
end


function download(id)
  local url="https://github.com/schollz/mx.samples/releases/download/samples/"..id..".zip"
  local download_file=_path.code.."mx.samples/samples/"..id.."/download.zip"
  cmd="mkdir -p ".._path.code.."mx.samples/samples/"..id
  print(cmd)
  os.execute(cmd)
  cmd="curl -L -o "..download_file.." "..url
  print(cmd)
  os.execute(cmd)
  cmd="unzip "..download_file.." -d ".._path.code.."mx.samples/samples/"..id.."/"
  print(cmd)
  os.execute(cmd)
  cmd = "rm "..download_file
  print(cmd)
  os.execute(cmd)
end

function redraw_clock() -- our grid redraw clock
  while true do -- while it's running...
    clock.sleep(1/30) -- refresh
    redraw()
  end
end

function redraw()
  screen.clear()
  if downloading then
    msg=UI.Message.new({"downloading",available_instruments[download_available].name,"please wait..."})
    msg:redraw()
  elseif download_available>0 then
    local s=available_instruments[download_available].name..' ('..available_instruments[download_available].size..' MB)'
    msg=UI.Message.new({"are you sure you","want to download",s.."?","k2 = no, k3 = yes"})
    msg:redraw()
  else
    uilist:redraw()
  end
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
