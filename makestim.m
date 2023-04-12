function varargout = makestim(varargin)
%% Make a series of tones and complex tones 
% varargout = makemelody(varargin)
% This function using the input parameters to create series of pure tones,
% either complex tones (fundamental frequency + odd or even harmonics). The
% notes created are returned in three arrays one with each type of note. 
%
% Input arguments: 
% 1. ChosenOctaves: Cell array of two strings indicating the lowest and
% highest note to be used in the note series. The notes are given with the
% english name followed by the octave. The lowes note is 'C2' and the
% highest is 'B8' sharps are denotes as 'D#5'
%
% 2. harmamp: two element array containing max and min amplitude for the
% harmonics of the complex tones. In the present implementation the 
% decreases logarithmicaly with frequency, that is the lowest harmonic will 
% have the max amplitude and the highest harmonic will have the min. The 
% amplitudes are given as the exponential of 10, so for a maximum of 1 and 
% a minimun 80 dB lower would be [0,-4], i.e.  10^0 = 1, 10^-4 = 0.0001.
%
% 3. NumHarmonics: Number of harmonics for the complex tones interger value
% >= 1
% 
% 4. Number of notes to include in the melody, interger that has to be less
% that the number of notes included
%
% 5. beat: Length of each note in seconds, i.e. 0.125 or 0.25
%
% Output values: 
% 1. pure tone array
% 2. Complex tone array with even harmonics
% 3. Complex tone array with odd harmonics



% load note frequencies
F0 = varargin{1}; 
F1 = F0-varargin{2};
beat = varargin{3};
HarmResolve = varargin{4};
% find the index range of the notes to use;
harmonics = 2:2:40;% even harmonics

amp = 0.6*tukeywin(length(harmonics)+2,1);
amp = amp(2:end-1)';
fs = varargin{5};
% time vector used to generate the tones
t = 1/fs:1/fs:beat;  
% Equal rise and fall of the tonal stimuli, 0.15% of the length of the 
% stimuli
w = tukeywin(size(t,2),0.5)';
% harmonic complex
note0 = (amp*sin(2*pi*F0*harmonics'.*t).*w)';
note1 = (amp*sin(2*pi*F1*harmonics'.*t).*w)';

% tone
tone0 = (sin(2*pi*F0.*t).*w)';
tone1 = (sin(2*pi*F1.*t).*w)';
% filter for resolved or unresolved harmonics
switch HarmResolve
    case 'Low' 
      ctone0 = bandpass(note0,[F0 6*F0],fs);  
      ctone1 = bandpass(note1,[F1 6*F1],fs);  
    case 'High'
      ctone0 = bandpass(note0,[5*F0 15*F0],fs);
      ctone1 = bandpass(note1,[5*F1 15*F1],fs);
end
stim1 = tone1 + ctone1;
stim0 = tone0 + ctone0;
% make a 5 second pattern: 
A = repmat([stim0; zeros((2*beat)*fs,1); stim0; zeros((beat)*fs,1)],6,1);
B = repmat([zeros((2*beat)*fs,1); stim1; zeros((2*beat)*fs,1)],6,1);
Pat = [A+B];
% normalize to a max of 1
Pat = Pat./max(abs(Pat(:)));
varargout{1} = Pat;
varargout{2} = t;
varargout{3} = fs;

