import glob
import os

from audiolazy import str2midi
from tqdm import tqdm

foldername = os.path.join("theremin.music.uiowa.edu","sound files","MIS","Piano_Other","piano")
fnames = glob.glob(os.path.join(foldername,"*.aiff"))
for _, fname in tqdm(enumerate(fnames)):
    f = os.path.basename(fname)
    foo = f.split(".")
    newname = "piano."+foo[1]+"."+str(str2midi(foo[2]))+".wav"
    seconds = 6 
    if ".ff." in fname:
        seconds=8
    elif ".pp." in fname:
        seconds=4
    cmd = 'ffmpeg -i "{}" -af "silenceremove=1:0:-60dB" -y -to 00:00:0{} {}'.format(fname,seconds,newname)
    # cmd = 'ffmpeg -i "{}" -af "silenceremove=start_periods=1:start_duration=1:start_threshold=-63dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1:start_duration=1:start_threshold=-63dB:detection=peak,aformat=dblp,areverse" -y {}'.format(fname,newname)
    os.system(cmd)

