-- study1
--
-- combining mx.samples
-- with tmi
-- 
-- see the code for info

local UI=require "ui"
mxsamples=include("mx.samples/lib/mx.samples")

engine.name="MxSamples"
skeys = nil 

function init()
  skeys=mxsamples:new()  

  if util.file_exists(_path.code.."tmi") then 
	  tmi=include("tmi/lib/tmi")
	  m=tmi:new({
	    functions={
	      {name="chords",note_on="skeys:on({name='steinway_model_b',midi=<note>,velocity=<velocity>/2,delay_send=0.5,delay_times=4/100,delay_rate=1/2})",note_off="skeys:off({name='steinway_model_b',midi=<note>})"},
	      {name="bass",note_on="skeys:on({name='cello',midi=<note>,velocity=<velocity>/2,transpose_sample=-24,transpose_midi=24,attack=1,release=2,amp=0.9})",note_off="skeys:off({name='cello_pad',midi=<note>})"},
	      {name="melody",note_on="skeys:on({name='ghost_piano',midi=<note>,velocity=<velocity>/2,attack=0,release=2,amp=0.8,delay_send=0.8,delay_times=8/100,delay_rate=1/2})",note_off="skeys:off({name='ghost_piano',midi=<note>})"},
	      {name="swell",note_on="skeys:on({name='alto_sax_choir',midi=<note>,velocity=<velocity>/2,attack=1,release=2,amp=0.45,transpose_midi=-12,delay_send=0.5,delay_times=4/100,delay_rate=1/2})",note_off="skeys:off({name='alto_sax_choir',midi=<note>})"},
	    },
	  })
	  m:load("chords","/home/we/dust/code/mx.samples/studies/chords.tmi",1)
	  m:load("bass","/home/we/dust/code/mx.samples/studies/bass.tmi",2)
	  m:load("melody","/home/we/dust/code/mx.samples/studies/melody.tmi",3)
	  m:load("swell","/home/we/dust/code/mx.samples/studies/swell.tmi",4)
	  m:toggle_play()
	end
  clock.run(redraw_clock) 
end

function redraw_clock() -- our grid redraw clock
  while true do -- while it's running...
    clock.sleep(1/30) -- refresh
    redraw()
  end
end

function redraw()
  screen.clear()
  msg=UI.Message.new({"study1: mx.samples + tmi","requires downloading","cello, alto sax choir","steinway model b,","and ghost piano"})
  if not util.file_exists(_path.code.."tmi") then 
	  msg=UI.Message.new({"requires tmi","install tmi first"})
  end
  msg:redraw()
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
