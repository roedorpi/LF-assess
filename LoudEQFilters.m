%% loudness EQ
% % frequencies.
clear
cf = 80;
if 1
    fs = 4800;
    FileName = 'LoudEQFilters_4800.mat';
else
    fs = 48000;
    FileName = 'LoudEQFilters_48k.mat';
end
Fl = [20 25 31 40 50 63 80 100 125 160 200 250 310 400 500 630 800 1000];
Levs = 0:1:130;
LevsSPL = iso226(Fl,Levs,'LL');
 
L = iso226(Fl,cf,'LL');
%L_rel = L - min(L);
%LL = L-min(L); 
LL = 10.^((LevsSPL-min(LevsSPL))/20);
for i = 1:size(LL,2)
    loudFilt = fdesign.arbmag('N,F,A',1000,[0 5 Fl(5:end) fs/2],[0 0 LL(5:end,i)' 0],fs);
    HlF = design(loudFilt,'freqsamp','SystemObject',true);
    Lfilt{i} = HlF;
    [H(:,i),w] = freqz(Lfilt{i},fs/2,fs); 
end

lpfilt = fdesign.lowpass(300,800,1,100,48000);
Hlp = design(lpfilt,'systemObject',true);


save(FileName,"Lfilt","fs","Levs")
save("LoudEQFilters.mat","Levs","Lfilt","Hlp","lpfilt","fs");


% %%
% hold off
% semilogx(w,20*log10(abs(H(:,[61 81 101]))))
% 
% hold on
% 
% semilogx(Fl(5:end),LevsSPL(5:end,[61 81 101]))
% grid on
% %%
% fvtool(Lfilt{1:10:end})
