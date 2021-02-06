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
			Buffer.new(context.server);
		});

		(0..15).do({arg i; 
			SynthDef("player"++i,{ 
				arg bufnum, amp, t_trig=0,envgate=1,
				attack=0.015,decay=1,release=2,sustain=0.9,
				sampleStart=0,sampleEnd=1,rate=1,pan=0,
				lpf=20000,hpf=10,
				secondsPerBeat=1,delayBeats=8,delayFeedback=1,delaySend=0;

				// vars
				var ender,snd;

				ender = EnvGen.ar(
					Env.new(
						curve: 'cubed',
						levels: [0,1,sustain,0],
						times: [attack+0.015,decay,release],
						releaseNode: 2,
					),
					gate: envgate,
				);
				
				snd = PlayBuf.ar(2, bufnum,
					rate:BufRateScale.kr(bufnum)*rate,
				 	startPos: ((sampleStart*(rate>0))+(sampleEnd*(rate<0)))*BufFrames.kr(bufnum),
				 	trigger:t_trig,
				);
		        snd = LPF.ar(snd,lpf);
		        snd = HPF.ar(snd,hpf);
				snd = Mix.ar([
					Pan2.ar(snd[0],-1+(2*pan),amp),
					Pan2.ar(snd[1],1+(2*pan),amp),
				]);
				snd = snd * amp * ender;
		        snd = snd*0.5 +
		        	((delaySend>0)*CombN.ar(
		        		snd,
						1,secondsPerBeat*delayBeats,secondsPerBeat*delayBeats*LinLin.kr(delayFeedback,0,1,2,128),0.5*delaySend // delayFeedback should vary between 2 and 128
					)); 
				Out.ar(0,snd)
			}).add;	
		});

		samplerPlayerSuperkeys = Array.fill(14,{arg i;
			Synth("player"++i, target:context.xg);
		});

		this.addCommand("superkeysrelease","", { arg msg;
			(0..199).do({arg i; sampleBuffSuperkeys[i].free});
		});
		this.addCommand("superkeysload","is", { arg msg;
			// lua is sending 0-index
			sampleBuffSuperkeys[msg[1]].free;
			sampleBuffSuperkeys[msg[1]] = Buffer.read(context.server,msg[2]);
		});

		this.addCommand("superkeyson","iifffffffffffff", { arg msg;
			// lua is sending 1-index
			samplerPlayerSuperkeys[msg[1]-1].set(
				\t_trig,1,
				\envgate,1,
				\bufnum,msg[2],
				\rate,msg[3],
				\amp,msg[4],
				\pan,msg[5],
				\attack,msg[6],
				\decay,msg[7],
				\sustain,msg[8],
				\release,msg[9],
				\lpf,msg[10],
				\hpf,msg[11],
				\secondsPerBeat,msg[12],
				\delayBeats,msg[13],
				\delayFeedback,msg[14],
				\delaySend,msg[15],
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
		(0..199).do({arg i; sampleBuffSuperkeys[i].free});
		(0..15).do({arg i; samplerPlayerSuperkeys[i].free});
	}
}
