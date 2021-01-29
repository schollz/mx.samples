
download from http://www.jonmeyermusic.com/samples

enter your email and then right-click on 'Kawai Felt Piano Samples (700 mb)'. then click "Copy Link address" and then enter it into the terminal:

```
wget <link address>

# change name and unzip
mv *dl* dl.zip
unzip dl.zip

# remove unnessecary
rm dl.zip
rm -rf Data *nkc *nki *nkr *MACOSX* Resources

# convert to format
python3 convert.py

# if successful then 
rm 66*.wav
rm 62*.wav
rm -rf 'Kawai Felt Piano Samples' 
```


