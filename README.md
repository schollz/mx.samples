# superkeys

digiment 


this script provides an accessible way to utilize the vast trove of free instrument sample libraries. for instance, you can load in a piano with multiple dynamics and variations for any number of keys with release samples. 

this script handles the voices and the instruments dynamically, only loading into memory when needed so you can have gigabytes of samples and use only what you need in realtime.

a massive thank you to @zebra for helping me post-process the UofI piano samples - those samples were one of my main motivations for this script.

## requirements

- norns
- midi controller 

## documentation

### as a library

the api is pretty simple to include this into another script if you want a bunch of different voices. instruments are loaded dynamically so you can add as many as you want.

syntax would be:

```lua
superkeys=include("superkeys/lib/superkeys")
engine.name="Superkeys"
skeys=superkeys:new()

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
### samples

this script will allow you to download samples that i've already converted to use with it.

however, you can easily take any sample library and convert to use with superkeys. in the `samples/` folder there is a utility script `convert.py` that is specific to each type of sample and shows basically how its done (its easy).

the current samples are from the following sources, which are free and do not restrict to distributing them for this purpose:

- The University of Iowa Musical Instrument Samples database which ["may be downloaded and used for any projects, without restrictions"](http://theremin.music.uiowa.edu/MIS.html).
- the pianobook which states that ["There are NO restrictions on their use (except selling them on as your own samples)"](https://www.pianobook.co.uk/faq/)

## license

MIT