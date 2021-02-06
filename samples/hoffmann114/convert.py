exec(open("../utils.py").read())
exec(open("../depop.py").read())

fnames = glob.glob("Hoffmann114/*.wav")
for _, fname in enumerate(fnames):
    f = os.path.basename(fname)
    foo = f.replace("-"," ").replace("_"," ").split(".")[0].split()
    dynamics = 2
    dynamic = 1
    if 'ff' in foo[1]:
        dynamic = 2
    variation=1
    if '2' in foo[1]:
        variation = 2
    release = 0
    if 'felt' in foo[1]:
        release = 1
    midival = 0
    midival = str2midi(foo[2])
    newname = "{}.{}.{}.{}.{}.wav".format(midival,dynamic,dynamics,variation,release)
    cmd = 'ffmpeg -i "{}" -y {}'.format(fname,newname)
    os.system(cmd)
    # cmd = 'ffmpeg -i "{}" -af "silenceremove=start_periods=1:start_duration=1:start_threshold=-63dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1:start_duration=1:start_threshold=-63dB:detection=peak,aformat=dblp,areverse" -y {}'.format(fname,newname)
    #normalize_volume(newname)
    # try:ls
    #     os.system(cmd)
    #     depop_file(newname)
    # except Exception as e:
    #     print(e)
    #     print(newname)


