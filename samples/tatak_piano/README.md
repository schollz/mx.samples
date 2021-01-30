
download from  https://www.pianobook.co.uk/library/ghost-piano/

enter your email and then right-click on 'ESX24'. then click "Copy Link address" and then enter it into the terminal:

```
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


