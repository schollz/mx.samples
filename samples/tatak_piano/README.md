
download from  https://www.pianobook.co.uk/library/ghost-piano/

enter your email and then right-click on 'ESX24'. then click "Copy Link address" and then enter it into the terminal:


```
# install python3, ffmpeg
sudo apt install python3 python3-pip ffmpeg 
# install audiolazy
sudo -H python3 -m pip install audiolazy

wget <link address>

# change name and unzip
mv *index* dl.zip
unzip dl.zip

# remove unnessecary
rm -rf dl.zip __MACOSX

# convert to format
python3 convert.py

# if successful then 
rm -rf 'Ghost Piano'
```


