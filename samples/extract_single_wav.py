# <group name="KU100 F notes_with_pedal" loCC64="64" hiCC64="127">
#      <sample hiNote="21" loNote="21" rootNote="21" start="400000" end="1200000" path="samples/Claustrophobic Piano KU 100_NR.wav" seqPosition="1" loVel="120" hiVel="127"/>
#      <sample hiNote="21" loNote="21" rootNote="21" start="400000" end="1200000" path="samples/Claustrophobic Piano KU 100_NR.wav" seqPosition="2"
import os

from xml.etree import cElementTree as ET
from icecream import ic

mics = ["KU100", "MIX456", "M149"]
wwopedal = ["with_pedal", "without_pedal"]

for _, mic in enumerate(mics):
    for _, pedaltype in enumerate(wwopedal):
        try:
            os.mkdir(f"{mic}_{pedaltype}")
        except:
            pass
        lines = open(f"Claustrophobic Piano ({mic}).dspreset", "r").read().split("\n")
        dynamic = "F"
        getsamples = False
        for line in lines:
            line = line.strip()
            if line.startswith("<group name"):
                getsamples = False
                if f"MF notes_{pedaltype}" in line:
                    dynamic = 2
                    getsamples = True
                elif f" P notes_{pedaltype}" in line:
                    dynamic = 1
                    getsamples = True
                elif f" F notes_{pedaltype}" in line:
                    dynamic = 3
                    getsamples = True
            elif line.startswith("<sample") and getsamples:
                r = ET.fromstring(line)
                try:
                    note = int(r.get("rootNote"))
                except:
                    continue
                source = r.get("path")
                sstart = float(r.get("start")) / 48000.0
                duration = float(r.get("end")) / 48000.0 - sstart
                variation = int(r.get("seqPosition"))
                ic(line, dynamic, note, sstart, duration, variation)
                # <midinote>.<dynamic>.<dynamics>.<variation>.<release>.wav
                fname = f"{note}.{dynamic}.3.{variation}.0.wav"
                if not os.path.exists(f"{mic}_{pedaltype}/{fname}"):
                    cmd = f"ffmpeg -y -i  '{source}' -ss '{sstart}' -t '{duration}' {mic}_{pedaltype}/{fname}"
                    print(cmd)
                    os.system(cmd)
