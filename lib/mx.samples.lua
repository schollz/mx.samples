-- modulate for samples
--

local MusicUtil=require "musicutil"
local Formatters=require 'formatters'

local MxSamples={}

local VOICE_NUM=14

local delay_rates_names={"whole-note","half-note","quarter note","eighth note","sixteenth note","thirtysecond"}
local delay_rates={4,2,1,1/2,1/4,1/8,1/16}

local function current_time()
  return os.time()
  -- return clock.get_beat_sec()*clock.get_beats()
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
        files=_list_files(s,files,recursive)
      end
    end
  end
  do
    local cmd="ls -p "..d
    local f=assert(io.popen(cmd,'r'))
    local out=assert(f:read('*a'))
    f:close()
    for s in out:gmatch("%S+") do
      table.insert(files,d..s)
    end
  end
  return files
end

local function list_files(d,recurisve)
  if recursive==nil then
    recursive=false
  end
  return _list_files(d,{},recursive)
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

function MxSamples:new(args)
  local l=setmetatable({},{__index=MxSamples})
  local args=args==nil and {} or args
  l.debug = args.debug
  l.instrument={} -- map instrument name to list of samples
  l.buffer=0
  l.voice={} -- list of voices and how hold they are
  for i=1,VOICE_NUM do
    l.voice[i]={age=current_time(),active={name="",midi=0}}
  end

  -- lets add files
  local sample_folders=list_files(_path.code.."mx.samples/samples/")
  for _,sample_folder_path in ipairs(sample_folders) do
    l:add_folder(sample_folder_path)
  end

  -- check for and add that a key has release
  for sample_name,samples in pairs(l.instrument) do
    local has_release=false
    for i,sample in ipairs(samples) do
      if sample.is_release then
        has_release=true
        break
      end
    end
    for i,sample in ipairs(samples) do
      l.instrument[sample_name][i].has_release=has_release
    end
  end

  -- add parameters
  params:add_group("MX.SAMPLES",17)
  local filter_freq=controlspec.new(20,20000,'exp',0,20000,'Hz')
  params:add {
    type='control',
    id="mxsamples_amp",
    name="amp",
  controlspec=controlspec.new(0,10,'lin',0,1.0,'amp')}
  params:add {
    type='control',
    id="mxsamples_pan",
    name="pan",
  controlspec=controlspec.new(-1,1,'lin',0,0)}
  params:add {
    type='control',
    id="mxsamples_attack",
    name="attack",
  controlspec=controlspec.new(0,10,'lin',0,0,'s')}
  params:add {
    type='control',
    id="mxsamples_decay",
    name="decay",
  controlspec=controlspec.new(0,10,'lin',0,1,'s')}
  params:add {
    type='control',
    id="mxsamples_sustain",
    name="sustain",
  controlspec=controlspec.new(0,2,'lin',0,0.9,'amp')}
  params:add {
    type='control',
    id="mxsamples_release",
    name="release",
  controlspec=controlspec.new(0,10,'lin',0,2,'s')}
  params:add {
    type='control',
    id="mxsamples_transpose_midi",
    name="transpose midi",
  controlspec=controlspec.new(-24,24,'lin',0,0,'note',1/48)}
  params:add {
    type='control',
    id="mxsamples_transpose_sample",
    name="transpose sample",
  controlspec=controlspec.new(-24,24,'lin',0,0,'note',1/48)}
  params:add {
    type='control',
    id="mxsamples_tune",
    name="tune sample",
  controlspec=controlspec.new(-100,100,'lin',0,0,'cents',1/200)}
  params:add {
    type='control',
    id='mxsamples_lpf_mxsamples',
    name='low-pass filter',
    controlspec=filter_freq,
    formatter=Formatters.format_freq
  }
  params:add {
    type='control',
    id='mxsamples_hpf_mxsamples',
    name='high-pass filter',
    controlspec=controlspec.new(20,20000,'exp',0,20,'Hz'),
    formatter=Formatters.format_freq
  }
  params:add {
    type='control',
    id="mxsamples_delay_send",
    name="delay send",
  controlspec=controlspec.new(0,100,'lin',0,0,'%',1/100)}
  params:add {
    type='control',
    id="mxsamples_delay_times",
    name="delay iterations",
  controlspec=controlspec.new(0,100,'lin',0,0,'beats',1/100)}
  params:add_option("mxsamples_delay_rate","delay rate",delay_rates_names)
    params:add {
    type='control',
    id="mxsamples_sample_start",
    name="sample start",
  controlspec=controlspec.new(0,1000,'lin',0,0,'ms',1/1000)}
  params:add {
    type='control',
    id="mxsamples_play_release",
    name="play release prob",
  controlspec=controlspec.new(0,100,'lin',0,50,'%',1/100)}
  params:add_option("mxsamples_scale_velocity","scale with velocity",{"off","on"})

  return l
