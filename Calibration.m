%%
function varargout = Calibration(varargin)
%% Input parameters
if numel(varargin) > 0
    Fc = varargin{1}; %Center frequencies for the calibration
    Level = varargin{2}; % Levels to measure
    FileName = varargin{3}; % file name to save results
    FLow = varargin{4}; % lowest frequency of interest for the analysis
    FHigh = varargin{5}; % highest frequency of interest
    CalibrateCoupler = varargin{6}; % boolean to calibrate or measure
    MeasAmpGain = varargin{7}; % gain on mic preamplifier
    CalibrationFile = varargin{8}; % Stored calibrations use for display.
else
    %Fc = [50 63 80 100 125 150 200 250 316 400 500 630 800 1000 1250 1500 2000 2500 3150 4000 5000 6300 8000];
    Fc = [50 63 80 100 125 150 200 250 316 400 500 630 800 1000];
    Level = -50:-5:-100; %For levels below -200 no output is reproduced. 
    FileName = sprintf('IP30_ID206465_%s.mat',datetime("now","Format","ddMMuuuu_HH_mm"));
    FLow = 50;
    FHigh = 8e3;
    MeasAmpGain = [50 50];
    CalibrateCoupler = false;
    CalibrationFile = sprintf('KemarMicCalib_%idB_input_gain.mat',0);
end
StimType = 3;  %% 3 input only, 2 STM stimuli, 1 tone stim at given level
%%
fs = 48000;
Bufsize = 1024;
AuDev = "ASIO Fireface USB";
auio =  audioPlayerRecorder; 
auio.Device = AuDev;
auio.SampleRate = fs;
auio.SupportVariableSize = true;
auio.BufferSize = Bufsize;
auio.PlayerChannelMapping = [7 8];
auio.RecorderChannelMapping = [1 2];


Osc = audioOscillator;
Osc.SampleRate = fs;
Osc.SamplesPerFrame = Bufsize;
Osc.Amplitude = 0;
%% Coupler calibratoin
% Record 5 seconds from each input channel pausing between channels to change the
% calibrator. This part will save the calibratin file with variables CalRMS, CalTone,
% Calsettings. Once this is run change CalibrateCoupler to false. 
% Loop runs for each channel to calibrate in this case two. Record the 
% calibration tone for each input channel with fixed settings of the soud
% card (MeasAmpGain). At the end of each iteration change the
% calibrator to the next channel. 
if CalibrateCoupler
    for i = 1: length(auio.RecorderChannelMapping)
        tic 
        Out = [];
        while toc < 5  
            %outsig = Osc();
            out = auio(zeros(auio.BufferSize,2));
            Out = [Out; out];
        end
        plot(1/fs:1/fs:length(Out)/fs, Out(:,i))
        CalTone{i} = Out(:,i);
        CalRMS(i) = rms(Out(:,i));
        pause % wait for keystroke, change calibrator
    end
    CalSettings = "RME Fireface UCX; input channels 1 & 2;" + ...
        "Mic polarization 48 volts; Input gain 0 dB;" + ....
        "SC phone output gain -10 dB"; 
    save(CalibrationFile,"CalRMS", "CalTone", "CalSettings");
    
    return
else
    load(CalibrationFile,"CalRMS");
end



%% 1/3-octave filter bank
oneThirdOctFiltBank = octaveFilterBank("1/3 octave",fs, ...
                              FrequencyRange=[FLow FHigh]);
[FF, F0] = getBandedgeFrequencies(oneThirdOctFiltBank);
P0 = 20e-6; % reference pressure
LRdB = zeros(length(FF),2); 


%% plot

b = figure(1);
delete(b.Children);
a = axes(Parent=b,Position=[0.13 0.36 0.77 0.6]);
grid on

yyaxis left;
PL(1)=stairs(FF,LRdB(:,1));
yyaxis right;
PL(2)=stairs(FF,LRdB(:,2));

a.XScale = 'log';
a.XLim = [FF(1) FF(end)];
a.YAxis(1).Limits = [-5 120];
a.YAxis(1).Label.String = 'dB SPL';
a.YAxis(2).Limits = [-5 120];
a.YAxis(2).Label.String = 'dB SPL';
a.XTick = round(F0);
a.XTickLabel = roundn(F0/1000,-3);
a.XTickLabelRotation = 45;
a.XMinorTick = 'off';
a.XMinorGrid = 'off';
a.XLabel.String = 'Frequency [kHz]';
Frange = log2(a.XLim(end))-log2(a.XLim(1)); % how many decades (or octaves)
dBrange = diff(a.YLim)/20; % denominator dB per decade desired.
a.PlotBoxAspectRatio = [Frange/dBrange 1 1]; 
        
[PL.LineWidth] = deal(2);
% b.WindowButtonDownFcn = @StartStopExec;
% b.WindowStyle = 'docked';

