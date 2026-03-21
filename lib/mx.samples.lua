-- modulate for samples
--

local MusicUtil=require "musicutil"
local Formatters=require 'formatters'

local MxSamples={}

local MaxVoices=40
local delay_rates_names={"whole-note","half-note","quarter note","eighth note","sixteenth note","thirtysecond"}
local delay_rates={4,2,1,1/2,1/4,1/8,1/16}
local delay_last_clock=0
local velocities={}
velocities[1]={1,4,7,10,13,16,19,22,25,28,31,34,38,41,43,46,49,52,55,57,60,62,64,66,68,70,71,73,74,76,77,79,80,81,83,84,85,86,87,89,90,91,92,93,94,95,95,96,97,98,99,99,100,101,102,102,103,104,104,105,105,106,106,107,107,108,108,109,109,109,110,110,111,111,111,112,112,112,112,113,113,113,114,114,114,114,115,115,115,115,115,116,116,116,116,116,117,117,117,117,118,118,118,118,118,119,119,119,120,120,120,120,121,121,121,122,122,122,123,123,124,124,124,125,125,126,126,127}
velocities[2]={0,2,3,4,6,7,8,10,11,13,14,15,17,18,19,21,22,23,25,26,27,29,30,31,33,34,35,37,38,39,40,42,43,44,45,47,48,49,50,52,53,54,55,57,58,59,60,61,62,64,65,66,67,68,69,70,71,72,73,75,76,77,78,79,80,81,82,83,83,84,85,86,87,88,89,90,91,92,92,93,94,95,96,97,97,98,99,100,100,101,102,103,103,104,105,106,106,107,108,109,109,110,111,111,112,113,113,114,115,115,116,117,117,118,119,119,120,120,121,122,122,123,124,124,125,126,126,127}
velocities[3]={1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,8,8,8,9,9,9,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,18,18,19,20,20,21,22,23,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,42,43,44,45,47,48,49,51,52,54,55,57,58,60,62,63,65,66,68,70,72,73,75,77,79,80,82,84,86,88,90,92,94,95,97,99,101,103,105,107,109,111,113,115,117,119,121,123,125,127}
velocities[4]={}
for i=1,128 do
  table.insert(velocities[4],64)
end

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

local function freq_to_midi(freq)
  return 12 * math.log10(freq / 440) / math.log10(2) + 69
end

local function midi_to_freq(midi)
  return 440 * math.exp(.057762265 * (midi - 69))
end

function MxSamples:new(args)
  local l=setmetatable({},{__index=MxSamples})
  local args=args==nil and {} or args
  l.debug=args.debug --true-- args.debug -- true --args.debug
  l.instrument={} -- map instrument name to list of samples
  l.buffers_used={} -- map buffer number to data
  l.buffer=0
  l.voice={} -- list of voices and how hold they are
  l.voice_last=1
  for i=1,MaxVoices do -- initiate with 40 voices
    l.voice[i]={age=current_time(),active={name="",midi=0}}
  end

  -- lets add files
  local sample_folders=list_files(_path.audio.."mx.samples/")
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
  params:add_group("MX.SAMPLES",20)
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
    id="mxsamples_reverb_send",
    name="reverb send",
  controlspec=controlspec.new(0,100,'lin',0,0,'%',1/100)}
  params:add {
    type='control',
    id="mxsamples_delay_send",
    name="delay send",
  controlspec=controlspec.new(0,100,'lin',0,0,'%',1/100)}
  params:add {
    type='control',
    id="mxsamples_delay_times",
    name="delay iterations",
  controlspec=controlspec.new(0,100,'lin',0,1,'beats',1/100)}
  params:set_action("mxsamples_delay_times",function(x)
    if engine.name=="MxSamples" then
      engine.mxsamples_delay_feedback(x/100)
    end
  end)
  params:add_option("mxsamples_delay_rate","delay rate",delay_rates_names,1)
  params:set_action("mxsamples_delay_rate",function(x)
    if engine.name=="MxSamples" then
      engine.mxsamples_delay_beats(delay_rates[x])
    end
  end)
  params:add {
    type='control',
    id="mxsamples_sample_start",
    name="sample start",
  controlspec=controlspec.new(0,1000,'lin',0,0,'ms',1/1000)}
  params:add {
    type = "control",
    id = "mxsamples_noise_level",
    name = "noise level",
  controlspec = controlspec.new(0, 10, 'lin', 0, 0, 'x', 0.01)}
  params:add {
    type='control',
    id="mxsamples_play_release",
    name="play release prob",
  controlspec=controlspec.new(0,100,'lin',0,0,'%',1/100)}
  params:add_option("mxsamples_scale_velocity","velocity sensitivity",{"delicate","normal","stiff","fixed"},4)
  params:add_option("mxsamples_pedal_mode","pedal mode",{"sustain","sostenuto"},1)

  osc.event=function(path,args,from)
    if path=="voice" then
      local voice_num=args[1]
      local onoff=args[2]
      if onoff==0 and voice_num~=nil then
        l.voice[voice_num].age=current_time()
        l.voice[voice_num].active={name="",midi=0}
      end
    end
  end

  return l
end

