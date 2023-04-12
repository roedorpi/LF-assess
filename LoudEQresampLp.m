%function varargout = LoudEQresampLp(varargin)
%%
% 
%close all
%clear
clc
SigFilts = load('LoudEQFilters.mat','Levs','Lfilt','Hlp');
nOct = 0.5;
cf = 100;
CO = 0;
TM = 10;
MA = 0;
T = 1;
fs = 48000;
Lev = 100; % level of centerfrequency
cfLoudLev = iso226(cf,Lev,'SPL'); % 94 dB == 1 rms 
[smod, n1, n2, n3,t] = generate_STM_new(nOct,cf,CO,TM,MA,T,fs/10,Lev,SigFilts);
[tone_mod, tone1, tone2,t] = generate_STM_2(nOct,cf,CO,TM,MA,T,fs/10,Lev,SigFilts);
%smod = mean(reshape(smod,fs,T),2);
%n1 = mean(reshape(n1,fs,T),2);
N = length(smod);
t = 0:1/fs:T-1/fs;

Smod = fft(smod,N);
N1 = fft(n1,N);

Tone_mod = fft(tone_mod,N);
Tone1 = fft(tone1,N);

F = 0:fs/N:fs/2-fs/N;
SMOD = 20*log10(sqrt(2*abs(Smod(1:N/2,:)/N).^2)/20e-6);
NO1 = 20*log10(sqrt(2*abs(N1(1:N/2,:)/N).^2)/20e-6);

TMOD = 20*log10(sqrt(2*abs(Tone_mod(1:N/2,:)/N).^2)/20e-6);
TO1 = 20*log10(sqrt(2*abs(Tone1(1:N/2,:)/N).^2)/20e-6);


%kw = weightingFilter('K-weighting',fs);
%smod_ = kw(smod);
% x = varargin{1};
% fs1 = varargin{2};
% fs2 = varargin{3};



%%
% smod_ = filtfilt(HlF.coeffs.Numerator,1,smod);
% n1_ = filtfilt(HlF.coeffs.Numerator,1,n1);
% 
% 
% normalize amplitude after filtering, normalize rms value of signals to 1.
% smod_ = smod_/rms(smod_);
% n1_ = n1_/rms(n1_); 
% 
% scale the signal to the desired level, by scaling the signal from an
% amplitude of 1 rms (94 dB) to the desired amplitude in dB.
% smod = scaleLvL(smod, Lev, 0);
% n1 = scaleLvL(n1, Lev, 0);
% 
% smod_ = scaleLvL(smod_, Lev, 0);
% n1_ = scaleLvL(n1_, Lev, 0);


%% loudness compensated
% Smod_ = fft(smod_,N);
% N1_ = fft(n1_,N);
% 
% SMOD_ = 20*log10(sqrt(2*abs(Smod_(1:N/2,:)/N).^2)/20e-6);
% NO1_ = 20*log10(sqrt(2*abs(N1_(1:N/2,:)/N).^2)/20e-6);

%% not loudnes compensated



%%
plot(F,TMOD,F,TO1)
%hold on
%plot(F,SMOD,F,NO1) 
grid on

set(gca,'XScale','log')

% lpfilt = fdesign.lowpass(300,800,1,100,48000);
% Hlp = design(lpfilt,'systemObject',true);
% %%
% smod_resamp = resample(smod,48000,fs);
% smod_resamp = filter(Hlp,smod_resamp);
% %%
% soundsc(smod_,fs);
% pause(length(smod_)/fs+0.2);
% 
% soundsc(n1_,fs);
% %%
% 
% soundsc(smod_resamp,48000)


