exec(open("../utils.py").read())
exec(open("../depop.py").read())

foldername = os.path.join("theremin.music.uiowa.edu","sound files","MIS","Piano_Other","piano")
fnames = glob.glob(os.path.join(foldername,"*.aiff"))
fnames = list(fnames)
for _, fname in enumerate(tqdm(fnames)):
    f = os.path.basename(fname)
    foo = f.split(".")
    midival = str2midi(foo[2])
    dynamics = 3
    dynamic = 1
    if foo[1] == "mf":
        dynamic = 2
    elif foo[1] == "ff":
        dynamic = 3
    variation = 1
    release = 0
    newname = "{}.{}.{}.{}.{}.wav".format(midival,dynamic,dynamics,variation,release)
    seconds = 6 
    if ".ff." in fname:
        seconds=8
    elif ".pp." in fname:
        seconds=4
    cmd = 'ffmpeg -i "{}" -af "silenceremove=1:0:-60dB" -y -to 00:00:0{} {}'.format(fname,seconds,newname)
    run(cmd)
    try:
        depop_file(newname)
    except:
        pass


