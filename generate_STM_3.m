    function [stm,tone1, tone2,t] = generate_STM_3(varargin)
%function [stm,tone1, tone2,t] = generate_STM_3(cf,fm_CO,fm_Hz,m_dB,T,fs,level,SigFilts,LEQ)
% Purpose of this function is to generate a STM tone signal with the folowing.
% Inputs:
 % nOctaves = Band width for frequency modulation
 % cf = fundamental frequency
 % fm_CO = spectral modulation density [cycles/octave]
 % fm_HZ = Temporal modulation [Hz]
 % m_dB = Modulation depth [dB] (0 dB = full modulation)
 % T = Time duration of STM sequence [s]
 % fs = sampling frequency
 % level = presentation level in dBFS -- see calibration for details
 % SigFilts = low pass and loudness compensation filters
 % LEQ = loudness compensation based on headphone max output variable from
 % heaphone sensitivity files 
% Outputs:
 % stm = Spectrotemporal modulated tone stimulus signal of length T
 % tone1 = tone at fundamental frequency stimulus signal of length T
 % tone2 = same as tone1
 % t = time vector
 % Output stimuli are filtered with the a loudness compensation filter to
 % present all side bands at an equal relative loudness. Additonaly the
 % levels of the three output signals are randomized within 1.5 dB to
 % avoid loudness cues in a 3AFC paradigm for modulation detection. 
cf = varargin{1};
fm_CO = varargin{2};
fm_Hz = varargin{3};
m_dB = varargin{4};
T = varargin{5};
DnSampRate = 10;
fs = varargin{6}/DnSampRate;
level = varargin{7};
SigFilts = varargin{8};
LEQ = varargin{9};
LoudEQ = varargin{10};
NormType = varargin{11};
t = 0:1/fs:T-1/fs;          % time vector in [s]
m = 10^(m_dB/20);           % convert modulation depth [dB] to linear

%% Generate stimuli in time
tone = sin(2*pi*cf*t);
% both frequency and time
if fm_CO ~= 0 && fm_Hz ~= 0 % both frequency and time modulation 
    stm = sin(2*pi*cf.*t + m*sin(2*pi*fm_CO.*t+pi*rand)).*(1 + m*sin(2*pi*fm_Hz.*t+pi*rand));
elseif  fm_CO == 0  % only time modulation
    stm = sin(2*pi*cf.*t).*(1 + m*sin(2*pi*fm_Hz.*t+pi*rand));
elseif  fm_Hz == 0  % only frequency modulation
    stm = sin(2*pi*cf.*t + m*sin(2*pi*fm_CO.*t+pi*rand));
else
    stm = tone;
end


%% loudness Adjustments
% this is to compensate for the change in loudness as a function of
% frequency, is only relevant for stimuli that have frequency content that
% is greater that one ERB or critical band. The idea is to boos the lower
% frequency components so they are perceived as loud as the rest of the
% frequency components of the signal, in this way the audibility of the
% modulation is not only dependent on the audibility of the higher 
% sidebands of the modulated signal, but both lower and upper side bands 
% should contribute equaly to the detection. 

if strcmp(LoudEQ,'On')
    
    % use the earphone sensitivity to calculate the expected SPL of the desired
    % signal. This level is used to find the correct loudness compensation
    % curve. It is not used to get the desired presentation level. 
    if cf <= 250
        SPL_0dBFS = [LEQ.Frequencies',LEQ.LdB(1,:,1)', LEQ.LdB(1,:,2)'];
        
        DesiredLevel = SPL_0dBFS(SPL_0dBFS(:,1)==cf,2)+level;

        if DesiredLevel > max(SigFilts.Levs)
            DesiredLevel = max(SigFilts.Levs);
        end
        loudLev = iso226(cf,DesiredLevel,'SPL');
        lfilt = SigFilts.Lfilt{SigFilts.Levs == round(loudLev)};   
        
        stm = filtfilt(lfilt.Numerator,1,stm);
    end
end

%% Create a window function
window = hannfl(round(T*fs),round(0.05*fs),round(0.05*fs));
% Apply window to three signals
stm = stm'.*window;
tone = tone'.*window;
%% Resample the singnal

Fs = fs*DnSampRate; % from the audio device
stm = resample(stm,Fs,fs);
tone = resample(tone,Fs,fs);

%% Low pass filter
stm = filtfilt(SigFilts.Hlp.Numerator,1,stm);
tone = filtfilt(SigFilts.Hlp.Numerator,1,tone);


%% Level scaling
% level of each stimuli is scaled to have a SPL equal to "level" + a
% variable range to avoid level cues in the comparison. 
% NormType: signal is normalized to an 'RMS' of 1 or 'Peak' value of 1,
% before setting the desired attenuation. 

rndRange = 1; % differences of op to 2 dB

%Scaling the signal 
stm = scaleLvLre0dBFS(stm, level, rndRange, NormType);
tone1 = scaleLvLre0dBFS(tone, level, rndRange, NormType);
tone2 = scaleLvLre0dBFS(tone, level, rndRange, NormType);







