function tone = MakeTone(duration,freq,fs)
     t=0:1/fs:duration-1/fs;
     tone = cos(2*pi* freq*t)*.3;
end

