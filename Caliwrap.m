%%

Fc = [50 63 80 100 125 150 200 250 316 400 500 630 800 1000];
Level = 0:-5:-50; %For levels below -200 no output is reproduced. 
FileName = sprintf('IP30_ID206465_%s.mat',datetime("now","Format","ddMMuuuu_HH_mm"));
FLow = 50;
FHigh = 8e3;
CalibrateCoupler = false;
CalibrationFile = sprintf('KemarMicCalib_%idB_input_gain.mat',20);

Calibration(Fc,Level,FileName,FLow,FHigh,CalibrateCoupler,CalibrationFile, [], 1);
pause
%%
Level = -45:-5:-90;
CalibrationFile = sprintf('KemarMicCalib_%idB_input_gain.mat',30);
FileName = sprintf('IP30_ID206465_%s.mat',datetime("now","Format","ddMMuuuu_HH_mm"));
Calibration(Fc,Level,FileName,FLow,FHigh,CalibrateCoupler,CalibrationFile, [], 1);
pause
%%
Level = -65:-5:-110;
CalibrationFile = sprintf('KemarMicCalib_%idB_input_gain.mat',40);
FileName = sprintf('IP30_ID206465_%s.mat',datetime("now","Format","ddMMuuuu_HH_mm"));
Calibration(Fc,Level,FileName,FLow,FHigh,CalibrateCoupler,CalibrationFile, [], 1);
pause
%%
CalibrationFile = sprintf('KemarMicCalib_%idB_input_gain.mat',20);
FileName = sprintf('IP30_ID206465_%s.mat',datetime("now","Format","ddMMuuuu_HH_mm"));
Fc = [80 100 125 150];
Level = 0:-5:-40; 
Calibration(Fc,Level,FileName,FLow,FHigh,CalibrateCoupler,CalibrationFile, [2 2], 2);

FileName = sprintf('IP30_ID206465_%s.mat',datetime("now","Format","ddMMuuuu_HH_mm"));
Fc = [80 100 125 150];
Level = 0:-5:-40; 
Calibration(Fc,Level,FileName,FLow,FHigh,CalibrateCoupler,CalibrationFile, [24 24], 2);
