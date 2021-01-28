samples provided by University of Iowa Electronic Music Studios

http://theremin.music.uiowa.edu/


```bash
# from within this directory

# download files
wget -x -i urls.txt --no-clobber

# install python3, ffmpeg
sudo apt install python3 python3-pip ffmpeg # password is 'sleep' 

# install audiolazy
sudo -H python3 -m pip install audiolazy

# convert to norns format
python3 convert.py
```
