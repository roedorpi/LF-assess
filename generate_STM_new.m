function [stm,noise1, noise2,carrier,t] = generate_STM_new(nOctaves,cf,fm_CO,fm_Hz,m_dB,T,fs,level,SigFilts,LEQ,LoudEQ,NormType)
% Purpose of this function is to generate a STM, noise and carrier stimulus
% signal according to the inputs.
% Inputs:
 % nOctaves = number of octaves for the noise carrier
 % cf = center frequency for noise carrier
 % fm_CO = spectral modulation density [cycles/octave]
 % fm_HZ = Temporal modulation [Hz]
 % m_dB = Modulation depth [dB] (0 dB = full modulation)
 % T = Time duration of STM sequence [s]
 % fs = sampling frequency
 % level = presentation level in dB SPL
% Outputs:
 % stm = Spectrotemporal modulated noise stimulus signal of length T
 % noise = Noise stimulus signal of length T
 % carrier = Carrier signal
 % t = time vector
 
% Definitions
f_min = 32; % Lowest freq in the noise stimulus
f_max = 500; % Highest freq in the noise stimulus
N_freqs = 1000; % Number of tones in the noise stimulus
DnSampRate = 10;
fs = fs/DnSampRate;
phi_start = rand(1,1)*2*pi-pi;    

% Calculate the frequency limits of the mod. band according to nOctaves
f_min_mod=floor(2^(-nOctaves*0.5)*cf); % Lowest freq in the mod. band (carrier)
f_max_mod=floor(2^(nOctaves*0.5)*cf);  % Highest freq in the mod. band (carrier) 

% Create freq vector with logarithmically placed freqs between min and max freq
freqs = logspace(log10(f_min),log10(f_max),N_freqs)'; 
% Extract the carrier from the noise freq vector
freqs_carrier = freqs(freqs>=floor(f_min_mod) & freqs <= floor(f_max_mod));
% The freq vector for the noise must not contain freqs which are in the carrier
% freqs_noise = setxor(freqs,freqs_carrier);

A = ones(size(freqs_carrier)); % Creates a vector of ones that will contain STM content

%A_offNoise = 0;%10^(-200/20)*ones(size(freqs_noise)); % Creates a vector which will contain the noise which is outside of the STM carrier band

A = A(:);
N = round(T*fs);            % number of temporal samples
t = 0:1/fs:T-1/fs;          % time vector in [s]
m = 10^(m_dB/20);           % convert modulation depth [dB] to linear
x = log2(freqs_carrier/freqs_carrier(1));   % definition of frequency axis in octaves
% N_freqs = length(freqs);    % number of audio frequency components considered
N_freqs_carrier = length(freqs_carrier);    % number of audio frequency components for the carrier
%N_freqs_noise = length(freqs_noise);    % number of audio frequency components for the noise
%% Generate stimuli in spectral domain

% High-resolution frequency vector
bins_perHz = 32;            % defines frequency resoution as well as duration of resulting time signal (before cropping)
% df = 1/bins_perHz;
% f = 0:df:fs-df;             

% allocate variable for carrier spectrum
S_carrier = zeros(fs/2*bins_perHz+1,1);

% Calculate indices for considered frequencies
 % Structure of indices:
 % idx_offNoise is placed around the idx_carrierbands, idx_lower_SB and
 % idx_upper_SB. Depending on how the center frequency of the carrier is
 % set the vector entry where the offNoise jumps in frequency index will vary.
 % For each entry of the three vectors: lower_SB < carrierbands < upper_SB
 % i.e. the sidebands are placed around the carrierband.
idx_carrierbands = round(freqs_carrier*bins_perHz); 
%idx_offNoise = round(freqs_noise*bins_perHz); 
idx_lower_SB = idx_carrierbands - round(fm_Hz*bins_perHz); % index of lower sideband
idx_upper_SB = idx_carrierbands + round(fm_Hz*bins_perHz); % index of upper sideband

% Define Phase for considered frequencies
phi_mod = (2*pi*fm_CO*x)+phi_start-pi/2;        % -pi/2 to convert sine to cosine
phi_carrier = rand(N_freqs_carrier,1)*2*pi-pi;  % random phase for carrier bands
%phi_offNoise = rand(N_freqs_noise,1)*2*pi-pi;   % random phase for off frequency noise
phi_lower_SB = phi_carrier - phi_mod;           % Phase for lower sideband
phi_upper_SB = phi_carrier + phi_mod;           % Phase for upper sideband

% fill in components
S_carrier(idx_carrierbands) = A.*exp(1i*(phi_carrier));
%S_carrier(idx_offNoise) = A_offNoise.*exp(1i*(phi_offNoise));


S_stm = S_carrier;
S_stm(idx_lower_SB) = S_stm(idx_lower_SB) + A.*m/2.*exp(1i*(phi_lower_SB));
S_stm(idx_upper_SB) = S_stm(idx_upper_SB) + A.*m/2.*exp(1i*(phi_upper_SB));
S_noise = S_carrier;
S_noise(idx_lower_SB) = S_noise(idx_lower_SB) + A.*m/2.*exp(1i*(rand(N_freqs_carrier,1)*2*pi-pi));
S_noise(idx_upper_SB) = S_noise(idx_upper_SB) + A.*m/2.*exp(1i*(rand(N_freqs_carrier,1)*2*pi-pi));


% Define full symmetric spectra
S_stm = [S_stm; conj(S_stm(end-1:-1:2))];
S_noise = [S_noise; conj(S_noise(end-1:-1:2))];
S_carrier = [S_carrier; conj(S_carrier(end-1:-1:2))];

%% Generate and process corresponding time signals

% calculate time signals
stm = ifft(S_stm);
noise = ifft(S_noise);
carrier = ifft(S_carrier);

% crop time signals to specified duration
stm = stm(1:N);
noise = noise(1:N);
carrier = carrier(1:N);


%% loudness Adjustments
% these values have to be obtained for each of the test frequencies. 
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
        noise = filtfilt(lfilt.Numerator,1,noise);
    end

end


%% Resample the signal to match sound card sampling rate
Fs = fs*DnSampRate; % from the audio device
stm = resample(stm,Fs,fs);
noise = resample(noise,Fs,fs);
carrier = resample(carrier,Fs,fs);

%% Low pass filter
stm = filtfilt(SigFilts.Hlp.Numerator,1,stm);
noise = filtfilt(SigFilts.Hlp.Numerator,1,noise);
carrier = filtfilt(SigFilts.Hlp.Numerator,1,carrier);

%% Create a window function
window = hannfl(round(T*Fs),round(0.05*Fs),round(0.05*Fs));
% Apply window to three signals
stm = stm.*window;
noise = noise.*window;
carrier = carrier.*window;

%% Level scaling
% level of each stimuli is scaled to have a SPL equal to "level" + a
% variable range to avoid level cues in the comparison. 

rndRange = 0; %1.5;
stm = scaleLvLre0dBFS(stm, level, rndRange, NormType);
noise1 = scaleLvLre0dBFS(noise, level, rndRange, NormType);
noise2 = scaleLvLre0dBFS(noise, level, rndRange, NormType);
carrier = scaleLvLre0dBFS(carrier, level, rndRange, NormType);






