-- modulate for samples
--

MusicUtil = require "musicutil"

local Superkeys={}


local function current_time()
  return clock.get_beat_sec()*clock.get_beats()
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
  return l
end

function Superkeys:add(sample)
  -- {name="something", filename="~/piano_mf_c4.wav", midi=40, velocity_range={0,127},buffer=TBD}
  print("superkeys: add")
  tab.print(sample)
  if sample.velocity_range==nil then
    sample.velocity_range={0,127}
  end

  -- load sample into a buffer
  sample.buffer=self.buffer
  if self.instrument[sample.name] == nil then 
    self.instrument[sample.name]={}
  end
  table.insert(self.instrument[sample.name],sample)
  engine.superkeysload(sample.buffer,sample.filename)
  self.buffer=self.buffer+1
end

function Superkeys:on(d)
  -- sk:on({name="piano",midi=40,velocity=60})
  -- {name="something", midi=40, velocity=10}
  if d.velocity==nil then
    d.velocity=127
  end
  -- find the sample that is closest to the midi
  -- and within the velocity range
  local sample_closest={buffer=0,midi=0}
  for i,sample in ipairs(self.instrument[d.name]) do
    if d.velocity>=sample.velocity_range[1] and d.velocity<=sample.velocity_range[2] then
      if math.abs(sample.midi-d.midi)<math.abs(sample_closest.midi-d.midi) then
        tab.print(sample)
        sample_closest={buffer=sample.buffer,midi=sample.midi}
      end
    end
  end

  if sample_closest.buffer==0 then
    print("superkeys: could not find sample")
    tab.print(d)
    do return end
  end

  -- assign the new voice
  local voice_i=self:get_voice()
  self.voice[voice_i].active={name=d.name,midi=d.midi}

  -- play it from the engine
  print("superkeys: on "..d.name..d.midi)
  engine.superkeyson(
    voice_i,
    sample_closest.buffer,
    MusicUtil.note_num_to_freq(d.midi)/MusicUtil.note_num_to_freq(sample_closest.midi),
    1.0)
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
