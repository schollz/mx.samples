-- mx.samples v1.4.2
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
  {name="12string piano",size=40*1.5},
  {name="alto sax choir",size=17*1.5},
  {name="angelic dobro",size=35},
  {name="asat classic clean",size=28*1.5},
  {name="ash harmonium",size=307*1.5},
  {name="bedroom clarinet short",size=7*1.5},
  {name="bedroom clarinet sustained",size=50*1.5},
  {name="blackhole guitar",size=27*1.5},
  {name="box violin",size=8*1.5},
  {name="cello",size=22*1.5},
  {name="cello pad",size=4*1.5},
  {name="claus piano",size=616},
  {name="claus piano wpedal",size=614},
  {name="cow pad",size=61},
  {name="dictaphone",size=18},
  {name="discord choir",size=18},
  {name="doom drone",size=47},
  {name="drums acoustic",size=31*1.5},
  {name="drums snapping",size=1.5},
  {name="drums violin",size=5},
  {name="dyn evo choir slow",size=288*1.5},
  {name="dyn evo choir fast",size=172*1.5},
  {name="ebow guitar",size=137*1.5},
  {name="epiphone guitar",size=5.9*1.5},
  {name="epiano dx7",size=15},
  {name="epiano r3",size=350},
  {name="fender rhodes",size=102},
  {name="fender strato vib",size=15*5.2},
  {name="gentle vibes",size=206},
  {name="glockenspiel",size=12*1.5},
  {name="ghost piano",size=40*1.5},
  {name="hannas melodica",size=40*1.5},
  {name="hohner guitaret",size=137*1.5},
  {name="harmonium",size=535},
  {name="india ashberry dry",size=15},
  {name="kawai felt",size=62.8*2},
  {name="lamp",size=4},
  {name="kalimba",size=217*1.5},
  {name="marimba red",size=3.8*1.5},
  {name="marimba white",size=3.8*1.5},
  {name="music box",size=20},
  {name="november piano",size=5*1.5},
  {name="piano soft",size=53.3*1.5},
  {name="phils banjo",size=3.8*1.5},
  {name="raindrop c40",size=7},
  {name="reverse piano",size=7},
  {name="sheltone organ",size=31*1.5},
  {name="steel string",size=33*1.5},
  {name="steinway model b",size=128*1.5},
  {name="strat 62",size=26*1.5},
  {name="string spurs",size=221},
  {name="string spurs swells",size=31},
  {name="sufjanwho",size=1.5*7.3},
  {name="sweep bassoon",size=50},
  {name="sweep celli",size=50},
  {name="sweep clarinet",size=50},
  {name="sweep euphonium",size=50},
  {name="sweep flute",size=50},
  {name="sweep horns",size=50},
  {name="sweep oboe",size=50},
  {name="sweep trombone",size=50},
  {name="sweep trumpet",size=50},
  {name="sweep violins",size=50},
  {name="tatak piano",size=127*1.5},
  {name="telecaster",size=7.1*1.5},
  {name="trembling radiator",size=16*1.5},
  {name="trembling radiator ebow",size=16*1.5},
  {name="uilleann pipes",size=117},
  {name="wind chimes",size=5},
}

function init()
  cmd="mkdir -p ".._path.audio.."mx.samples/"
  print(cmd)
  os.execute(cmd)

  skeys=mxsamples:new()
  update_uilist()

  setup_midi()

  local f=io.open(_path.data.."mx.samples/last","rb")
  if f~=nil then
    local content=f:read("*all")
    f:close()
    local last_instrument_current=tonumber(content)
    if last_instrument_current~=nil then
      instrument_current=last_instrument_current
      uilist.index=instrument_current
      update_uilist()
    end
  end

  -- set default delay
  params:set("mxsamples_delay_rate",4)
  params:set("mxsamples_delay_times",4)

  print("available instruments: ")
  tab.print(skeys:list_instruments())
  clock.run(redraw_clock)
end

function setup_midi()
  -- get list of devices
  local mididevice={}
  local mididevice_list={"none"}
  midi_channels={"all"}
  for i=1,16 do
    table.insert(midi_channels,i)
  end
  for _,dev in pairs(midi.devices) do
    if dev.port~=nil then
      local name=string.lower(dev.name)
      table.insert(mididevice_list,name)
      print("adding "..name.." to port "..dev.port)
      mididevice[name]={
        name=name,
        port=dev.port,
        midi=midi.connect(dev.port),
        active=false,
      }
      mididevice[name].midi.event=function(data)
        if mididevice[name].active==false then
          do return end
        end
        local d=midi.to_msg(data)
        --if d.type~="clock" then
        --  tab.print(d)
        --end
        if d.ch~=midi_channels[params:get("midichannel")] and params:get("midichannel")>1 then
          do return end
        end
        if d.type=="note_on" then
          skeys:on({name=available_instruments[instrument_current].id,midi=data[2],velocity=data[3]})
        elseif d.type=="note_off" then
          skeys:off({name=available_instruments[instrument_current].id,midi=data[2]})
        elseif d.cc==64 then -- sustain pedal
          local val=d.val
          if val>126 then
            val=1
          else
            val=0
          end
          if params:get("mxsamples_pedal_mode")==1 then
            engine.mxsamples_sustain(val)
          else
            engine.mxsamples_sustenuto(val)
          end
        end
      end
    end
  end
  tab.print(mididevice_list)

  params:add{type="option",id="midi",name="midi in",options=mididevice_list,default=1}
  params:set_action("midi",function(v)
    if v==1 then
      do return end
    end
    for name,_ in pairs(mididevice) do
      mididevice[name].active=false
    end
    mididevice[mididevice_list[v]].active=true
  end)
  params:add{type="option",id="midichannel",name="midi ch",options=midi_channels,default=1}

  if #mididevice_list>1 then
    params:set("midi",2)
  end
end

function update_uilist()
  -- check if downloaded

  items={}
  for i,a in ipairs(available_instruments) do
    available_instruments[i].id=string.gsub(a.name," ","_")
    local files_for=os.capture("ls /home/we/dust/audio/mx.samples/"..available_instruments[i].id.."/*.wav")
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
  local index=1
  if uilist~=nil then
    index=uilist.index
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
      f=io.open(_path.data.."mx.samples/last","w")
      f:write(instrument_current)
      f:close()
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
          skeys:add_folder(_path.audio.."mx.samples/"..available_instruments[download_available].id.."/")
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
  local download_file=_path.audio.."mx.samples/"..id.."/download.zip"
  cmd="mkdir -p ".._path.audio.."mx.samples/"..id
  print(cmd)
  os.execute(cmd)
  cmd="curl -L -o "..download_file.." "..url
  print(cmd)
  os.execute(cmd)
  cmd="unzip "..download_file.." -d ".._path.audio.."mx.samples/"..id.."/"
  print(cmd)
  os.execute(cmd)
  cmd="rm "..download_file
  print(cmd)
  os.execute(cmd)
end

function redraw_clock() -- our grid redraw clock
  while true do -- while it's running...
    clock.sleep(1/10) -- refresh
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