function MxSamples:max_voices(num_voices)
  if num_voices<MaxVoices then
    engine.mxsamplesvoicenum(num_voices) -- release unused voices
    for i=num_voices,MaxVoices do
      self.voice[i]=nil
    end
  end
end

function MxSamples:reset()
  for name,_ in pairs(self.instrument) do
    for i,_ in ipairs(self.instrument[name]) do
      self.instrument[name][i].buffer=-1 -- reset buffer info
    end
  end

  for i,_ in ipairs(self.voice) do
    self.voice[i]={age=current_time(),active={name="",midi=0}} -- reset voices
  end
end

function MxSamples:add_folder(sample_folder_path)
  _,sample_folder,_=string.match(sample_folder_path,"(.-)([^\\/]-%.?([^%.\\/]*))/$")
  -- make sure it doesn't exist
  for name,_ in pairs(self.instrument) do
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
  local names={}
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
    d.velocity=72
  end

  if params:get("mxsamples_scale_velocity")<4 then
    -- scale velocity depending on sensitivity
    d.velocity=velocities[params:get("mxsamples_scale_velocity")][math.floor(d.velocity+1)]
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

  -- for z_tuning compatibility
  -- convert direct midi note to frequency using MusicUtil.note_num_to_freq, which is altered by z_tuning, then convert the result to midi value using a standart locale function
  local note_in_freq = MusicUtil.note_num_to_freq(d.midi)
  local note_in_midi = freq_to_midi(note_in_freq)
  
  for _,i in ipairs(sample_is_shuffled) do
    local sample=self.instrument[d.name][i]
    if (d.dynamic==sample.dynamic and d.is_release==sample.is_release) or (d.is_release==true and sample.is_release==true) then
      if math.abs(sample.midi - note_in_midi )<math.abs(sample_closest.midi - note_in_midi) then
        sample_closest=sample
        sample_closest.i=i
      end
      if math.abs(sample.midi - note_in_midi)<math.abs(sample_closest_loaded.midi - note_in_midi) and sample.buffer>-1 then
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
      local transpose_sample=d.transpose_sample
      if transpose_sample==nil then
        transpose_sample=params:get("mxsamples_transpose_sample")
      end
      local hz=d.hz or MusicUtil.note_num_to_freq(d.midi)
      local hz_transpose=(MusicUtil.note_num_to_freq(d.midi+transpose_sample)/MusicUtil.note_num_to_freq(d.midi))
      if d.hz~=nil then
        hz_transpose=1
      end
      rate=hz/midi_to_freq(sample_closest_loaded.midi)*hz_transpose
    end
    local cents=d.tune
    if cents==nil then
      cents=params:get("mxsamples_tune")
    end
    rate=rate*(2^(cents/1200))

    -- compute amp
    -- multiply amp by velocity curve
    local amp=params:get("mxsamples_amp")
    if params:get("mxsamples_scale_velocity")<4 then
      amp=amp*d.velocity/127
    end

    -- update the delay if needed
    if clock.get_beat_sec()~=delay_last_clock then
      delay_last_clock=clock.get_beat_sec()
      engine.mxsamples_delay_time(delay_last_clock)
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
      d.delay_send or params:get("mxsamples_delay_send")/100,
      d.reverb_send or params:get("mxsamples_reverb_send")/100,
      d.sample_start or params:get("mxsamples_sample_start"),
      d.noise_level or params:get("mxsamples_noise_level"))
  end

  -- load sample if not loaded
  if sample_closest.buffer==-1 then
    -- print("loading:")
    -- tab.print(sample_closest)
    if self.debug then
      print("loading "..d.name.." "..sample_closest.i.." into buffer "..self.buffer)
    end
    self.instrument[d.name][sample_closest.i].buffer=self.buffer
    self.buffers_used[self.buffer]={name=d.name,i=sample_closest.i}
    engine.mxsamplesload(self.buffer,sample_closest.filename)
    self.buffer=self.buffer+1
    if self.buffer>79 then
      self.buffer=0
    end
    -- if this next buffer is being used, get it ready to be overridden
    if self.buffers_used[self.buffer]~=nil then
      self.instrument[self.buffers_used[self.buffer].name][self.buffers_used[self.buffer].i].buffer=-1
    end
  end

  return voice_i
end

function MxSamples:off(d)
  -- {name="something", midi=40, is_release=True|False}
  if d.name==nil then
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
      engine.mxsamplesoff(i)

      -- add a release sound effect if its not a release
      if self.instrument[d.name][1].has_release and math.random(100)<params:get("mxsamples_play_release") then
        if self.debug then
          print("doing release!")
        end
        local voice_i=self:on{name=d.name,is_release=true,midi=d.midi,variation=d.variation}
        if voice_i>0 then
          clock.run(function()
            clock.sleep(0.5)
            engine.mxsamplesoff(voice_i)
          end)
        end
      end
    end
  end
end

function MxSamples:get_voice()
  -- gets voice based on the oldest that is not being used
  local oldest={i=0,age=current_time()}
  for i,voice in ipairs(self.voice) do
    -- print(i,voice.active.midi)
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
  if oldest.i==0 then
    oldest.i=1
  end

  -- turn off voice
  engine.mxsamplesoff(oldest.i)
  self.voice[oldest.i].age=current_time()
  return oldest.i
end

return MxSamples
