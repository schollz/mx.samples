import glob
import os
import subprocess
import sys

from audiolazy import str2midi

def run(cmd):
    proc = subprocess.Popen(cmd,
        stdout = subprocess.PIPE,
        stderr = subprocess.PIPE,
    )
    stdout, stderr = proc.communicate()
 
    return proc.returncode, stdout, stderr

def max_volume(fname):
    cmd = 'ffmpeg -i '+fname+' -af volumedetect -vn -sn -dn -f null /dev/null'
    _,_,stderr = run(cmd.split())
    for _,line in enumerate(stderr.decode("utf-8").split("\n")):
        if "max_volume:" in line:
            print(line)
            v = line.split("max_volume:")[1]
            v = v.split()[0]
            return float(v)
    return 0

def normalize_volume(fname):
    v = max_volume(fname)
    if v >= 0:
        print("don't need to normalize "+fname)
        return
    v = v * -1
    print("adding +{}dB to {} ".format(v,fname))
    cmd = 'ffmpeg -i '+fname+' -af volume='+str(v)+'dB temp.wav'
    run(cmd.split())
    os.rename('temp.wav',fname)

fnames = glob.glob("Steinway Grand PIANOBOOK/Steinway Samples/*.wav")
for _, fname in enumerate(fnames):
    f = os.path.basename(fname)
    # 'Steinway Grand PIANOBOOK/Steinway Samples/Steinway_G#4_Dyn4_RR2.wav'
    # 'Steinway Grand PIANOBOOK/Steinway Samples/Steinway_Release_A1.wav'
    foo = f.split(".")[0].split("_")
    dynamics = 4
    dynamic = 1
    if foo[2] == "Dyn2":
        dynamic = 2
    elif foo[2] == "Dyn3":
        dynamic = 3
    elif foo[2] == "Dyn4":
        dynamic = 4
    variation = 1
    if len(foo) > 3 and foo[3] == "RR2":
        variation = 2
    release = 0
    midival = 0
    if foo[1] == "Release":
        release = 1
        midival = str2midi(foo[2])
    else:
        midival = str2midi(foo[1])
    newname = "{}.{}.{}.{}.{}.wav".format(midival,dynamic,dynamics,variation,release)
    seconds = 6 
    if " f " in fname:
        seconds=8
    elif " p " in fname:
        seconds=4
    cmd = 'ffmpeg -i "{}" -af "silenceremove=1:0:-60dB" -y -to 00:00:0{} {}'.format(fname,seconds,newname)
    # cmd = 'ffmpeg -i "{}" -af "silenceremove=start_periods=1:start_duration=1:start_threshold=-63dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1:start_duration=1:start_threshold=-63dB:detection=peak,aformat=dblp,areverse" -y {}'.format(fname,newname)
    os.system(cmd)
    #normalize_volume(newname)


