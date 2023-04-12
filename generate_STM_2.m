function [stm,tone1, tone2,t] = generate_STM_2(nOctaves,cf,fm_CO,fm_Hz,m_dB,T,fs,level,SigFilts,LEQ)
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
 % LEQ = boolean used for activate or deactivate loudness compensation
% Outputs:
 % stm = Spectrotemporal modulated tone stimulus signal of length T
 % tone1 = tone at fundamental frequency stimulus signal of length T
 % tone2 = same as tone1
 % t = time vector
 % Output stimuli are filtered with the a loudness compensation filter to
 % present all side bands at an equal relative loudness. Additonaly the
 % levels of the three output signals are randomized within 1.5 dB to
 % avoid loudness cues in a 3AFC paradigm for modulation detection. 

% Calculate the frequency limits of the mod. band according to nOctaves
f_min_mod=floor(2^(-nOctaves*0.5)*cf); % Lowest freq in the mod. band (carrier)
f_max_mod=floor(2^(nOctaves*0.5)*cf);  % Highest freq in the mod. band (carrier) 
% frequency modulation width:
ModWidth = (f_max_mod - f_min_mod)/2; % Modulation width for frequency modulation 
t = 0:1/fs:T-1/fs;          % time vector in [s]
m = 10^(m_dB/20);           % convert modulation depth [dB] to linear

%% Generate stimuli in time
tone = sin(2*pi*cf*t);
if fm_CO ~= 0 % both frequency and time modulation 
    stm = sin(2*pi*cf.*t + m*ModWidth/fm_CO*cos(2*pi*fm_CO.*t)).*(1 + m*sin(2*pi*fm_Hz.*t));
else  % only time modulation
    stm = sin(2*pi*cf.*t).*(1 + m*sin(2*pi*fm_Hz.*t));
end

%% Create a window function
window = hannfl(round(T*fs),round(0.05*fs),round(0.05*fs));
% Apply window to three signals
stm = stm'.*window;
tone = tone'.*window;
%% loudness Adjustments
% these values have to be obtained for each of the test frequencies. 
if strcmp(LEQ,'On')
%spl2fs = app.EarphoneSens(1,:,1); %SPL for 0dBAtt.     
%freqs = str2double(app.CenterFrequencyKnob.Items); 
    if cf <= 200
        SPL_0dBFS = [63 118.6
            80 119.8
            100 121.2
            125 122.7
            160 123.5
            200 123.1];
        
        DesiredLevel = SPL_0dBFS(SPL_0dBFS(:,1)==cf,2)+level;
        if DesiredLevel > max(SigFilts.Levs)
            DesiredLevel = max(SigFilts.Levs);
        end
        loudLev = iso226(cf,DesiredLevel,'SPL');
        lfilt = SigFilts.Lfilt{SigFilts.Levs == round(loudLev)};   
        
        stm = filtfilt(lfilt.Numerator,1,stm);
        tone = filtfilt(lfilt.Numerator,1,tone);
    end
end
%% Resample the singnal

Fs = 48000; % from the audio device
stm = resample(stm,Fs,fs);
tone = resample(tone,Fs,fs);

%% Low pass filter
stm = filtfilt(SigFilts.Hlp.Numerator,1,stm);
tone = filtfilt(SigFilts.Hlp.Numerator,1,tone);

% % Create a window function
% window = hannfl(round(T*Fs),round(0.05*Fs),round(0.05*Fs));
% Apply window to three signals
% stm = stm.*window;
% tone = tone.*window;


%% Level scaling
% level of each stimuli is scaled to have a SPL equal to "level" + a
% variable range to avoid level cues in the comparison. 

rndRange = 1.5;

%Scaling the signal 
stm = scaleLvLre0dBFS(stm, level, rndRange);
tone1 = scaleLvLre0dBFS(tone, level, rndRange);
tone2 = scaleLvLre0dBFS(tone, level, rndRange);







