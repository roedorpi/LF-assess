%%
function varargout = AbsThres(varargin)
app = varargin{1};
app.Reversals = 0;
% Default test parameters
TestFreqs = [63 80 100 125 160 200];
StartLevelDefault = [-20 -21.5 -23 -24.5 -25.3 -26];
StartLevel = StartLevelDefault(app.ThresData.tFSelect);
if strcmp(app.EarSwitch.Value,'Left')
    ChosenEar = 1;
    ChannelOut = app.ChanNumbers(1); %left headphone out 
    app.ThresData.Ear = 'Left';
else
    ChosenEar = 2;
    ChannelOut = app.ChanNumbers(2); %right headphone out
    app.ThresData.Ear = 'Right';
end
SPL20dBFS = app.EarphoneSens.LdB(1,app.ThresData.tFSelect,ChosenEar);

signalLength = 0.8 + 0.7*rand; % between 0.8 and 1.5 s.
fs = 48e3;
% input from function call
switch numel(varargin)
    case 2
        TestFreqs = varargin{2};
    case 3
        TestFreqs = varargin{2};    
        StartLevel = varargin{3};
    case 4
        TestFreqs = varargin{2};    
        StartLevel = varargin{3};
        signalLength = varargin{4};
    case 5
        TestFreqs = varargin{2};    
        StartLevel = varargin{3};
        signalLength = varargin{4};    
        fs = varargin{5};
end


Data = [];
app.RespApp.Button.Enable = 'on';
app.RespApp.AnswerPanel.Title = 'Gør dig klar!';
%% Blink Button to signal start
for m = 1:3
    app.RespApp.Button.BackgroundColor = [0.39,0.83,0.07];
    if isobject(app.ard), app.ard.writeDigitalPin(app.ardconf.LED,1); end
    if m>6
        pause(0.5)
    else
        pause(1)
    end
    app.RespApp.Button.BackgroundColor = [0.3,0.3,0.3];
    if isobject(app.ard), app.ard.writeDigitalPin(app.ardconf.LED,0); end
    if m>6
        pause(0.5)
    else
        pause(1)
    end
end

