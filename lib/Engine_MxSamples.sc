// Engine_MxSamples

// Inherit methods from CroneEngine
Engine_MxSamples : CroneEngine {

	// MxSamples specific
	var sampleBuffMxSamples;
	var sampleBuffMxSamplesDelay;
	var mxsamplesMaxVoices=40;
    var mxsamplesVoiceAlloc;
    var mxsamplesFX;
    var mxsamplesBusDelay;
    var mxsamplesBusReverb;
	// MxSamples ^

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		mxsamplesVoiceAlloc=Dictionary.new(mxsamplesMaxVoices);

		context.server.sync;

		sampleBuffMxSamples = Array.fill(80, { arg i; 
			Buffer.new(context.server);
		});
		sampleBuffMxSamplesDelay = Buffer.alloc(context.server,48000,2);

		SynthDef("mxfx",{ 
			arg inDelay, inReverb, reverb=0.03, out, secondsPerBeat=1,delayBeats=8,feedback=1,bufnumDelay;
			var snd,snd2;

			// delay
			snd = In.ar(inDelay,2);
			snd = BufCombN.ar(
        		bufnumDelay,
        		snd,
				secondsPerBeat*delayBeats,secondsPerBeat*delayBeats*LinLin.kr(feedback,0,1,2,128),// delayFeedback should vary between 2 and 128
			); 
			Out.ar(out,snd);

			// reverb
			// reverb predelay time :
			snd2 = In.ar(inReverb,2);
			z = DelayN.ar(snd2, 0.048);
			// 7 length modulated comb delays in parallel :
			y = Mix.ar(Array.fill(7,{ CombL.ar(z, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), 15) }));
			// two parallel chains of 4 allpass delays (8 total) :
			4.do({ y = AllpassN.ar(y, 0.050, [0.050.rand, 0.050.rand], 1) });
			// add original sound to reverb and play it :
			snd2=snd2+(reverb*y);
			snd2=HPF.ar(snd2,20);
			Out.ar(out,snd2);
		}).add;

		SynthDef("mxPlayer",{ 
				arg outDelay,outReverb,bufnum, amp=0.0, t_trig=0,envgate=1,name=1,
				attack=0.015,decay=1,release=2,sustain=0.9,
				sampleStart=0,sampleEnd=1,rate=1,pan=0,
				lpf=20000,hpf=10,delaySend=0,reverbSend=0;

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

				// SendTrig.kr(Impulse.kr(1),name,1);
				DetectSilence.ar(snd,doneAction:2);
				// just in case, release after 1 minute
				FreeSelf.kr(TDelay.kr(DC.kr(1),60));
				Out.ar(outDelay,snd*delaySend);
				Out.ar(outReverb,snd*reverbSend);
				Out.ar(0,snd)
		}).add;	

		// initialize fx synth and bus
		context.server.sync;
		mxsamplesBusDelay = Bus.audio(context.server,2);
		mxsamplesBusReverb = Bus.audio(context.server,2);
		context.server.sync;
		mxsamplesFX = Synth.new("mxfx",[\out,0,\inDelay,mxsamplesBusDelay,\inReverb,mxsamplesBusDelay]);
		context.server.sync;


		this.addCommand("mxsamplesrelease","", { arg msg;
			(0..79).do({arg i; sampleBuffMxSamples[i].free});
		});
		this.addCommand("mxsamplesload","is", { arg msg;
			// lua is sending 0-index
			sampleBuffMxSamples[msg[1]].free;
			sampleBuffMxSamples[msg[1]] = Buffer.read(context.server,msg[2]);
		});

		this.addCommand("mxsampleson","iiffffffffffff", { arg msg;
			var name=msg[1];
			if (mxsamplesVoiceAlloc.at(name)!=nil,{
				if (mxsamplesVoiceAlloc.at(name).isRunning==true,{
					("stealing "++name).postln;
					mxsamplesVoiceAlloc.at(name).free;
				});
			});
			mxsamplesVoiceAlloc.put(name,
				Synth.before(mxsamplesFX,"mxPlayer",[
				\t_trig,1,
				\outDelay,mxsamplesBusDelay,
				\outReverb,mxsamplesBusReverb,
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
				\delaySend,msg[12],
				\reverbSend,msg[13],
				\sampleStart,msg[14] ],target:context.server).onFree({
					("freed "++name).postln;
					NetAddr("127.0.0.1", 10111).sendMsg("voice",name,0);
				});
			);
			NodeWatcher.register(mxsamplesVoiceAlloc.at(name));
		});

		this.addCommand("mxsamplesoff","i", { arg msg;
			// lua is sending 1-index
			var name=msg[1];
			if (mxsamplesVoiceAlloc.at(name)!=nil,{
				if (mxsamplesVoiceAlloc.at(name).isRunning==true,{
					mxsamplesVoiceAlloc.at(name).set(
						\envgate,0,
					);
				});
			});
		});

		this.addCommand("mxsamples_delay_time","f", { arg msg;
			mxsamplesFX.set(\secondsPerBeat,msg[1])
		});

		this.addCommand("mxsamples_delay_beats","f", { arg msg;
			mxsamplesFX.set(\delayBeats,msg[1])
		});

		this.addCommand("mxsamples_delay_feedback","f", { arg msg;
			mxsamplesFX.set(\delayFeedback,msg[1])
		});


	}

	free {
		(0..79).do({arg i; sampleBuffMxSamples[i].free});
    	mxsamplesVoiceAlloc.keysValuesDo({ arg key, value; value.free; });
    	mxsamplesBusDelay.free;
    	mxsamplesBusReverb.free;
    	mxsamplesFX.free;
    	sampleBuffMxSamplesDelay.free;
	}
}
