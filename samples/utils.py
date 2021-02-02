import glob
import os
import subprocess
import sys

from tqdm import tqdm
from audiolazy import str2midi

def run(cmd):
    if not isinstance(cmd,list):
        cmd = cmd.split()
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

