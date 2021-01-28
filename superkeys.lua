-- superkeys v0.0.0
-- sample player
--
-- llllllll.co/t/superkeys
--

superkeys=include("superkeys/lib/superkeys")

engine.name="Superkeys"
skeys=nil

function init()
  skeys=superkeys:new()

  print("added files")
  m = midi.connect(3)
  m.event = function(data) 
    tab.print(data) 
    if data[1]==144 then 
      skeys:on({name="piano",midi=data[2],velocity=data[3]})
    elseif data[1]==128 then 
      skeys:off({name="piano",midi=data[2]})
    end
  end

  clock.run(redraw_clock) -- start the grid redraw clock
end

function enc(k,d)

end

function key(k,z)
  if z==1 then 
    skeys:on({name="piano",midi=60,velocity=60})
  elseif z==0 then
    skeys:off({name="piano",midi=60})
  end
end

function redraw_clock() -- our grid redraw clock
  while true do -- while it's running...
    clock.sleep(1/30) -- refresh
    redraw()
  end
end

function redraw()
  screen.clear()
  

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
