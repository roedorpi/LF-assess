function varargout = generate_Tones(cf,T,fs,level)

t = 0:1/fs:T-1/fs;          % time vector in [s]

%% Generate stimuli in time
tone = sin(2*pi*cf*t);

%% Create a window function
window = hannfl(round(T*fs),round(0.05*fs),round(0.05*fs));
% Apply window to three signals
tone = tone'.*window;

%% Level scaling
% The level is scaled down from a full scale signal.
Level = 10^(level/20);
tone = tone.*Level;

if nargout == 2
    varargout{1} = tone;
    varargout{2} = t;
elseif nargout == 1
    varargout{1} = tone;
end






