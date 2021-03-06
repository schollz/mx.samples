__author__ = "ezra buchla, zack scholl"

import shutil

from scipy import signal
from scipy.io import wavfile
import numpy as np 

debug_depop = False
if debug_depop:
    import matplotlib.pyplot as plt

# (adapted from ezra's excise.m, all mistakes are from zack)
# %% excise a portion of given (audio) signal with crossfade
# %%
# %% it is assumed that the exact final duration is flexible,
# %% so a fade time is programatically determined
# %%
# %% parameters:
# %% a, b: first and last indices of region to excise
# %% nw: window length (maximum crossfade duration in samples)
# %%
# %% returns:
# %% Y: new signal
# %% c: correlation peak value
# %% nf: actual count of crossfade samples
def excise(X, a, b, nw=1000):
    # count of excised samples
    nx = b-a+1;
    # restrict window size
    nw = np.amin([a-1, nw]);
    nw = np.amin([len(X)-b, nw]);

    # windows preceding and following excision,
    # which we'll examine for correlation
    W = X[a-nw:a];  
    V = X[b:b+nw];

    # find lag time maximizing cross-correlation
    C = signal.correlate(W,V,'full')
    lags = signal.correlation_lags(W.size,V.size,mode="full")
    # remove negative lags
    ipos =  np.where(lags>=0)
    C = C[ipos]
    lags = lags[ipos]
    idx = np.argmax(C)
    cmax = C[idx]
    r = int(lags[idx])
    # xfade duration
    nf = nw - r 

    # build output
    # initial segment
    Y0 = X[:a-nf]

    # ending segment
    Y1 = X[b+nf:]

    # calculate xfaded segment
    phi = np.linspace(0,1,nf)
    W = X[a-nf:a]
    V = X[b:b+nf]

    # FIXME:
    # should choose interpolation type based on degree of correlation
    # (linear if totally correlated, equal-power if uncorrelated)
    # for now, just use linear
    Yf = np.multiply(V,phi)
    Yf = Yf + np.multiply(W,1-phi)
    Y = Y0
    Y = np.append(Y,Yf)
    Y = np.append(Y,Y1)
    return Y

def depop(filename,newfilename,channel=0):
    # read in file
    samplerate, data = wavfile.read(filename)
    # collect data-type information and normalize
    original_type = data.dtype
    data_max = (np.iinfo(original_type).max)
    data = data.astype(float)
    data = data / data_max

    # compute basic properties
    length = data.shape[0] / samplerate
    num_channels = data.shape[1]
    time = np.linspace(0., length, data.shape[0])

    # stft of the channel
    # go through each band and, if its soft,
    # collect it to be averaged later
    f, t, Zxx = signal.stft(data[:, channel], samplerate, window=signal.get_window("hann",128),nperseg=128)
    zmean = np.zeros(Zxx[1,:].shape)
    znum = 0
    for i in range(Zxx.shape[0]):
    	z = 20*np.log10(np.abs(Zxx[i,:]))
    	z = z - np.mean(z[-500:])
        # find soft audio regions and use them for the average
        # arbitrary but works okay
    	if np.sum(z) < 10000:
    		zmean = np.add(zmean,z)
    		znum += 1

    # average all the soft bands
    zmean = zmean / znum 
    zmean = zmean - np.mean(zmean[-500:])
    z_std = np.std(zmean[-500:])

    peaks, _ = signal.find_peaks(zmean,height=z_std*6,prominence=10)
    if debug_depop:
        print(peaks)
        plt.plot(t,zmean)
        plt.plot(t[peaks],zmean[peaks],'o')
        plt.title("ch {}".format(channel))
        plt.show()

    for _, ind in enumerate(peaks):
        if t[ind] < 0.005 or t[ind] > length-0.005:
            continue
        # assume a pop width of 6 ms
        r = np.where(np.logical_and(time>t[ind]-0.003,time<t[ind]+0.003))
        score = zmean[ind]/z_std


        # anything over 20 sd's is probably a pop
        if score < 5:
            if debug_depop:
                print("too low score: {}".format(score))
            continue


        data0 = excise(data[:,0],r[0][0],r[0][-1])
        if num_channels > 1:
            data1 = excise(data[:,1],r[0][0],r[0][-1])
            newlen = min([len(data0),len(data1)])
            newdata = np.column_stack((data0[:newlen],data1[:newlen]))*data_max
        else:
            newdata = data0 

        wavfile.write(newfilename,samplerate,newdata.astype(original_type))
        return "removed a pop at {}".format(t[ind])
    return ""

def depop_file(filename,newfilename=""):
    if newfilename=="":
        newfilename="foo.wav"
    shutil.copy(filename,newfilename)
    for channel in range(0,2):
        for i in range(10):
            result = depop(newfilename,newfilename,channel)
            if result == "":
                break
            print(result + " in file " + filename + ", channel {}".format(channel+1))
    if newfilename == "foo.wav":
        shutil.copy(newfilename,filename)

#print("depopping")
#depop_file('79.2.3.1.0.wav')

# if debug_depop:
#   depop_file("54.1.2.1.0.wav","test1.wav")
