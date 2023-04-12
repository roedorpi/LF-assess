function output_signal = scaleLvLre0dBFS(input_signal, target_level, rndRange,NormType)

% scaleLvLHeadCalib.m - scales and filters a signal to equalize the headphone
 % Input signal which is to be scaled and equalized by the calibration filter
 % target_level - Desired output level in dB SPL (e.g. 86 dB SPL)
 % rndRange - Set a +/- x dB SPL random range for the output level (e.g. 2.5 dB SPL),
 % set equal to zero to have no range.
 % NormType - Change normalization to 'RMS' equals 1 or 'Peak' equals 1. 

%% check input_signal
% signal needs to be stored in a single column
if ~iscolumn(input_signal)
    if size(input_signal,1)==1
        input_signal = input_signal';
        warning('The input signal needs to be a single column vector - Input has been transposed')
    else
        error('The input signal needs to be a single column vector')
    end
end
%% Normalization type
switch NormType
    %  normalize rms value of signal to 1 
    case 'RMS'
        input_signal = input_signal/rms(input_signal);
    % normalize to peak value of signal to 1
    case 'Peak'
        input_signal = input_signal/max(abs(input_signal));
end
%% set the signal level to the target value
% Calculate the random range for the target level
rnd_level = -rndRange + (rndRange+rndRange).*rand();
target_level = target_level + rnd_level;
% Apply "voltage" gain to the signal.  
output_signal = input_signal * 10^((target_level)/20);
