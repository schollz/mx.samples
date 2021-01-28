~buff = Buffer.read(s, "C:\\Users\\zacks\\Downloads\\a4.wav");
~buff2 = Buffer.read(s, "C:\\Users\\zacks\\Downloads\\test.wav");
~buff3 = Buffer.read(s, "C:\\Users\\zacks\\go\\src\\github.com\\schollz\\superkeys\\samples\\piano\\piano.mf.74.wav")

(
(0..6).do({arg i;
	SynthDef("player"++i,{
	arg bufnum, amp, t_trig=0,envgate=1,
	attack=0.01,decay=1,release=0.5,sustain=0.8,
	sampleStart=0,sampleEnd=1,rate=1,timeStretch=1;
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

                                bufsnd = BufRd.ar(2,bufnum,
                                        Phasor.ar(
                                                trig:t_trig,
                                                rate:BufRateScale.kr(sampleBufnum)*rate,
                                                start:((sampleStart*(rate>0))+(sampleEnd*(rate<0))+rate.sign*0.2*(Line.kr(dur:)>=1))*BufFrames.kr(sampleBufnum),
                                                end:((sampleEnd*(rate>0))+(sampleStart*(rate<0)))*BufFrames.kr(sampleBufnum),
                                                resetPos:((sampleStart*(rate>0))+(sampleEnd*(rate<0)))*BufFrames.kr(sampleBufnum)
                                        )
                                        loop:0,
                                        interpolation:1
                                );
		
		snd = Warp1.ar(
			numChannels:2,
			bufnum:bufnum,
			pointer:LFSaw.ar(1/(BufDur.kr(bufnum)/timeStretch)).range(0,1), 
			freqScale:rate,
			windowSize:0.3,
			overlaps:8,
			windowRandRatio:0.0,
			interp:2
		);
	// cross-fade between Warp1 and regular BufRd

		// snd = PlayBuf.ar(2, bufnum,
		// 	rate:BufRateScale.kr(bufnum)*rate,
		// 	startPos: ((sampleStart*(rate>0))+(sampleEnd*(rate<0)))*BufFrames.kr(bufnum),
		// 	trigger:t_trig,
		// );
	snd = snd * amp * ender;
	Out.ar( [0,1],snd)
}).add;
});
)

~samplerPlayer = Array.fill(6,{arg i;Synth("player"++i,[\t_trig:0,\envgate:0], target:s);});
~samplerPlayer[0].set(\t_trig,1,\envgate,1,\bufnum,~buff3,\rate,40.midicps/40.midicps,\amp,1,\timeStretch,1);
~samplerPlayer[0].set(\envgate,0);

{BufDur.kr(~buff3)}.plot(1);

(
~samplerPlayer[0].set(\t_trig,1,\envgate,1,\bufnum,~buff,\rate,1,\amp,1);
~samplerPlayer[1].set(\t_trig,1,\envgate,1,\bufnum,~buff,\rate,44.midicps/40.midicps,\amp,1);
~samplerPlayer[2].set(\t_trig,1,\envgate,1,\bufnum,~buff2,\rate,47.midicps/40.midicps,\amp,1);
)
(
~samplerPlayer[0].set(\envgate,0);
~samplerPlayer[1].set(\envgate,0);
~samplerPlayer[2].set(\envgate,0);
)


{Line.kr(dur:1)}.plot(duration:2);


x=Synth("player0",[\bufnum:~buff,\amp:1.0,\t_trig:0,\envgate:0]);

x.set(\t_trig,1,\envgate,1,\bufnum,~buff,\rate,42.midicps/40.midicps);
x.set(\t_trig,1,\envgate,1,\bufnum,~buff2,\rate,0.5);
x.set(\envgate,0);




(
{
    EnvGen.kr(
        Env.new(
            levels: [0, 1, 0.5, 0],
            times: [0.01, 0.01, 0.01],
            releaseNode: 2 // sustains at level 0.5 until gate is closed
        ),
        gate: 1
    );
}.plot(duration: 1);
)


Env.adsr(0.02, 0.2, 0.25, 1, 1, -4).test(2).plot;

(
{
    EnvGen.kr(
        Env.new(
			curve: 'cubed',
            levels: [0.0, 1, 0.2, 0.0],
            times: [0.1, 0.1, 0.3],
            releaseNode: 2 // sustains at level 0.5 until gate is closed

        ),
        gate: Trig.kr(Impulse.kr(3), dur: 0.7)
    );
}.plot(duration: 1);
)
