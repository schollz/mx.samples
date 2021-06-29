// Engine_MxSamples

// Inherit methods from CroneEngine
Engine_MxSamples : CroneEngine {

	// MxSamples specific
	var sampleBuffMxSamples;
	var sampleBuffMxSamplesDelay;
	var mxsamplesMaxVoices=40;
    var mxsamplesVoiceAlloc;
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
		sampleBuffMxSamplesDelay = Array.fill(mxsamplesMaxVoices, { arg i; 
			Buffer.alloc(context.server,48000,2);
		});

		SynthDef("mxPlayer",{ 
				arg bufnum,bufnumDelay, amp, t_trig=0,envgate=1,name=1,
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
		        	((delaySend>0)*BufCombN.ar(
		        		bufnumDelay,
		        		snd,
						secondsPerBeat*delayBeats,secondsPerBeat*delayBeats*LinLin.kr(delayFeedback,0,1,2,128),0.5*delaySend // delayFeedback should vary between 2 and 128
					)); 
					// delay w/ 30 voices = 1.5% (one core) per voice
					// w/o delay w/ 30 voices = 1.1% (one core) per voice
				// SendTrig.kr(Impulse.kr(1),name,1);
				DetectSilence.ar(snd,doneAction:2);
				// just in case, release after 1 minute
				FreeSelf.kr(TDelay.kr(DC.kr(1),60));
				Out.ar(0,snd)
		}).add;	

		this.addCommand("mxsamplesrelease","", { arg msg;
			(0..79).do({arg i; sampleBuffMxSamples[i].free});
		});
		this.addCommand("mxsamplesload","is", { arg msg;
			// lua is sending 0-index
			sampleBuffMxSamples[msg[1]].free;
			sampleBuffMxSamples[msg[1]] = Buffer.read(context.server,msg[2]);
		});

		this.addCommand("mxsampleson","iiffffffffffffff", { arg msg;
			var name=msg[1];
			if (mxsamplesVoiceAlloc.at(name)!=nil,{
				if (mxsamplesVoiceAlloc.at(name).isRunning==true,{
					("stealing "++name).postln;
					mxsamplesVoiceAlloc.at(name).free;
				});
			});
			mxsamplesVoiceAlloc.put(name,
				Synth("mxPlayer",[
				\bufnumDelay,sampleBuffMxSamplesDelay[msg[1]-1],
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
				\sampleStart,msg[16] ],target:context.server).onFree({
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

	}

	free {
		(0..79).do({arg i; sampleBuffMxSamples[i].free});
		(mxsamplesMaxVoices).do({arg i; sampleBuffMxSamplesDelay[i].free;});
    	mxsamplesVoiceAlloc.keysValuesDo({ arg key, value; value.free; });
	}
}
