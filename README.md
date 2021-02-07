# mx.samples

mx.samples: like mr.coffee or mr.radar, but for samples


this script provides an accessible way to utilize the vast trove of free instrument sample libraries. for instance, you can load in a piano with multiple dynamics and variations and key release.

this script + supercollider engine handles the voices and the instruments dynamically - only loading into memory when needed so you can have gigabytes of samples and use only what you need in realtime. 

a massive thank you to @zebra for helping me post-process the UofI piano samples - those samples were one of my main motivations for this script since i wanted the norns to be a piano sometimes.

## requirements

- norns
- midi controller 

## documentation

### as a keyboard

you can use *mx.samples* as a keyboard. just plugin your midi keyboard, open the script and choose a sample. samples are available to download (processed by me, you can process your own too - see below).

_"warming" up the keyboard:_ the very first note you play will not "play" (known bug) because it is loading the sample. every subsequent *new* note will re-pitch the loaded sample *or it will load in a sample for that note* to be used the next time (so no latency from load). this means that you can get the best sound by playing the notes you want to play once before you play them.

### as a library

the api is pretty simple to include this into another script if you want a bunch of different voices. (another goal here - to use with [tmi](https://llllllll.co/t/tmi/)). instruments are loaded dynamically so you can add as many as you want.

see [study1.lua](https://github.com/schollz/mx.samples/blob/main/studies/study1.lua) for an example that uses [tmi](https://llllllll.co/t/tmi/) to do the sequencing.

basically the syntax would be:

```lua
mxsamples=include("mx.samples/lib/mx.samples")
engine.name="MxSamples"
skeys=mxsamples:new()

-- play an instrument
skeys:on({name="ghost piano",midi=60,velocity=120})
skeys:on({name="box violin",midi=42,velocity=120})

-- turn them off
skeys:off({name="ghost piano",midi=60})
skeys:off({name="box violin",midi=42})
```

the parameters can be added into the `on` function as well:

```lua
skeys:on({
	name="ghost piano",midi=60,velocity=120,
	attack=1,
	release=3,
	-- every parameter in the menu is available here
})
```

### getting samples

this script will allow you to download samples that i've already converted to use with it.

however, you can easily take any sample library and convert to use with mx.samples. in the `samples/` folder there is a utility script `convert.py` that is specific to each type of sample and shows basically how its done (its easy).

the current samples are from the following sources, which are free and do not restrict to distributing them for this purpose:

- The University of Iowa Musical Instrument Samples database which ["may be downloaded and used for any projects, without restrictions"](http://theremin.music.uiowa.edu/MIS.html).
- the pianobook which states that ["There are NO restrictions on their use (except selling them on as your own samples)"](https://www.pianobook.co.uk/faq/)

## license

MIT
