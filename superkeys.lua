-- superkeys v0.0.0
-- sample player
--
-- llllllll.co/t/superkeys
--
local UI=require "ui"
superkeys=include("superkeys/lib/superkeys")

engine.name="Superkeys"
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
  {name="ghost piano",size=40*1.5},
  {name="kawai felt",size=63*1.5},
  {name="steinway model b",size=128*1.5},
  {name="tatak piano",size=127*1.5},
}

function init()
  skeys=superkeys:new()
  update_uilist()

  for _,dev in pairs(midi.devices) do
    if dev.port~=nil then
      m=midi.connect(dev.port)
      m.event=function(data)
        if available_instruments[instrument_current].active~=true then
          do return end
        end
        tab.print(data)
        if data[1]==144 then
          skeys:on({name=available_instruments[instrument_current].id,midi=data[2],velocity=data[3]})
        elseif data[1]==128 then
          skeys:off({name=available_instruments[instrument_current].id,midi=data[2]})
        end
      end
    end
  end

  clock.run(redraw_clock) -- start the grid redraw clock
end

function update_uilist()
  -- check if downloaded

  items={}
  for i,a in ipairs(available_instruments) do
    available_instruments[i].id=string.gsub(a.name," ","_")
    local files_for=os.capture("ls /home/we/dust/code/superkeys/samples/"..available_instruments[i].id.."/*.wav")
    local downloaded=false
    if string.find(files_for,".wav") then
      downloaded=true
    end
    local s=a.name
    available_instruments[i].downloaded=downloaded
    available_instruments[i].active=(downloaded and i==instrument_current)
    if not downloaded then
      s=s.." - get? ("..a.size.."MB)"
    end
    if available_instruments[i].active then
      s='> '..s..' <'
    else
      s='  '..s
    end
    table.insert(items,s)
  end
  uilist=UI.ScrollingList.new(0,0,1,items)
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
    elseif download_available>0 then
      if k==2 then
        download_available=0
      elseif k==3 then
        -- download!
        downloading=true
        clock.run(function()
          download(available_instruments[download_available].id)
          update_uilist()
          download_available=0
          downloading=false
        end)
      end
    else
      download_available=i
    end
  end
end


function download(id)
  local url="https://github.com/schollz/superkeys/releases/download/samples/"..id..".zip"
  local download_file=_path.code.."superkeys/samples/"..id.."/download.zip"
  cmd="curl -o "..download_file.." "..url
  print(cmd)
  os.execute(cmd)
  cmd="unzip "..download_file.." -d ".._path.code.."superkeys/samples/"..id.."/"
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
    local s=available_instruments[download_available].name..'('..available_instruments[download_available].size..')'
    msg=UI.Message.new({"are you sure","you want to","download "..s.."?","k2 = no, k3 = yes"})
    msg:redraw()
  else
    uilist:redraw()
  end
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
