function [Signal,t] = generate_Noises(cf,bw,T,fs,level)

t = 0:1/fs:T-1/fs;          % time vector in [s]

if bw == 0
    %% Generate tone in time
    tone = sin(2*pi*cf*t');
else     
    %% Generate Broad band pink noise
    tone = pinknoise(round(T*fs));
    BW = [cf/2^(1/2*bw) cf*2^(1/2*bw)];  
    tone = bandpass(tone,BW,fs);
    
end

%% Create a window function
window = hannfl(round(T*fs),round(0.05*fs),round(0.05*fs));
% Apply window to three signals
tone = tone.*window;
tone = tone./max(abs(tone));
%% Level scaling
% The level is scaled down from a full scale signal.
Level = 10^(level/20);
Signal = tone.*Level;










