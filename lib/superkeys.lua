-- modulate for samples
--

local MusicUtil = require "musicutil"
local Formatters=require 'formatters'

local Superkeys={}

local delay_rates_names = {"whole-note","half-note","quarter note","eighth note","sixteenth note"}
local delay_rates = {4,2,1,1/2,1/4}

local function current_time()
  return clock.get_beat_sec()*clock.get_beats()
end


local function list_files(d,recurisve)
  if recursive==nil then
    recursive=false
  end
  return _list_files(d,{},recursive)
end

local function _list_files(d,files,recursive)
  -- list files in a flat table
  if d=="." or d=="./" then
    d=""
  end
  if d~="" and string.sub(d,-1)~="/" then
    d=d.."/"
  end
  folders={}
  if recursive then
    local cmd="ls -ad "..d.."*/ 2>/dev/null"
    local f=assert(io.popen(cmd,'r'))
    local out=assert(f:read('*a'))
    f:close()
    for s in out:gmatch("%S+") do
      if not (string.match(s,"ls: ") or s=="../" or s=="./") then
        files=list_files(s,files,recursive)
      end
    end
  end
  do
    local cmd="ls -p "..d.." | grep -v /"
    local f=assert(io.popen(cmd,'r'))
    local out=assert(f:read('*a'))
    f:close()
    for s in out:gmatch("%S+") do
      table.insert(files,d..s)
    end
  end
  return files
end

local function split_str(inputstr,sep)
  if sep==nil then
    sep="%s"
  end
  local t={}
  for str in string.gmatch(inputstr,"([^"..sep.."]+)") do
    table.insert(t,str)
  end
  return t
end

