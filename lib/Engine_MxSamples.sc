// Engine_MxSamples

// Inherit methods from CroneEngine
Engine_MxSamples : CroneEngine {

	// MxSamples specific
	var sampleBuffMxSamples;
	var samplerPlayerMxSamples;
	// MxSamples ^

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		sampleBuffMxSamples = Array.fill(200, { arg i; 
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
				 	startPos: ((sampleEnd*(rate<0))*BufFrames.kr(bufnum))+(sampleStart/1000*48000),
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

		samplerPlayerMxSamples = Array.fill(14,{arg i;
			Synth("player"++i, target:context.xg);
		});

		this.addCommand("mxsamplesrelease","", { arg msg;
			(0..199).do({arg i; sampleBuffMxSamples[i].free});
		});
		this.addCommand("mxsamplesload","is", { arg msg;
			// lua is sending 0-index
			sampleBuffMxSamples[msg[1]].free;
			sampleBuffMxSamples[msg[1]] = Buffer.read(context.server,msg[2]);
		});

		this.addCommand("mxsampleson","iiffffffffffffff", { arg msg;
			// lua is sending 1-index
			samplerPlayerMxSamples[msg[1]-1].set(
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
				\sampleStart,msg[16],
			);
		});

		this.addCommand("mxsamplesoff","i", { arg msg;
			// lua is sending 1-index
			samplerPlayerMxSamples[msg[1]-1].set(
				\envgate,0,
			);
		});

	}

	free {
		(0..199).do({arg i; sampleBuffMxSamples[i].free});
		(0..15).do({arg i; samplerPlayerMxSamples[i].free});
	}
}
