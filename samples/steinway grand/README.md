
download from http://www.jonmeyermusic.com/samples

enter your email and then right-click on 'Steinway Grand 1.1 (260bm)'. then click "Copy Link address" and then enter it into the terminal:

```
wget <link address>

# change name and unzip
mv *dl* dl.zip
unzip dl.zip

# remove unnessecary
rm -rf dl.zip __MACOSX

# convert to format
python3 convert.py

# if successful then 
rm -rf 'Steinway Grand PIANOBOOK'
```