function Superkeys:new(args)
  local l=setmetatable({},{__index=Superkeys})
  local args=args==nil and {} or args
  l.instrument={} -- map instrument name to list of samples
  l.buffer=0
  l.voice={} -- list of voices and how hold they are
  for i=1,12 do
    l.voice[i]={age=current_time(),active={name="",midi=0}}
  end

  -- lets add files
  files=list_files(_path.code.."superkeys/samples/piano/")
  for _,fname in ipairs(files) do
    if string.find(fname,".wav") then
      -- print("adding "..fname)
      pathname,filename,ext=string.match(fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
      local foo=split_str(filename,".")
      velocity_range={45,80}
      if foo[2]=="pp" then
        velocity_range={0,45}
      elseif foo[2]=="ff" then
        velocity_range={80,127}
      end
      local midi_value=foo[3]
      l:add({name="piano",filename=fname,midi=midi_value,velocity_range=velocity_range})
    end
  end
  files=list_files(_path.code.."superkeys/samples/marimba/")
  for _,fname in ipairs(files) do
    if string.find(fname,".wav") then
      -- print("adding "..fname)
      pathname,filename,ext=string.match(fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
      local foo=split_str(filename,".")
      local midi_value=foo[3]
      l:add{name="marimba",filename=fname,midi=tonumber(midi_value)}
    end
  end
  files=list_files(_path.code.."superkeys/samples/vibraphone/")
  for _,fname in ipairs(files) do
    if string.find(fname,".wav") then
      -- print("adding "..fname)
      pathname,filename,ext=string.match(fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
      local foo=split_str(filename,".")
      local midi_value=foo[3]
      l:add{name="vibraphone",filename=fname,midi=tonumber(midi_value)}
    end
  end

  -- add parameters
  params:add_group("SUPERKEYS",#self.instrument*11)
  local filter_freq=controlspec.new(20,20000,'exp',0,20000,'Hz')
  for instrument_name,_ in pairs(self.instrument) do 
    params:add_separator(instrument_name)
    params:add {
      type='control',
      id=instrument_name.."_tranpose_midi",
      name="transpose midi",
      controlspec=controlspec.new(-24,24,'lin',0,0,'note',1/49)
    }
    params:add {
      type='control',
      id=instrument_name.."_tranpose_sample",
      name="transpose sample",
      controlspec=controlspec.new(-24,24,'lin',0,0,'note',1/49)
    }
    params:add {
      type='control',
      id=instrument_name..'_lpf_superkeys',
      name='low-pass filter',
      controlspec=filter_freq,
      formatter=Formatters.format_freq
    }
    params:add {
      type='control',
      id=instrument_name..'_hpf_superkeys',
      name='high-pass filter',
      controlspec=filter_freq,
      formatter=Formatters.format_freq
    }
    params:add {
      type='control',
      id=instrument_name..'_notch1_superkeys',
      name='notch filter 1',
      controlspec=filter_freq,
      formatter=Formatters.format_freq
    }
    params:add {
      type='control',
      id=instrument_name..'_notch2_superkeys',
      name='notch filter 2',
      controlspec=filter_freq,
      formatter=Formatters.format_freq
    }
    params:add {
      type='control',
      id=instrument_name.."_delay_send",
      name="delay send"
      controlspec=controlspec.new(0,100,'lin',0,0,'%',1/100)
    }
    params:add {
      type='control',
      id=instrument_name.."_delay_feedback",
      name="delay feedback"
      controlspec=controlspec.new(0,100,'lin',0,0,'%',1/100)
    }
    params:add_option(instrument_name.."_delay_rate","delay rate",delay_rates_names)
    params:add {
      type='control',
      id=instrument_name.."_bitcrusher_sample",
      name="bitcrush sample rate"
      controlspec=controlspec.new(1000,48000,'exp',0,48000,'hz')
    }
    params:add {
      type='control',
      id=instrument_name.."_bitcrusher_bits",
      name="bitcrush"
      controlspec=controlspec.new(4,32,'lin',0,32,'bits',1/28)
    }
  end


  return l
end


function Superkeys:add(sample)
  -- {name="something", filename="~/piano_mf_c4.wav", midi=40, velocity_range={0,127},buffer=TBD}
  if sample.velocity_range==nil then
    sample.velocity_range={0,127}
  end

  -- add sample to instrument
  sample.buffer=-1
  if self.instrument[sample.name] == nil then 
    self.instrument[sample.name]={}
  end
  table.insert(self.instrument[sample.name],sample)
end

function Superkeys:on(d)
  -- sk:on({name="piano",midi=40,velocity=60})
  -- {name="something", midi=40, velocity=10}
  if d.velocity==nil then
    d.velocity=127
  end
  -- find the sample that is closest to the midi
  -- and within the velocity range
  local sample_closest={buffer=-2,midi=-10000}
  local sample_closest_loaded={buffer=-2,midi=-10000}          
  for i,sample in ipairs(self.instrument[d.name]) do
    if d.velocity>=sample.velocity_range[1] and d.velocity<=sample.velocity_range[2] then
      if math.abs(sample.midi-d.midi)<math.abs(sample_closest.midi-d.midi) then
        sample_closest=sample
        sample_closest.i=i
      end
      if math.abs(sample.midi-d.midi)<math.abs(sample_closest_loaded.midi-d.midi) and sample.buffer>-1 then
        sample_closest_loaded=sample
        sample_closest_loaded.i=i
      end
    end
  end


  if sample_closest_loaded.buffer>-1 then
    -- assign the new voice
    local voice_i=self:get_voice()
    self.voice[voice_i].active={name=d.name,midi=d.midi}

    -- play it from the engine
    print("superkeys: on "..d.name..d.midi)
    local pan = 0
    local pop1=18000
    local pop2=18000
    if d.name == "piano" then 
      pan = util.linlin(21,108,-0.85,0.85,d.midi)
      pop1=5000
      pop2=6900
    end
    print("pan "..pan)
    engine.superkeyson(
      voice_i,
      sample_closest_loaded.buffer,
      MusicUtil.note_num_to_freq(d.midi)/MusicUtil.note_num_to_freq(sample_closest_loaded.midi),
      1.0,
      pan,
      pop1,
      pop2)
end

  -- load sample if not loaded
  if sample_closest.buffer==-1 then 
      self.instrument[d.name][sample_closest.i].buffer=self.buffer
      engine.superkeysload(self.buffer,sample_closest.filename)
      self.buffer = self.buffer + 1
  end

end

function Superkeys:off(d)
  -- {name="something", midi=40}

  -- find the voice being used for this one
  for i,voice in ipairs(self.voice) do
    if voice.active.name==d.name and voice.active.midi==d.midi then
      -- this is the one!
      print("superkeys: turning off "..d.name..":"..d.midi)
      self.voice[i].active={name="",midi=0}
      engine.superkeysoff(i)
      break
    end
  end
end

function Superkeys:get_voice()
  -- gets voice based on the oldest
  local oldest={i=0,age=current_time()}
  for i,voice in ipairs(self.voice) do
    if voice.age<oldest.age then
      oldest={i=i,age=voice.age}
    end
  end
  self.voice[oldest.i].age=current_time()
  return oldest.i
end


return Superkeys
