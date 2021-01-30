-- superkeys v0.0.0
-- sample player
--
-- llllllll.co/t/superkeys
--

superkeys=include("superkeys/lib/superkeys")

engine.name="Superkeys"
skeys=nil
instrument_names={}
instrument_current=1

function init()
  skeys=superkeys:new()
  instrument_names=skeys:list_instruments()

  for _,dev in pairs(midi.devices) do
    if dev.port~=nil then
      m=midi.connect(dev.port)
      m.event=function(data)
        tab.print(data)
        if data[1]==144 then
          skeys:on({name=instrument_names[instrument_current],midi=data[2],velocity=data[3]})
        elseif data[1]==128 then
          skeys:off({name=instrument_names[instrument_current],midi=data[2]})
        end
      end
    end
  end

  clock.run(redraw_clock) -- start the grid redraw clock
end

function enc(k,d)
end

function key(k,z)
  if k>=2 and z==1 then
    local d=1
    if k==2 then
      d=-1
    end
    instrument_current=instrument_current+d
    if instrument_current<1 then
      instrument_current=#instrument_names
    end
    if instrument_current>#instrument_names then
      instrument_current=1
    end
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

  screen.level(15)
  screen.move(10,10)
  screen.text(instrument_names[instrument_current])
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