end

function MxSamples:reset()
  for name,_ in pairs(self.instrument) do
    for i,_ in ipairs(self.instrument[name]) do
      self.instrument[name][i].buffer = -1 -- reset buffer info
    end
  end

  for i,_ in ipairs(self.voice) do
    self.voice[i]={age=current_time(),active={name="",midi=0}} -- reset voices
  end
end

function MxSamples:add_folder(sample_folder_path)
  _,sample_folder,_=string.match(sample_folder_path,"(.-)([^\\/]-%.?([^%.\\/]*))/$")
  -- make sure it doesn't exist 
  for name, _ in pairs(self.instrument) do 
    if name==sample_folder then 
      do return end 
    end
  end
  files=list_files(sample_folder_path)
  local found_wav=false
  for _,fname in ipairs(files) do
    if string.find(fname,".wav") then
      found_wav=true
      -- WORK
      pathname,filename,ext=string.match(fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
      -- midival,dynamic,dynamics,variation,release
      local foo=split_str(filename,".")
      self:add({
        name=sample_folder,
        filename=fname,
        midi=tonumber(foo[1]),
        dynamic=tonumber(foo[2]),
        dynamics=tonumber(foo[3]),
        variation=tonumber(foo[4]),
      is_release=foo[5]=="1"})
    end
  end
  return found_wav
end

function MxSamples:list_instruments()
  local names = {}
  for name,_ in pairs(self.instrument) do
    table.insert(names,name)
  end
  table.sort(names)
  return names
end

function MxSamples:add(sample)
  -- {name="something", filename="~/piano_mf_c4.wav", midi=40, dynamic=1|2|3, dynamics=3, release=False/True, has_release=TBD, buffer=TBD}
  -- add sample to instrument
  sample.buffer=-1
  if self.instrument[sample.name]==nil then
    self.instrument[sample.name]={}
  end
  table.insert(self.instrument[sample.name],sample)
end


function MxSamples:on(d)
  -- {name="piano",midi=40,velocity=60,is_release=True|False}

  -- use spaes or undersores
  d.name=d.name:gsub(" ","_")

  if d.is_release==nil then
    d.is_release=false
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
  d.midi=d.midi+(d.transpose_midi or params:get("mxsamples_transpose_midi"))

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
    if (d.dynamic==sample.dynamic and d.is_release==sample.is_release) or (d.is_release==true and sample.is_release==true) then
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


  local voice_i=-1
  if sample_closest_loaded.buffer>-1 then
    -- assign the new voice
    voice_i=self:get_voice()
    self.voice[voice_i].active={name=d.name,midi=d.midi,i=sample_closest_loaded.i}
    if self.debug then
      print("sample_closest_loaded: "..sample_closest_loaded.filename.." on voice "..voice_i)
    end
    -- play it from the engine

    -- compute pan (special for pianos!)
    local pan=params:get("mxsamples_pan")
    if string.find(d.name,"piano") then
      pan=util.linlin(21,108,-0.85,0.85,d.midi)
    end

    -- compute rate
    local rate=d.rate
    if d.is_release and rate==nil then
      rate=1
    elseif rate==nil then
      local transpose_sample = d.transpose_sample
      if transpose_sample == nil then 
        transpose_sample = params:get("mxsamples_transpose_sample")
      end
      local hz = d.hz or MusicUtil.note_num_to_freq(d.midi)
      local hz_transpose = (MusicUtil.note_num_to_freq(d.midi+transpose_sample)/MusicUtil.note_num_to_freq(d.midi))
      if d.hz ~= nil then 
	      hz_transpose = 1
      end
      rate=hz/MusicUtil.note_num_to_freq(sample_closest_loaded.midi)*hz_transpose
    end
    local cents = d.tune 
    if cents == nil then 
      cents = params:get("mxsamples_tune")
    end
    rate = rate * (2^(cents/1200))

    -- compute amp
    -- multiply amp by velocity curve
    local amp=params:get("mxsamples_amp")
    local scale_amp = params:get("mxsamples_scale_velocity")==2
    if d.scale_velocity ~= nil then 
      scale_amp = d.scale_velocity
    end
    if scale_amp then 
      amp = amp * d.velocity / 127 
    end
    engine.mxsampleson(
      voice_i,
      sample_closest_loaded.buffer,
      rate,
      d.amp or amp,
      d.pan or pan,
      d.attack or params:get("mxsamples_attack"),
      d.decay or params:get("mxsamples_decay"),
      d.sustain or params:get("mxsamples_sustain"),
      d.release or params:get("mxsamples_release"),
      d.lpf or params:get("mxsamples_lpf_mxsamples"),
      d.hpf or params:get("mxsamples_hpf_mxsamples"),
      clock.get_beat_sec(),
      d.delay_rate or delay_rates[params:get("mxsamples_delay_rate")],
      d.delay_times or params:get("mxsamples_delay_times")/100,
      d.delay_send or params:get("mxsamples_delay_send")/100,
      d.sample_start or params:get("mxsamples_sample_start")
    )
  end

  -- load sample if not loaded
  if sample_closest.buffer==-1 then
    -- print("loading:")
    -- tab.print(sample_closest)
    self.instrument[d.name][sample_closest.i].buffer=self.buffer
    engine.mxsamplesload(self.buffer,sample_closest.filename)
    self.buffer=self.buffer+1
  end

  return voice_i
end

function MxSamples:off(d)
  -- {name="something", midi=40, is_release=True|False}
  if d.name == nil then 
    print("mx.samples error (:off): no name!")
    do return end
  end

  -- use spaes or undersores
  d.name=d.name:gsub(" ","_")

  if d.is_release==nil then
    d.is_release=false
  end

  -- find the voice being used for this one
  for i,voice in ipairs(self.voice) do
    if voice.active.name==d.name and voice.active.midi==d.midi then
      -- this is the one!
      if self.debug then 
        print("mxsamples: turning off "..d.name..":"..d.midi)
      end
      self.voice[i].age=current_time()
      self.voice[i].active={name="",midi=0}
      engine.mxsamplesoff(i)

      -- add a release sound effect if its not a release
      if self.instrument[d.name][1].has_release and math.random(100)<params:get("mxsamples_play_release") then
        if self.debug then 
          print("doing release!")
        end
        local voice_i=self:on{name=d.name,is_release=true,midi=d.midi,variation=d.variation}
        if voice_i > 0 then 
          clock.run(function()
            clock.sleep(0.5)
            self.voice[voice_i].active={name="",midi=0}
            engine.mxsamplesoff(voice_i)
          end)
        end
      end
      do return end
    end
  end
end

function MxSamples:get_voice()
  -- gets voice based on the oldest that is not being used
  local oldest={i=0,age=current_time()}
  for i,voice in ipairs(self.voice) do
    if voice.age<oldest.age and voice.active.midi==0 then
      oldest={i=i,age=voice.age}
    end
  end
  
  -- found none - now just take the oldest
  if oldest.i==0 then
    for i,voice in ipairs(self.voice) do
      if voice.age<oldest.age then
        oldest={i=i,age=voice.age}
      end
    end
  end
  if oldest.i == 0 then 
    oldest.i = 1
  end

  -- turn off voice
  engine.mxsamplesoff(oldest.i)
  self.voice[oldest.i].age=current_time()
  return oldest.i
end


return MxSamples
