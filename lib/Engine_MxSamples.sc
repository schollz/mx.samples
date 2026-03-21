// Engine_MxSamples

// Inherit methods from CroneEngine
Engine_MxSamples : CroneEngine {

	// <mxsamples>
	var sampleBuffMxSamples;
	var sampleBuffMxSamplesDelay;
	var mxsamplesMaxVoices=40;
	var mxsamplesFX;
	var mxsamplesBusDelay;
	var mxsamplesBusReverb;
	var fnNoteOn, fnNoteOff;
	var mxsamplesVoices;
	var mxsamplesVoicesOn;
	var pedalSustainOn=false;
	var pedalSostenutoOn=false;
	var pedalSustainNotes;
	var pedalSostenutoNotes;
	// </mxsamples>

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		// <mxsamples>
		mxsamplesVoices=Dictionary.new;
		mxsamplesVoicesOn=Dictionary.new;
		pedalSustainNotes=Dictionary.new;
		pedalSostenutoNotes=Dictionary.new;

		context.server.sync;

		sampleBuffMxSamples = Array.fill(80, { arg i; 
			Buffer.new(context.server);
		});
		sampleBuffMxSamplesDelay = Buffer.alloc(context.server,48000,2);

		SynthDef("mxfx",{ 
			arg inDelay, inReverb, reverb=0.05, out, secondsPerBeat=1,delayBeats=4,delayFeedback=0.1,bufnumDelay;
			var snd,snd2,y,z;

			// delay
			snd = In.ar(inDelay,2);
			snd = CombC.ar(
				snd,
				2,
				secondsPerBeat*delayBeats,
				secondsPerBeat*delayBeats*LinLin.kr(delayFeedback,0,1,2,128),// delayFeedback should vary between 2 and 128
			); 
			Out.ar(out,snd);

			// reverb
			snd2 = In.ar(inReverb,2);
			snd2 = DelayN.ar(snd2, 0.03, 0.03);
			snd2 = CombN.ar(snd2, 0.1, {Rand(0.01,0.099)}!32, 4);
			snd2 = SplayAz.ar(2, snd2);
			snd2 = LPF.ar(snd2, 1500);
			5.do{snd2 = AllpassN.ar(snd2, 0.1, {Rand(0.01,0.099)}!2, 3)};
			snd2 = LPF.ar(snd2, 1500);
			snd2 = LeakDC.ar(snd2);
			Out.ar(out,snd2);
		}).add;

		SynthDef("mxPlayer",{ 
				arg outDelay,outReverb,bufnum, amp=0.0, t_trig=0,envgate=1,name=1,
				attack=0.015,decay=1,release=2,sustain=0.9,
				sampleStart=0,sampleEnd=1,rate=1,pan=0,
				lpf=20000,hpf=10,delaySend=0,reverbSend=0, noiseLevel=0;

				// vars
				var ender,snd, noise;

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

				// Noise
				noise = HPF.ar(in: Mix.new([PinkNoise.ar(0.5), Dust.ar(5,1)]),
											 freq: 2000,
											 mul: Amplitude.kr(snd,
											 									 attackTime: 0.1,
											 									 releaseTime: 0.5,
																				 mul: noiseLevel));
				
				snd = Mix.new([snd, noise]);

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
		mxsamplesFX = Synth.new("mxfx",[\out,0,\inDelay,mxsamplesBusDelay,\inReverb,mxsamplesBusReverb]);
		context.server.sync;


		// initialize 
		// intialize helper functions		
		fnNoteOff = {
			arg name;
			mxsamplesVoicesOn.removeAt(name);
			if (pedalSustainOn==true,{
				pedalSustainNotes.put(name,1);
			},{
				if ((pedalSostenutoOn==true)&&(pedalSostenutoNotes.at(name)!=nil),{
					// do nothing, it is a sostenuto note
				},{
					// remove the sound
					mxsamplesVoices.at(name).set(\envgate,0);
				});
			});
		};


		this.addCommand("mxsamplesrelease","", { arg msg;
			(0..79).do({arg i; sampleBuffMxSamples[i].free});
		});
		this.addCommand("mxsamplesload","is", { arg msg;
			// lua is sending 0-index
			sampleBuffMxSamples[msg[1]].free;
			sampleBuffMxSamples[msg[1]] = Buffer.read(context.server,msg[2]);
		});

		this.addCommand("mxsampleson","iifffffffffffff", { arg msg;
			var name=msg[1];
			if (mxsamplesVoices.at(name)!=nil,{
				if (mxsamplesVoices.at(name).isRunning==true,{
					("stealing "++name).postln;
					mxsamplesVoices.at(name).free;
				});
			});
			mxsamplesVoices.put(name,
				Synth.before(mxsamplesFX,"mxPlayer",[
					\t_trig,1,
					\outDelay,mxsamplesBusDelay,
					\outReverb,mxsamplesBusReverb,
					\envgate,1,
					\bufnum,sampleBuffMxSamples[msg[2]],
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
					\sampleStart,msg[14],
					\noiseLevel,msg[15] ]).onFree({
					("freed "++name).postln;
					NetAddr("127.0.0.1", 10111).sendMsg("voice",name,0);
				});
			);
			mxsamplesVoicesOn.put(name,1);
			NodeWatcher.register(mxsamplesVoices.at(name));
		});

		this.addCommand("mxsamplesoff","i", { arg msg;
			// lua is sending 1-index
			var name=msg[1];
			if (mxsamplesVoices.at(name)!=nil,{
				if (mxsamplesVoices.at(name).isRunning==true,{
					fnNoteOff.(name);
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

		this.addCommand("mxsamples_sustain", "i", { arg msg;
			pedalSustainOn=(msg[1]==1);
			if (pedalSustainOn==false,{
				// release all sustained notes
				pedalSustainNotes.keysValuesDo({ arg note, val; 
					if (mxsamplesVoicesOn.at(note)==nil,{
						pedalSustainNotes.removeAt(note);
						fnNoteOff.(note);
					});
				});
			},{
				// add currently down notes to the pedal
				mxsamplesVoicesOn.keysValuesDo({ arg note, val; 
					pedalSustainNotes.put(note,1);
				});
			});
		});

		this.addCommand("mxsamples_sustenuto", "i", { arg msg;
			pedalSostenutoOn=(msg[1]==1);
			if (pedalSostenutoOn==false,{
				// release all sustained notes
				pedalSostenutoNotes.keysValuesDo({ arg note, val; 
					if (mxsamplesVoicesOn.at(note)==nil,{
						pedalSostenutoNotes.removeAt(note);
						fnNoteOff.(note);
					});
				});
			},{
				// add currently held notes
				mxsamplesVoicesOn.keysValuesDo({ arg note, val;
					pedalSostenutoNotes.put(note,1);
				});
			});
		});



	}

	free {
		(0..79).do({arg i; sampleBuffMxSamples[i].free});
		mxsamplesVoices.keysValuesDo({ arg key, value; value.free; });
		mxsamplesBusDelay.free;
		mxsamplesBusReverb.free;
		mxsamplesFX.free;
		sampleBuffMxSamplesDelay.free;
	}
}
