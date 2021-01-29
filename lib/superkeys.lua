-- modulate for samples
--

local MusicUtil=require "musicutil"
local Formatters=require 'formatters'

local Superkeys={}

local delay_rates_names={"whole-note","half-note","quarter note","eighth note","sixteenth note"}
local delay_rates={1,2,4,8,16}

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
  local sample_folders=list_files(_path.code.."superkeys/samples/")
  for _,sample_folder_path in ipairs(sample_folders) do
    _,sample_folder,_=string.match(fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
    files=list_files(sample_folder_path)
    for _,fname in ipairs(files) do
      if string.find(fname,".wav") then
        -- WORK
        pathname,filename,ext=string.match(fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
        -- midival,dynamic,dynamics,variation,release
        local foo=split_str(filename,".")
        l:add({
          name=sample_folder,
          filename=fname,
          midi=tonumber(foo[1]),
          dynamic=tonumber(foo[2]),
          dynamics=tonumber(foo[3]),
          variation=tonumber(foo[4]),
        release=foo[5]=="1"})
      end
    end
  end
  l:finish_adding()

  -- add parameters
  params:add_group("SUPERKEYS",#self.instrument*12)
  local filter_freq=controlspec.new(20,20000,'exp',0,20000,'Hz')
  for instrument_name,_ in pairs(self.instrument) do
    params:add_separator(instrument_name)
    params:add {
      type='control',
      id=instrument_name.."_amp",
      name="amp",
    controlspec=controlspec.new(0,1,'lin',0,1.0,'amp')}
    params:add {
      type='control',
      id=instrument_name.."_tranpose_midi",
      name="transpose midi",
    controlspec=controlspec.new(-24,24,'lin',0,0,'note',1/49)}
    params:add {
      type='control',
      id=instrument_name.."_tranpose_sample",
      name="transpose sample",
    controlspec=controlspec.new(-24,24,'lin',0,0,'note',1/49)}
    params:add {
      type='control',
      id=instrument_name.."_pan",
      name="pan",
    controlspec=controlspec.new(-1,1,'lin',0,0)}
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
    controlspec=controlspec.new(0,100,'lin',0,0,'%',1/100)}
    params:add {
      type='control',
      id=instrument_name.."_delay_feedback",
      name="delay feedback"
    controlspec=controlspec.new(0,100,'lin',0,0,'%',1/100)}
    params:add_option(instrument_name.."_delay_rate","delay rate",delay_rates_names)
    params:add {
      type='control',
      id=instrument_name.."_bitcrusher_sample",
      name="bitcrush sample rate"
    controlspec=controlspec.new(1000,48000,'exp',0,48000,'hz')}
    params:add {
      type='control',
      id=instrument_name.."_bitcrusher_bits",
      name="bitcrush"
    controlspec=controlspec.new(4,32,'lin',0,32,'bits',1/28)}
  end


  return l
end


function Superkeys:add(sample)
  -- {name="something", filename="~/piano_mf_c4.wav", midi=40, dynamic=1|2|3, dynamics=3, release=False/True, has_release=TBD, buffer=TBD}
  -- add sample to instrument
  sample.buffer=-1
  if self.instrument[sample.name]==nil then
    self.instrument[sample.name]={}
  end
  table.insert(self.instrument[sample.name],sample)
end

function Superkeys:finish_adding()
  for sample_name,samples in pairs(self.instrument) do
    local has_release=false
    for i,sample in ipairs(samples) do
      if sample.release then
        has_release=true
        break
      end
    end
    for i,sample in ipairs(samples) do
      self.instrument[sample_name][i].has_release=has_release
    end
  end
end

function Superkeys:on(d)
  -- sk:on({name="piano",midi=40,velocity=60,release=True|False})
  -- {name="something", midi=40, velocity=10}
  if d.release==nil then
    d.release=false
  end
  if d.velocity==nil then
    d.velocity=127
  end

  d.dynamic=1
  if self.instrument[d.name][1].dynamics>1 then
    -- determine dynamic based on velocity
    d.dynamic=math.floor(util.linlin(0,127,1,self.instrument[d.name][1].dynamics+0.999,d.velocity))
  end

  -- transpose midi before finding sample
  d.midi=d.midi+params:get(d.name.."_tranpose_midi")

  -- find the sample that is closest to the midi
  -- with the specified dynamic
  local sample_closest={buffer=-2,midi=-10000}
  local sample_closest_loaded={buffer=-2,midi=-10000}

  -- go through the samples randomly
  local sample_is={}
  for i,sample in ipairs(self.instrument[d.name]) do
    table.insert(sample_is,i)
  end
  -- shuffle
  local sample_is_shuffled={}
  for i,v in ipairs(sample_is) do
    local pos=math.random(1,#sample_is_shuffled+1)
    table.insert(sample_is_shuffled,pos,v)
  end
  for _,i in ipairs(sample_is_shuffled) do
    local sample=self.instrument[d.name][i]
    if d.dynamic==sample.dynamic then
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

    -- compute pan (special for pianos!)
    local pan=params:get(d.name.."_pan")
    if d.name=="piano" then
      pan=util.linlin(21,108,-0.85,0.85,d.midi)
      -- pop1=5000
      -- pop2=6900
    end

    -- compute rate
    local rate=d.rate
    if rate==nil then
      rate=MusicUtil.note_num_to_freq(d.midi)/MusicUtil.note_num_to_freq(sample_closest_loaded.midi)*(MusicUtil.note_num_to_freq(d.midi+params:get(d.name.."_tranpose_sample"))/MusicUtil.note_num_to_freq(d.midi))
    end

    -- compute amp
    -- TODO: multiply amp by velocity curve?
    local amp=params:get(instrument_name.."_amp")

    engine.superkeyson(
      voice_i,
      sample_closest_loaded.buffer,
      rate,
      amp,
      pan,
      params:get(d.name.."_lpf_superkeys"),
      params:get(d.name.."_hpf_superkeys"),
      params:get(d.name.."_notch1_superkeys"),
      params:get(d.name.."_notch2_superkeys"),
      params:get(d.name.."_bitcrusher_sample"),
      params:get(d.name.."_bitcrusher_bits"),
      clock.get_beat_sec(),
      delay_rates[params:get(d.name.."_delay_rate")],
      params:get(d.name.."_delay_feedback"),
      params:get(d.name.."_delay_send"),
    )
  end

  -- load sample if not loaded
  if sample_closest.buffer==-1 then
    self.instrument[d.name][sample_closest.i].buffer=self.buffer
    engine.superkeysload(self.buffer,sample_closest.filename)
    self.buffer=self.buffer+1
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

      -- -- TODO: add a release sound effect
      -- TODO make the release less random
      if self.instrument[d.name][1].has_release and math.random()<1 then
        self:on{name=d.name,release=true,midi=d.midi}
        clock.run(function()
          self:off{name=d.name,midi=d.midi}
        end)
      end
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
