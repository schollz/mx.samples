import mimetypes
import re

from pathlib import Path

exec(open("./utils.py").read())
exec(open("./depop.py").read())

# TODO: separate files by name???
#       some sample sets contain multiple styles

# TODO: remove non-musical audio files???
#       these might just be the ones with no note info...

def find_dynamic(path):
    # replace _ with - because _ is included in \w
    cleaned_path = path.replace("_"," ")
    # tries to find dynamics and *not* notes
    # TODO: this struggles if dynamic is at the end
    match = re.search(r"(\b|\W)(m?(f+|p+))[^#0-9](\b|\W)", cleaned_path, flags=re.IGNORECASE)
    if match is None:
        return
    else:
        return match.group(2)

def is_audio(path):
    try:
        if "audio" in mimetypes.guess_type(path)[0]:
            return True
        else:
            return False
    except TypeError:
        # path is not a file
        return False

def convert(file, destination, dynamics_dict):
    # get the filename only
    filename = os.path.basename(file)
    # remove the extension
    filename = os.path.splitext(filename)[0]

    # get the note
    # NB: if this doesn't work well, there are fancier options like
    # https://github.com/mzucker/python-tuner/blob/master/tuner.py
    match = re.search(r"[a-g]{1}[#b]?[0-9]{1}", filename, flags=re.IGNORECASE)
    if match is None:
        # TODO: no note in filename
        #       maybe these can be discarded in most cases?
        pass
    midival = str2midi(match.group(0))

    # TODO: velocity instead of dynamics?
    dynamic = find_dynamic(filename)
    if not dynamic:
        dynamics = 1
        dynamic = 1
    else:
        dynamics = len(dynamics_dict)
        dynamic = dynamics_dict[dynamic]

    release = 0
    seconds = 12

    # format filename, incrementing for variations
    variation = 1
    new_name = "{}.{}.{}.{}.{}.wav".format(midival,dynamic,dynamics,variation,release)
    output = destination + '/' + new_name
    while os.path.isfile(output):
        variation += 1
        new_name = "{}.{}.{}.{}.{}.wav".format(midival,dynamic,dynamics,variation,release)
        output = destination + '/' + new_name

    cmd = ['ffmpeg','-i',file,'-ac','2','-af','silenceremove=1:0:-60dB','-y',output]
    run(cmd)

#######################################
# Start here
#######################################

folder = os.path.abspath(sys.argv[1])
# TODO: allow setting output path
destination = sys.argv[2]

# filter folder to just audio files (in any subfolder)
audio_files = [x for x in list(Path(folder).rglob('*')) if is_audio(x)]

# find the dynamics in the filenames
# number of dynamics: len(dynamics)
dynamics = set([find_dynamic(x.name) for x in audio_files])

dynamics_dict = {}
if len(dynamics) > 1:
    # create dynamics translation layer for this sample set
    translation_layer = {
        "ppp": 1,
        "pp": 2,
        "p": 3,
        "mp": 4,
        "mf": 5,
        "f": 6,
        "ff": 7,
        "fff": 8
    }

    # just keep the ones used by this sample set
    for d in dynamics:
        dynamics_dict[d] = translation_layer[d.lower()]

    # sort by value, going from ppp to fff
    t2 = dict(sorted(dynamics_dict.items(), key=lambda item: item[1]))

    # reassign dynamic values to the remaining dynamics
    # TODO: this is where velocity values could be assigned
    dynamic = 1
    for d in t2:
        dynamics_dict[d] = dynamic
        dynamic += 1

# make sure destination exists
if not os.path.exists(destination):
    os.makedirs(destination)

# do the conversion
for file in tqdm(audio_files):
    convert(file, destination, dynamics_dict)
