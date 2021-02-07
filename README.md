# mx.samples

mx.samples: like mr.coffee or mr.radar, but for instrument samples.

https://vimeo.com/509450523

us as a keyboard instrument or in another script. *mx.samples* provides an accessible way to utilize the vast trove of free instrument sample libraries.  for instance, you can load in a piano that has been sampled on multiple dynamics and variations and key releases.

the core of the script + supercollider engine handles the voices and the instruments. you can have unlimited samples on disk because samples are loaded dynamically - only loading into memory when needed (max 200 samples can be loaded though). no latency on loading because it will load in the background (and use the closest pitched sample in the meantime).

my motivation for this script was to have a really nice sounding piano on the norns. also i wanted to be able to have a library of samples that works well with [tmi](https://llllllll.co/t/tmi/40818) (see `studies/study1.lua` and demo above) but can also be used for future projects in the idea galaxy.

a massive thank you to @zebra for helping me post-process the UofI piano samples - there is a great [script available to "de-pop"](https://github.com/schollz/mx.samples/blob/main/samples/depop.py) samples that had glitches in recording, thanks to that work. also this project wouldn't be possible without the generosity of the folks submitting their samples to be used freely at [pianobook.co.uk](https://www.pianobook.co.uk/) and at the [University of Iowa Electronic Music department](http://theremin.music.uiowa.edu/MIS.html).

## requirements

- norns
- midi controller OR use in a script

## documentation

mx.samples can be used as a keyboard (selecting sound+parameters via menus) or as a library (selecting sound+parameters via code).

### as a keyboard

you can use *mx.samples* as a keyboard. just plugin your midi keyboard, open the script and choose a sample. samples are available to download (processed by me, you can process your own too - see below).

there are a bunch of effects (filters / delay) and options (tuning, down-sampling, playing releases, velocity scaling) available from the parameters menu `PARAMETERS -> MX.SAMPLES`.

_"warming" up the keyboard:_ the very first note you play will not "play" (known bug) because it is loading the sample. every subsequent *new* note will re-pitch the loaded sample *or it will load in a sample for that note* to be used the next time (so no latency from load). this means that you can get the best sound by playing the notes you want to play once before you play them.

### as a library

you can use *mx.samples* as a lua library for your project (see demo above). the api is pretty simple to include this into another script if you want a bunch of different voices. (another goal here - to use with [tmi](https://llllllll.co/t/tmi/)). instruments are loaded dynamically so you can add as many as you want.

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

this script will allow you to download samples that i've already processed. in theory you can use any kontakt / vst sample pack if you have access to the raw audio. in the `samples/` folder there is a utility script `convert.py` that is specific to each type of sample and shows basically how its done (its easy). here's [an example for the UofI piano](https://github.com/schollz/mx.samples/blob/main/samples/steinway_model_b/convert.py).

the current samples are from the following sources, which are free and do not restrict to distributing them for this purpose:

- The University of Iowa Musical Instrument Samples database which ["may be downloaded and used for any projects, without restrictions"](http://theremin.music.uiowa.edu/MIS.html).
- the pianobook which states that ["There are NO restrictions on their use (except selling them on as your own samples)"](https://www.pianobook.co.uk/faq/)

## download

`;install https://github.com/schollz/mx.samples`
