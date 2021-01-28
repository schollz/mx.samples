-- modulate for samples
--


local Superkeys={}

function Superkeys:new(args)
  local l=setmetatable({},{__index=Lattice})
  local args=args==nil and {} or args
  l.instrument={} -- map instrument name to list of samples
  l.buffer=0
  return l
end

function Superkeys:add(sample)
  -- {name="something", sample="~/piano_mf_c4.wav", midi=40, velocity_range={0,127},buffer=TBD}
  if sample.velocity_range==nil then
    sample.velocity_range={0,127}
  end

  -- TODO: load sample into a buffer
  sample.buffer=self.buffer
  self.buffer=self.buffer+1

end

function Superkeys:on(d)
  -- {name="something", midi=40, velocity=10}
  if d.velocity==nil then
    d.velocity=127
  end
  -- find the sample that is closest to the midi
  -- and within the velocity range
  local sample_closest={buffer=0,midi=0}
  for i,sample in pairs(self.instrument[d.name]) do
    if d.velocity>=sample.velocity_range[1] and d.velocity<=sample.velocity_range[2] then
      if math.abs(sample.midi-d.midi)<math.abs(sample_closest.midi-d.midi) then
        sample_closest={buffer=sample.buffer,midi=sample.midi}
      end
    end
  end

  if sample_closest.buffer == 0 then
	  print("superkeys: could not find sample")
	  tab.print(d)
	  do return end
  end

  -- TODO: figure out which voice to use
  
  -- play it from the engine
  engine.superkeysplay(
	sample_closest.buffer,
	sample_closest.midi,
	d.midi,
	d.velocity,
  )
end

return Superkeys
