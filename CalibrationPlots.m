clear 
clc

%%
load("KemarMicCalib_20dB_input_gain.mat","CalRMS");
ADC.IG20dB = CalRMS;
clear CalRMS;
load("KemarMicCalib_40dB_input_gain.mat","CalRMS");
ADC.IG40dB = CalRMS;
clear CalRMS;
calfiles = dir('IP30_ID206465_*.mat');

%% center frequencies of filters used in the calibration analysis
fs = 48000;
FLow = 50;
FHigh = 8000;

oneThirdOctFiltBank = octaveFilterBank("1/3 octave",fs, ...
                              FrequencyRange=[FLow FHigh]);
[FF, F0] = getBandedgeFrequencies(oneThirdOctFiltBank);


%% pure tone frequencies of the calibration stimuli. 
% Took out 750 Hz to match the 1/3 octave bands
Fc = [50 63 80 100 125 150 200 250 316 400 500 630 800 1000 1250 1500 2000 2500 3150 4000 5000 6300 8000];
%% attenuation levels
Att = [0:-5:-95 -400];
%%

f5 = figure(5);
delete(f5.Children);
ax1 = axes(Parent=f5,Position=[0.13 0.56 0.77 0.4],Box='on');
ax2 = axes(Parent=f5,Position=[0.13 0.11 0.77 0.4],Box='on',NextPlot='add');

ax2.XScale = 'log';
ax2.XLim = [50 1000];
ax2.XTick = Fc;
ax2.XMinorTick = 'off';
ax2.XMinorGrid = 'off';
ax2.XGrid = 'on';
ax2.YGrid = "on"; 
ax2.YLim = [0 120];
ax2.XLabel.String = 'Frequency [Hz]';
ax2.YLabel.String = 'Sound pressure level [dBSPL]';

Frange = log2(ax2.XLim(end))-log2(ax2.XLim(1)); % how many decades (or octaves)
dBrange = diff(ax2.YLim)/20; % denominator dB per decade desired.
ax2.PlotBoxAspectRatio = [Frange/dBrange 1 1]; 

%%
fs = 48000;
for i = [1 3]
    obj = matfile(calfiles(i).name);
    vars = who(obj);
    % select tones and attenuations
    vars = vars(contains(vars,{'Freq_50_', 'Freq_63_','Freq_80_', 'Freq_100_', 'Freq_125_', 'Freq_150_', 'Freq_200_'})); % dont include 750 HZ
    for j = 1:length(vars)
        param = regexp(vars{j},'_','split');
        % index of the played frequencies and attenuations
        f_indx = find(Fc == str2double(param{2}));
        a_indx = find(Att == -str2double(param{4}));
       
        disp({F0(f_indx), Fc(f_indx), Att(a_indx)})

        if strcmp(param{5},'signal')
            if (i < 3 && str2double(param{4}) < 60) || (i > 1 && str2double(param{4}) > 50)
                if i == 1
                    CalRMS = ADC.IG20dB;
                else
                    CalRMS = ADC.IG40dB;
                end
                 sig = obj.(vars{j})(fs:2*fs-1,:)./CalRMS;
                 sig_ = oneThirdOctFiltBank(sig);
                 sig_allbands = squeeze(20*log10(rms(sig_)/20e-6));
                 Levels(a_indx,f_indx,:) = sig_allbands(f_indx,:);
                 Levels_all(a_indx,f_indx,:,:) = sig_allbands;
                 plot(ax1,0:1/fs:length(sig)/fs-1/fs,sig)
                 stairs(ax2,FF,[sig_allbands; sig_allbands(end,:)])
                 
                 ax1.Title.String = sprintf('%s',vars{j});
                 ax1.Title.Interpreter = "none";
                 drawnow
                 pause(2)

            end 
        else
           Levels_(a_indx,f_indx,:) = obj.(vars{j})(1,f_indx,:); 
        end
        if Att(a_indx) < -90, delete(ax2.Children); end
    end
    
end


%%
m = 1;
for i = 4:length(calfiles)
    obj = matfile(calfiles(i).name);
    vars = who(obj);
    for j = 1:length(vars)
        param = regexp(vars{j},'_','split');
        if ~strcmp(param{5},'signal')
            bglev(:,:,m) = squeeze(obj.(vars{j}));
            m=m+1;
        end
    end
end

bglev_m = mean(bglev,3);
bglev_std = std(bglev,[],3);
bglev_m = [bglev_m; bglev_m(end,:)];
%%
f = figure(1);
delete(f.Children);
a = axes('parent',f);
grid on
stairs(FF,bglev_m,'Parent',a,'Color',[0.5 0.5 0.5])
hold on
errorbar(a,F0,bglev_m(1:end-1,1),bglev_std(:,1),'Color',[0.5 0.5 0.5],'LineStyle','none')
errorbar(a,F0,bglev_m(1:end-1,2),bglev_std(:,2),'Color',[0.5 0.5 0.5],'LineStyle','none')

a.XScale = 'log';
a.XLim = [FF(2) 700];
a.YAxis.Limits = [0 120];
a.YAxis.Label.String = 'dB SPL';
a.XTick = round(F0);
a.XTickLabel = roundn(F0/1000,-3);
a.XTickLabelRotation = 45;
a.XMinorTick = 'off';
a.XMinorGrid = 'off';
a.XLabel.String = 'Frequency [kHz]';
a.Box = 'on';

Frange = log2(a.XLim(end))-log2(a.XLim(1)); % how many decades (or octaves)
dBrange = diff(a.YLim)/20; % denominator dB per decade desired.
a.PlotBoxAspectRatio = [Frange/dBrange 1 1]; 
FF_ = FF(3:end-1);
F0_ = F0(3:end-1);

stairs(a,FF_,[Levels_(1:2:end,:,1) Levels_(1:2:end,end,1)]','LineStyle','-','Color',[0.6 0.6 0.6])
stairs(a,FF_,[Levels_(1:2:end,:,2) Levels_(1:2:end,end,2)]','LineStyle','-','Color',[0.7 0.7 0.7])
%%
% mf = matfile('CalibLevels_IP30_processed.mat','Writable',true);
% mf.Levels = Levels;
% mf.Levels_all = Levels_all;
% mf.FF_ = FF_;
% mf.FO_ = F0_;
% mf.FF = FF;
% mf.FO = F0;
% mf.Fc = Fc;