c = axes(Parent=b,Position=[0.13 0.08 0.77 0.2]);
grid on
TP = line(0:1/fs:3-1/fs,zeros(3*fs,2),'Parent',c);
c.XLabel.String = 'Time [s]';
c.YLabel.String = 'Sound Pressure [Pa]';
c.Box = 'on';

%% Probe tone
fileObj = matfile(FileName,"Writable",true);
StimLength = 141*auio.BufferSize/fs; %~3seconds
Numbuffs = ceil(StimLength*fs/auio.BufferSize);
if StimType == 2
    SigFilts = load('LoudEQFilters.mat',"Levs","Lfilt","Hlp");
    EarphoneSens = load('IP30_ID205470_0_40dBAtt_14_10_2022.mat','Frequencies','LdB');
    fs_ = fs/10;
end



% while j  
    for l = 1:length(Fc)
        Osc.Frequency = Fc(l);
        for k = 1:length(Level)
            X = zeros(auio.BufferSize,length(auio.RecorderChannelMapping),Numbuffs+8);
            m = 1;
            if StimType == 3
                for i = 1:Numbuffs+8 
                    X(:,:,i) = auio(zeros(auio.BufferSize,2));
                end
            elseif StimType == 1 
                Osc.Amplitude = 10^(Level(k)/20);
                for i = 1:Numbuffs+8
                    if i<3 || i > Numbuffs + 2
                        Signal = zeros(auio.BufferSize,1);
                    else
                        Signal = Osc();
                    end
                    X(:,:,i) = auio(repmat(Signal,1,2));
                end
            elseif StimType == 2 
                
                [smod, ~, ~, ~] = generate_STM_3(Fc(l),2,2,Level(k),141*auio.BufferSize/fs,fs,-10,SigFilts,EarphoneSens,'on','Peak');
                
                 Diff_in_samples = 141*auio.BufferSize - length(smod);
                 if Diff_in_samples >= 0
                     smod = [smod; zeros(Diff_in_samples,1)];
                 else
                     smod = smod(1:141*auio.BufferSize);
                 end
                 smod = reshape(smod,auio.BufferSize,[]);
                 smod = [zeros(auio.BufferSize,4) smod zeros(auio.BufferSize,4)];
                 Numbuffs = size(smod,2);
                 for i = 1:Numbuffs
                    X(:,:,i) = auio(repmat(smod(:,i),1,2));
                 end
            end

            X = permute(X,[1,3,2]);
            X = reshape(X,[],2);
            X = [X(:,1), -X(:,2)];
            X = X./10.^(MeasAmpGain/20)./CalRMS; % level adjust
            stimname = sprintf("Freq_%i_att_%i_signal",Fc(l),abs(Level(k)));
            fileObj.(stimname) = X;
            LR = oneThirdOctFiltBank(X);
            LRdB = squeeze(20*log10(rms(LR(fs:end-fs,:,:))/P0));
            x = X(fs:end-fs,:);
            x = x.*hamming(length(x),"periodic");                         
            XdB = 20*log10(abs(2*fft(x)/length(x))/P0);
            stimname = sprintf("Freq_%i_att_%i_thirdlev",Fc(l),abs(Level(k)));
            fileObj.(stimname) = LRdB;
            PL(1).XData = 0:fs/length(x):fs - fs/length(x);
            PL(1).YData  = XdB(:,1);
            PL(2).XData = 0:fs/length(x):fs - fs/length(x);
            PL(2).YData  = XdB(:,2);
            %PL(1).YData  = [LRdB(:,1); LRdB(end,1)]; 
            %PL(2).YData  = [LRdB(:,2); LRdB(end,2)]; 
            TP(1).XData = 0:1/fs:length(x)/fs-1/fs;
            TP(1).YData = x(:,1);
            TP(2).XData = 0:1/fs:length(x)/fs-1/fs;
            TP(2).YData = x(:,2);
            fprintf(1,'Chan1: Level: %2.1f dB RMS: %f, Freq: %i\n',...
                max(LRdB(:,1)),P0*10^(max(LRdB(:,1))/20),F0(LRdB(:,1) == max(LRdB(:,1))))    
            fprintf(1,'Chan2: Level: %2.1f dB, RMS: %f, Freq: %i\n\n',...
                max(LRdB(:,2)),P0*10^(max(LRdB(:,2))/20),F0(LRdB(:,2) == max(LRdB(:,2))))    

            drawnow
        end

    end
%end
auio.release
% end

% function StartStopExec(~,~)
% global j
%     if j == 1
%         j = 0;
% 
%     elseif j == 0
%         j = 1;
%         Calibration;
%     end
% 
% end


%Fc = [125 250 500 750 1000 1500 2000 3000 4000 6000 8000];