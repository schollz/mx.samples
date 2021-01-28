// Engine_Superkeys

// Inherit methods from CroneEngine
Engine_Superkeys : CroneEngine {

	// Superkeys specific
	var sampleBuffSuperkeys;
	var samplerPlayerSuperkeys;
	// Superkeys ^

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		sampleBuffSuperkeys = Array.fill(200, { arg i; 
			// Buffer.read(context.server, "/home/we/dust/code/superkeys/samples/silence.wav"); 
			Buffer.new(context.server);
		});

		(0..13).do({arg i; 
			SynthDef("player"++i,{ 
				arg bufnum, amp, t_trig=0,envgate=1,
				attack=0.01,decay=1,release=0.5,sustain=0.8,
				sampleStart=0,sampleEnd=1,rate=1,pan=0,
				lpf=18000,resonance=1.0,hpf=10;
				// vars
				var ender,snd;

				ender = EnvGen.kr(
					Env.new(
						curve: 'cubed',
						levels: [0,1,sustain,0],
						times: [attack,decay,release],
						releaseNode: 2,
					),
					gate: envgate,
				);
				
				snd = PlayBuf.ar(2, bufnum,
					rate:BufRateScale.kr(bufnum)*rate,
				 	startPos: ((sampleStart*(rate>0))+(sampleEnd*(rate<0)))*BufFrames.kr(bufnum),
				 	trigger:t_trig,
				);
	        	// snd = MoogFF.ar(snd,lpf,resonance);
	        	// snd = HPF.ar(snd,hpf);
				snd = Mix.ar([
					Pan2.ar(snd[0],-1+(2*pan),amp),
					Pan2.ar(snd[1],1+(2*pan),amp),
				]);
				snd = snd * amp * ender;
				Out.ar(0,snd)
			}).add;	
		});

		samplerPlayerSuperkeys = Array.fill(14,{arg i;
			Synth("player"++i, target:context.xg);
		});

		this.addCommand("superkeysload","is", { arg msg;
			// lua is sending 0-index
			sampleBuffSuperkeys[msg[1]].free;
			sampleBuffSuperkeys[msg[1]] = Buffer.read(context.server,msg[2]);
		});

		this.addCommand("superkeyson","iiff", { arg msg;
			// lua is sending 1-index
			samplerPlayerSuperkeys[msg[1]-1].set(
				\t_trig,1,
				\envgate,1,
				\bufnum,msg[2],
				\rate,msg[3],
				\amp,msg[4],
			);
		});

		this.addCommand("superkeysoff","i", { arg msg;
			// lua is sending 1-index
			samplerPlayerSuperkeys[msg[1]-1].set(
				\envgate,0,
			);
		});

	}

	free {
		(0..99).do({arg i; sampleBuffSuperkeys[i].free});
		(0..13	).do({arg i; samplerPlayerSuperkeys[i].free});
	}
}
