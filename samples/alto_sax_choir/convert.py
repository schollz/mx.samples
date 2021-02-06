exec(open("../utils.py").read())
exec(open("../depop.py").read())

foldername = os.path.join("source")
fnames = glob.glob("source/*.wav")
fnames = list(fnames)
print(fnames)
for _, fname in enumerate(tqdm(fnames)):
    f = os.path.basename(fname)
    f = f.replace(' ','').split('.')[0]
    foo = f.split("_")
    print(foo)
    midival = str2midi(foo[2])
    dynamics = 1
    dynamic = 1
    variation = 1
    release = 0
    seconds = 12
    newname = "{}.{}.{}.{}.{}.wav".format(midival,dynamic,dynamics,variation,release)
    cmd = ['ffmpeg','-i',fname,'-af','silenceremove=1:0:-60dB','-y',newname]
    run(cmd)
