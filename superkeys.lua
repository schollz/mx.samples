-- superkeys v0.0.0
-- sample player
--
-- llllllll.co/t/superkeys
--

superkeys=include("superkeys/lib/superkeys")

engine.name="Superkeys"
sk = nil

function init()
  sk=superkeys:new()

  clock.run(redraw_clock) -- start the grid redraw clock
end

function enc(k,d)

end

function key(k,z)

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