app.RespApp.Button.BackgroundColor = [0.39,0.83,0.07];
if isobject(app.ard), app.ard.writeDigitalPin(app.ardconf.LED,1); end
app.RespApp.AnswerPanel.Title = 'Tryk på knappen når du hører en lyd.';
F = TestFreqs;
Abort = 0; %if the test is terminated by the experimenter "stop button"
for i = 1:length(F)
    % reset all counters for each frequency
    Done = 0;
    Valleys = 0;
    Peaks = 0;
    j = 1;
    CurrentLevel = StartLevel(i); % dB 
    NextLevel = 0; % dB step to change for next presentation
    PrevLevel = StartLevel(i); 
    delete(app.UIAxes.Children)
    LoudLevs = iso226(F(i),[0 50 100],'LL');
    patch(app.UIAxes,...
        [app.UIAxes.XLim(1), app.UIAxes.XLim(2), app.UIAxes.XLim(2), app.UIAxes.XLim(1)],...
        [LoudLevs(1),LoudLevs(1),LoudLevs(2),LoudLevs(2)],[0.2 0.8 0.2],...
        'FaceAlpha',0.2,'LineStyle','none');
    patch(app.UIAxes,...
        [app.UIAxes.XLim(1), app.UIAxes.XLim(2), app.UIAxes.XLim(2), app.UIAxes.XLim(1)],...
        [LoudLevs(2),LoudLevs(2),LoudLevs(3),LoudLevs(3)],[0.8 0.2 0.2],...
        'FaceAlpha',0.2,'LineStyle','none');
    text(app.UIAxes,app.UIAxes.XLim(2)-5,LoudLevs(1),'MAF');
    text(app.UIAxes,app.UIAxes.XLim(2)-5,LoudLevs(2),'50 phon');
    text(app.UIAxes,app.UIAxes.XLim(2)-5,LoudLevs(3),'100 phon');
    Familiarization = 1;
    Repeat = 0;
    %[Tone,~] = generate_Tones(F(i),signalLength,fs,StartLevel(i));
    
    %Tplot = line(F(i),CurrentLevel,'linewidth',2,...
    %    'color','b','marker','o','MarkerSize',18,'parent',app.UIAxes);
    while ~Done
        %% set level
        PrevLevel = CurrentLevel;
        CurrentLevel = PrevLevel+NextLevel;
        %Tone = Tone.*(10^(NextLevel/20));
        signalLength = roundn(0.5 + rand,-1);
        clear Tone
        [Tone,~] = generate_Tones(F(i),signalLength,fs,CurrentLevel);
        TonedB = CurrentLevel + SPL20dBFS(i); %for plotting
        Tplot.YData = TonedB;
        drawnow
        %% Present stimuli
        preStim = round((0.5 + rand)*fs); % 0.5 to 1.5 s
        postStim = round((0.5 + 2.5*rand)*fs); % 0.5 to 3 s
        Tone_ = cat(1,zeros(preStim,1),Tone(:),zeros(postStim,1));
                
        CorrectDetection = 0;
        PressedBeforeStim = 0;
        %Present stimuli
        Out = playrec('play',Tone_,ChannelOut);
        
        while ~playrec('isFinished',Out)
            pause(0.01)
            ButtonDown = app.RespApp.Pushed;
            if isobject(app.ard)
                ArdButDown = ~app.ard.readDigitalPin(app.ardconf.SWState);
            else
                ArdButDown = 100;
            end
            %ButtonUp = ;
            % check for answer, no response has been given.
            if ButtonDown || ArdButDown == 1
        %        app.RespApp.Button.BackgroundColor  = 'r';
        %        drawnow
                % Valid answer only from onset of stimuli until 2 times length of stimuli 
                [~,AnswerSample] = playrec('getCurrentPosition'); 
                if ~CorrectDetection
                    if AnswerSample && AnswerSample > preStim && AnswerSample < 2*length(Tone) + preStim 
                        CorrectDetection = 1;                        
                        NextLevel = -10;
                      %  disp('Pressed--Correct')
                    elseif AnswerSample && AnswerSample < preStim
                        CorrectDetection = 0;
                        PressedBeforeStim = 1;
                        if CurrentLevel + NextLevel > StartLevel(i)
                            NextLevel = 0;
                        else
                            NextLevel = 5;
                        end
                      %  disp('Pressed--before stim')
                    else
                        CorrectDetection = 0;
                        if CurrentLevel + NextLevel > StartLevel(i)
                            NextLevel = 0;
                        else
                            NextLevel = 5;
                        end
                      %  disp('Pressed--not valid')                    
                    end
                end
            elseif ~ButtonDown || ArdButDown == 0
         %       app.RespApp.Button.BackgroundColor  = [0.39,0.83,0.07];
         %       drawnow
                if ~CorrectDetection
                    if CurrentLevel + NextLevel > StartLevel(i)
                            NextLevel = 0;
                        else
                            NextLevel = 5;
                    end
                    %disp('no response--not valid')
                else
                  %  disp('no response')
                end
            end
            
        end
        
        % Remove Correct detection that contains responses before stimulus onset
        % to avoid getting correct answer by holding the button down.
        if PressedBeforeStim && CorrectDetection
            CorrectDetection = 0;
            if CurrentLevel + NextLevel > StartLevel(i)
                NextLevel = 0;
            else
                NextLevel = 5;
            end
        end
        %app.RespApp.Button.BackgroundColor  = [0.39,0.83,0.07];
        % get response time
        if exist('AnswerSample','var')
            RespTime = (AnswerSample-preStim)/fs;
            %rt = toc(app.RespApp.PushTime);
        else
            RespTime = NaN;
        end
        % plot markers
        if CorrectDetection
            line(j,TonedB,'color','b','marker','+',...
                        'linewidth',3,'MarkerSize',8,'parent',app.UIAxes)
        else
            line(j,TonedB,'color','b','marker','o',...
                        'linewidth',2,'MarkerSize',8,'parent',app.UIAxes)
        end
        % Count peaks and valeys
        % No response at valey
        if CurrentLevel < PrevLevel && ~CorrectDetection
            Valleys = [Valleys CurrentLevel];
            line(j,TonedB,'color','b','marker','o','MarkerSize',8,...
                'markerfacecolor','b','parent',app.UIAxes)
            Familiarization = 0;
        end
        % Response at peak
        if CurrentLevel > PrevLevel && CorrectDetection && ~Familiarization
            Peaks = [Peaks CurrentLevel] ;           
            line(j,TonedB,'color','g','marker','+','MarkerSize',10,...
                'markerfacecolor','g','parent',app.UIAxes)
        end
        % save data into varialble
        Data(j,:,i) = [CurrentLevel, CorrectDetection, RespTime, Familiarization, Valleys(end), Peaks(end)];
        app.CurrentStimuliLabel.Text = sprintf(...
            'Now Presenting: Freq: %i Hz; Level: %.1f dB SPL; Trial Nr: %i; Correct %i',...
            F(i),Tplot.YData,j,CorrectDetection);
        % check for stop criteria: 3 out of at least 5 consecutive peaks at
        % the same level
        if length(Peaks) == 4
            % the first three peaks are at the same value
            if std(Peaks([2 3 4]))== 0
                Done = 1;
                Est(i) = mode(Peaks);
                Tplot.MarkerFaceColor = 'b';
            end
        elseif length(Peaks) == 5
            % Check if 3 peaks of the first 4 are at the same value
            if std(Peaks([2 3 5]))== 0 || std(Peaks([2 4 5]))== 0 || std(Peaks([3 4 5]))== 0
                Done = 1;
                Est(i) = mode(Peaks);
                Tplot.MarkerFaceColor = 'b';
            % Check if the first four peaks are all at different values restart 
            % familiarization
            elseif length(find(Peaks(2:5) == Peaks(2)))==1 && length(find(Peaks(2:5) == Peaks(3)))==1 ...
                    && length(find(Peaks(2:5) == Peaks(4)))==1 && length(find(Peaks(2:5) == Peaks(5)))==1
                NextLevel = StartLevel(i)-CurrentLevel;
                Est(i) = mean(Peaks(2:end));
                Peaks = 0;
                Valleys = 0;
                Familiarization = 1;
                Repeat = Repeat + 1;
            end
            % Check if 3 peaks of 5 are at the same value
        elseif length(Peaks) == 6    
            if std(Peaks([2 3 6]))== 0 || std(Peaks([2 4 6]))== 0 || std(Peaks([2 5 6]))== 0 ...
                    || std(Peaks([3 5 6]))== 0 || std(Peaks([4 5 6]))== 0 || std(Peaks([3 4 6]))== 0
                Done = 1;
                Est(i) = mode(Peaks);
                Tplot.MarkerFaceColor = 'b';
            % No success 
            else    
                NextLevel = StartLevel(i)-CurrentLevel;
                Est(i) = mean(Peaks(2:end));
                Peaks = 0;
                Valleys = 0;
                Familiarization = 1;
                Repeat = Repeat + 1; 
            end
        end
        % There were no 3 equal thresholds
        if Repeat == 2
            Done = 1;
            Tplot.MarkerFaceColor = 'r';
        end
        % The test was aborted from control pannel
        if  app.Reversals > 5 || strcmp(app.StartButton.Text,'Start')
            Done = 1;
            Abort = 1;
            Est(i) = NaN; % no estimate. 
        end
        clear Tone_ T
        j = j +1;
        
        app.RespApp.ButtonReset;
        
    end
    ThresTime(i) = now;
    if Abort
        break;
    end
end
varargout{1} = Data;
Estimate.Freqs = F;
Estimate.Thres = Est;
Estimate.Thres_dBSPL = Est + SPL20dBFS(1:length(Est));
if length(ThresTime) < length(F)
    ThresTime = cat(2,ThresTime, nan(1,length(F)-length(ThresTime))); 
end
Estimate.Time4Estimate = ThresTime;
varargout{2} = Estimate;
app.RespApp.AnswerPanel.Title = 'Tid til en pause.';
app.CurrentStimuliLabel.Text = '...';
if isobject(app.ard), app.ard.writeDigitalPin(app.ardconf.LED,0); end
end

