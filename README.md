# superkeys

a voice allocator / sample player for norns

can input multiple samples of the same type (piano keys a2,c4,g5, etc.) and the best one will be selected and pitched.


clipping samples

```bash
ffmpeg -i .\Piano.ff.D5.aiff -af "silenceremove=1:0:-50dB" -y -to 00:00:05 test.wav
 ```