function PlotThreshold(varargin)
app = varargin{1};
%reference values for SPL. 
load('IP30_ID205470_0_40dBAtt_14_10_2022.mat','LdB')
ldB = [LdB(1,2:4,1)' LdB(1,2:4,2)'];

File = varargin{2}{:};
fio = matfile([app.DataPath,'/',File],"Writable",false);
N = fieldnames(fio);
Thresh = N(contains(N,'Thres_'));
Stmt = N(contains(N,'STMT_'));


a(1) = app.UIAxesHTL_2;
delete(a(1).Children)
a(2) = app.UIAxesHTR_2;
delete(a(2).Children)
a(3) = app.UIAxesSTL_2;
delete(a(3).Children)
a(4) = app.UIAxesSTR_2;
delete(a(4).Children)
for k = 1:4
    a(k).NextPlot = 'add';
end

Coll = [0.8 0.2 0.2
        0.2 0.8 0.2
        0.2 0.2 0.8];

for i = 1:length(Thresh)
    t = fio.(Thresh{i});
    tr = t.Raw;
    Indx = 1:size(tr,1);
    if strcmp(t.Ear,'Left')
        Ear = 1;
        Title = 'Hearign thresholds Ascending method (IP30)  -- Left ear';
    else
        Ear = 2;
        Title = 'Hearign thresholds Ascending method (IP30) -- Right ear';
    end
    for j = 1:size(tr,3)
        
            tr_s(:,1:3,j) = [tr(:,1,j)+ldB(j,Ear) tr(:,2:3,j)];
           
           % lv = find(tr_s(:,3,j)== 0,1)-1;
           if sum(tr_s(:,2)) ~= 0
               pfc(j,Ear) = plot(a(Ear),Indx(tr_s(:,2,j)==1),...
                   tr_s(tr_s(:,2,j)==1,1,j),'+','Color',Coll(j,:));
               plot(a(Ear),Indx(tr_s(:,2,j)==0),...
                   tr_s(tr_s(:,2,j)==0,1,j),'o','Color',Coll(j,:)) 
           else
               pfc(j,Ear) = plot(a(Ear),Indx(tr_s(:,2,j)==0),...
                   tr_s(tr_s(:,2,j)==0,1,j),'o','Color',Coll(j,:));
               
           end
           
        Legs{j} = sprintf('%i Hz',t.Estimate.Freqs(j)); 
    end
    clear tr_s
    legend(a(Ear),pfc(1:j,Ear),Legs(1:j))
    [a(Ear).Children.LineWidth] = deal(2);
    [a(Ear).Children.MarkerSize] = deal(8);
    a(Ear).Box = 'on';
    a(Ear).XGrid = 'on';
    a(Ear).YGrid = 'on';
    a(Ear).YLim = [30 110];
    a(Ear).YLabel.String = 'dB SPL';
    a(Ear).XLabel.String = 'Trials';
    a(Ear).Title.String = Title;
    clear Legs
end

Coll = colormap(a(3));
Coll = Coll(floor(linspace(1,size(Coll,1)-30,length(Stmt))),:);
for i = 1:length(Stmt)
    s = fio.(Stmt{i});
    if strcmp(s.Ear, 'Left')
        Ear = 3;
        Title = 'Spectro-Temporal mudulation sensitivity (IP30) -- Left ear';
    else
        Ear = 4;
        Title = 'Spectro-Temporal mudulation sensitivity (IP30) -- Right ear';
    end
    Indx = 1:height(s.Resp);
    pfc_(i) = plot(a(Ear),Indx(s.Resp.Correct == 1),s.Resp.Level(s.Resp.Correct == 1),'+','Color',Coll(i,:));
    plot(a(Ear),Indx(s.Resp.Correct == 0),s.Resp.Level(s.Resp.Correct == 0),'o','Color',Coll(i,:));
    aa(1,:) = string(s.StimParam);
    aa(2,:) = '-';
    aa(2,end) = ' ';
    Legs_{i} = [aa{:}];
    Ears{i} = s.Ear;
    [a(Ear).Children.LineWidth] = deal(2);
    [a(Ear).Children.MarkerSize] = deal(8);
    a(Ear).Box = 'on';
    a(Ear).XGrid = 'on';
    a(Ear).YGrid = 'on';
    a(Ear).YLim = [-40 10];
    a(Ear).YLabel.String = 'Modulation Amplitude dB';
    a(Ear).XLabel.String = 'Trials';
    a(Ear).Title.String = Title;

end
if exist("pfc_","var")
    for Ear = 3:4
        if Ear == 3
            pl = pfc_(strcmp(Ears,'Left'));
            Le = Legs_(strcmp(Ears,'Left'));
            
        else
            pl = pfc_(strcmp(Ears,'Right'));
            Le = Legs_(strcmp(Ears,'Right'));
            
        end
        legend(a(Ear),pl,Le)
    end
else
    uialert(app.UIFigure,'There is no valid STM sensitivity data','','Icon','info')
  
end
