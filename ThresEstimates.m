%%
function varargout = ThresEstimates(varargin)
inarg = fieldnames(varargin{1});
if sum(contains(inarg,'Name'))
    A = load([varargin{1}.Path,varargin{1}.Name]);
else     
    A = varargin{1};
end
N = fieldnames(A);
Thres = N(contains(N,'Thres_'));
STM = N(contains(N,'STMT_'));

%%
if ~isempty(STM)
    Ear_ = [];
    for i = 1 : length(STM)
        stm = A.(STM{i}).Resp;
        StimParam = A.(STM{i}).StimParam;    
        [stmT_(i,5),stmT_(i,6)] = maxlike(median(stm.Level),1,stm.Level,stm.Correct);
        param = regexp(STM{i},'_','split');
        if length(StimParam) == 4
            stmT_(i,1:4) = [StimParam([1 3:4]) 40];
        else
            stmT_(i,1:4) = StimParam([1 3:5]);
        end
        if length(param) < 7
            tt(i) = datetime([param{5},'-',param{4},'-',param{6},...
                ' ',param{2},':',param{3},':',num2str(i)],'InputFormat','dd-MMM-yyyy HH:mm:ss');
        else
            tt(i) = datetime([param{2},'-',param{3},'-',param{4},...
                ' ',param{5},':',param{6},':',param{7}],'InputFormat','dd-MMM-yyyy HH:mm:ss');
            
        end
        if isfield(A.(STM{i}),'Ear')
            Ear = cellstr(A.(STM{i}).Ear);
        else
            Ear = 'Left';
        end
        Ear_ = [Ear_; Ear];
    end
    stmTab = array2table(stmT_,'RowNames',cellstr(tt));
    stmTab.Ear = Ear_;
    stmTab.Properties.VariableNames = {'Frequency','Cycles/Oct','Cycles/Sec',...
        'Sens Level','Threshold','STD','Ear'};
    varargout{1}.stmT = stmTab;

else
    varargout{1}.stmT = timetable;
end
clear tt

if ~isempty(Thres)
    ths_ = [];
    tt_ = [];
    Ear_ = [];
    for j = 1 : length(Thres)
        for k = 1: length(A.(Thres{j}).Estimate.Thres)
            if ~isnan(A.(Thres{j}).Estimate.Thres(k))
                ths(k,1) = A.(Thres{j}).Estimate.Freqs(k);
                if isfield(A.(Thres{j}).Estimate,'Thres_dBSPL')
                    ths(k,2) = roundn(A.(Thres{j}).Estimate.Thres_dBSPL(k),-1);
                else
                    ths(k,2) = roundn(A.(Thres{j}).Estimate.Thres(k),-1);
                end
                param = regexp(Thres{j},'_','split');
                 % response files that have one time stamp for each threshold
                if isfield(A.(Thres{j}).Estimate,'Time4Estimate')
                    tt(k) = datetime(datestr(A.(Thres{j}).Estimate.Time4Estimate(k)));
                else
                    if length(param) < 7
                        tt(k) = datetime([param{5},'-',param{4},'-',param{6},...
                        ' ',param{2},':',param{3},':',num2str(k)],'InputFormat','dd-MMM-yyyy HH:mm:ss');
                    else
                        tt(k) = datetime([param{2},'-',param{3},'-',param{4},' ',param{5},...
                            ':',param{6},':', num2str(k)],'InputFormat','dd-MMM-yyyy HH:mm:ss');
                    end
                end
            end    
        end
        if exist("ths","var")
            ths_ = [ths_; ths];
            tt_ = [tt_;tt(:)];
            Ear = cellstr(repmat(A.(Thres{j}).Ear,size(ths,1),1));
            Ear_ = [Ear_; Ear];
            clear ths tt Ear
        end
    end
    if ~isempty(ths_)
        thsTab = array2table(ths_(1:size(tt_),:),'RowNames',cellstr(tt_));
        thsTab.Ear = Ear_;
        thsTab.Properties.VariableNames = {'Frequency','Threshold_dBSPL','Ear'};
        varargout{1}.ths = thsTab;
    else
        varargout{1}.ths = timetable;
    end
else
    varargout{1}.ths = timetable;    
end



