exec(open("../utils.py").read())
exec(open("../depop.py").read())

foldername = "source"
fnames = glob.glob(os.path.join(foldername,"*.aif"))
fnames = list(fnames)
for _, fname in enumerate(tqdm(fnames)):
    f = os.path.basename(fname)
    foo = f.split(".")
    midival = str2midi(foo[4])
    dynamics = 1
    dynamic = 1
    variation = 1
    release = 0
    newname = "{}.{}.{}.{}.{}.wav".format(midival,dynamic,dynamics,variation,release)
    seconds = 8
    cmd = ['ffmpeg','-i',fname,'-af','silenceremove=1:0:-60dB','-y','-to','00:00:0{}'.format(seconds),newname]
    run(cmd)
    try:
        depop_file(newname)
    except Exception as e:
        print(e)
        print(newname)
        sys.exit(1)


