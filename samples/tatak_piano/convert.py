exec(open("../utils.py").read())
exec(open("../depop.py").read())

fnames = glob.glob("Tatak - Felt Piano Full/Tatak Felt Piano Full Samples/*.wav")
for _, fname in enumerate(fnames):
    f = os.path.basename(fname)
    # 'Steinway Grand PIANOBOOK/Steinway Samples/Steinway_G#4_Dyn4_RR2.wav'
    # 'Steinway Grand PIANOBOOK/Steinway Samples/Steinway_Release_A1.wav'
    foo = f.replace("-"," ").replace("_"," ").split(".")[0].split()
    dynamics = 2
    dynamic = 1
    if foo[3] == "mp":
        dynamic = 2
    release = 0
    variation=1
    midival = 0
    if foo[3] == "KR":
        release = 1
    midival = str2midi(foo[4])
    newname = "{}.{}.{}.{}.{}.wav".format(midival,dynamic,dynamics,variation,release)
    cmd = 'ffmpeg -i "{}" -af "silenceremove=1:0:-50dB" -y -to 00:00:06 {}'.format(fname,newname)
    # cmd = 'ffmpeg -i "{}" -af "silenceremove=start_periods=1:start_duration=1:start_threshold=-63dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1:start_duration=1:start_threshold=-63dB:detection=peak,aformat=dblp,areverse" -y {}'.format(fname,newname)
    #normalize_volume(newname)
    try:
        os.system(cmd)
        depop_file(newname)
    except Exception as e:
        print(e)
        print(newname)


